#!/usr/bin/env node
/**
 * حسابات تجربة — تُنشأ بمفتاح الخادم، لا من شاشة التسجيل.
 *
 * لماذا سكربت أصلاً؟ لأن الشاشة تنشئ راكباً واحداً في كل مرة، والتجربة
 * الحقيقية تحتاج طرفين على الأقل: راكب يطلب، وسائق متصل قريب منه يُعرض على
 * الخريطة ويُرسَل إليه الطلب. سائقٌ لا وجود له في `onlineDrivers` يعني شاشةً
 * تدور بلا نتيجة، وهذا ليس خطأً في التطبيق بل قاعدةً فارغة.
 *
 * وحزمة firebase-admin تتجاوز القواعد عمداً وبتصميمها. فهي تكتب `earnings`
 * و`ratings` — وهما محميّان من العميل — دون أن يُضعف ذلك القواعد نفسها. وهذا
 * هو الفرق بين مفتاح خادم ومفتاح تطبيق، وسبب أن الأول لا يوضع في APK أبداً.
 *
 *   node tools/seed-test-accounts.js seed
 *   node tools/seed-test-accounts.js list
 *   node tools/seed-test-accounts.js cleanup
 *
 * البيئة:
 *   GOOGLE_APPLICATION_CREDENTIALS  مسار مفتاح حساب الخدمة
 *   RTDB_URL                        عنوان القاعدة كاملاً
 *   TEST_PASSWORD                   كلمة مرور موحّدة لحسابات التجربة
 *   CENTER_LAT / CENTER_LNG         مركز نثر السائقين
 */

'use strict';

const admin = require('firebase-admin');

/* ── ما يُنشأ ─────────────────────────────────────────────────────────────── */

// نطاق .test محجوز بمعيار RFC 2606 ولا يُسجَّل ولا يُسلَّم إليه بريد. فهو أوضح
// من example.com في أنّ هذه الحسابات ليست لأحد، وأأمن من نطاق حقيقي قد يملكه
// شخص فيصله بريد لم يطلبه.
const DOMAIN = 'taiba.test';

const PASSENGERS = [
  { key: 'rider1', name: 'راكب تجريبي ١', phone: '0900000001' },
  { key: 'rider2', name: 'راكب تجريبي ٢', phone: '0900000002' },
];

const DRIVERS = [
  {
    key: 'driver1',
    name: 'سائق تجريبي ١',
    phone: '0910000001',
    car: { model: 'Toyota Corolla', number: 'KRT 1234', color: 'أبيض', type: 'اقتصادي' },
  },
  {
    key: 'driver2',
    name: 'سائق تجريبي ٢',
    phone: '0910000002',
    car: { model: 'Hyundai Accent', number: 'KRT 5678', color: 'فضي', type: 'اقتصادي' },
  },
  {
    key: 'driver3',
    name: 'سائق تجريبي ٣',
    phone: '0910000003',
    car: { model: 'Kia Sportage', number: 'KRT 9012', color: 'أسود', type: 'عائلي' },
  },
];

/* ── جيوهاش ───────────────────────────────────────────────────────────────── */

// ترميز geohash قياسي بدقّة ١٠ — وهي دقّة GeoFire الافتراضية، فما يكتبه هذا
// السكربت يطابق ما يكتبه تطبيق السائق لاحقاً. والحقل `g` هو المفهرس في
// database.rules.json، وعليه يقوم استعلام النطاق الذي سيحلّ محلّ تنزيل كل
// السائقين.
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

function geohash(lat, lon, precision = 10) {
  let latMin = -90;
  let latMax = 90;
  let lonMin = -180;
  let lonMax = 180;

  let hash = '';
  let bits = 0;
  let bit = 0;
  let even = true;

  while (hash.length < precision) {
    if (even) {
      const mid = (lonMin + lonMax) / 2;
      if (lon > mid) {
        bit = (bit << 1) + 1;
        lonMin = mid;
      } else {
        bit <<= 1;
        lonMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat > mid) {
        bit = (bit << 1) + 1;
        latMin = mid;
      } else {
        bit <<= 1;
        latMax = mid;
      }
    }

    even = !even;
    bits += 1;

    if (bits === 5) {
      hash += BASE32[bit];
      bits = 0;
      bit = 0;
    }
  }

  return hash;
}

/* ── إعداد ────────────────────────────────────────────────────────────────── */

const RTDB_URL =
  process.env.RTDB_URL ||
  'https://taxi-taiba-default-rtdb.europe-west1.firebasedatabase.app';

const PASSWORD = process.env.TEST_PASSWORD || 'Taiba@2026test';

// الخرطوم افتراضاً. غيّرها إلى حيث تجرّب فعلاً — سائق على بُعد ألف كيلومتر
// موجودٌ في القاعدة ولا يظهر في التطبيق، لأن المرشّح يقصّ عند ٢٢ كم.
const CENTER_LAT = Number(process.env.CENTER_LAT || 15.5007);
const CENTER_LNG = Number(process.env.CENTER_LNG || 32.5599);

// نثرٌ ثابت لا عشوائي: التشغيل مرتين يعطي المواقع نفسها، فما تراه على الخريطة
// لا يتحرّك بين تشغيل وآخر إلا حين تريد أنت. ≈ ١٫١ كم لكل ٠٫٠١ درجة.
const OFFSETS = [
  [0.012, 0.008],
  [-0.009, 0.014],
  [0.006, -0.011],
  [-0.014, -0.006],
  [0.017, 0.002],
];

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('GOOGLE_APPLICATION_CREDENTIALS غير مضبوط — لا مفتاح خادم.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: RTDB_URL,
});

const auth = admin.auth();
const db = admin.database();

const emailOf = (key) => `${key}@${DOMAIN}`;

/* ── إنشاء ────────────────────────────────────────────────────────────────── */

/**
 * يُعيد الحساب موجوداً كان أو جديداً.
 *
 * التشغيل مرتين شائع — تنسى أنك شغّلته، أو تُعيد بعد فشل في المنتصف. فالحساب
 * الموجود يُحدَّث ولا يُرفض، وبهذا يبقى السكربت آمن التكرار.
 */
async function ensureUser(key, displayName) {
  const email = emailOf(key);

  try {
    const existing = await auth.getUserByEmail(email);
    await auth.updateUser(existing.uid, { password: PASSWORD, displayName });
    return { uid: existing.uid, email, created: false };
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;

    const created = await auth.createUser({
      email,
      password: PASSWORD,
      displayName,
      // لا إرسال ولا تحقّق: البريد هنا معرّفٌ لا قناة اتصال. وهذا هو صلب
      // الأمر — Firebase لا يطلب بريداً حقيقياً في طريقة البريد/كلمة المرور،
      // ولا يتحقّق منه إلا إن طلبتَ أنت ذلك صراحةً في الشيفرة.
      emailVerified: false,
    });

    return { uid: created.uid, email, created: true };
  }
}

async function seed() {
  const made = [];

  for (const person of PASSENGERS) {
    const account = await ensureUser(person.key, person.name);

    await db.ref(`users/${account.uid}`).update({
      id: account.uid,
      name: person.name,
      email: account.email,
      phone: person.phone,
      blockStatus: 'no',
    });

    made.push({ role: 'راكب', ...account, name: person.name });
  }

  for (let index = 0; index < DRIVERS.length; index += 1) {
    const person = DRIVERS[index];
    const account = await ensureUser(person.key, person.name);

    const [dLat, dLng] = OFFSETS[index % OFFSETS.length];
    const lat = CENTER_LAT + dLat;
    const lng = CENTER_LNG + dLng;

    await db.ref(`drivers/${account.uid}`).update({
      id: account.uid,
      name: person.name,
      email: account.email,
      phone: person.phone,
      blockStatus: 'no',
      car_details: person.car,
      // معتمَدون كي تعمل التجربة فوراً. والقاعدة تربط هذا الحقل بالخدمة: من
      // ليس `approved` لا يستطيع الكتابة في `onlineDrivers` أصلاً، فلا يراه
      // راكب. اضبطه من لوحة الإدارة لتجرّب الاعتماد والإيقاف.
      approvalStatus: 'approved',
      // القواعد تمنع العميل من كتابة هذين. مفتاح الخادم يكتبهما، وهذا هو
      // ترتيبهما الصحيح: الأرقام المالية يضعها طرفٌ لا يملك المستخدم تعديله.
      earnings: 0,
      ratings: { count: 0, sum: 0, average: 0 },
      newTripStatus: 'idle',
    });

    // الشكل الذي يقرأه التطبيق حرفياً: home_page يأخذ value['l'][0] و[1].
    // وحقل g هو ما يجعل استعلام النطاق ممكناً حين نكتبه.
    await db.ref(`onlineDrivers/${account.uid}`).set({
      g: geohash(lat, lng),
      l: [lat, lng],
    });

    made.push({ role: 'سائق', ...account, name: person.name, at: `${lat.toFixed(4)}, ${lng.toFixed(4)}` });
  }

  return made;
}

/* ── حذف ──────────────────────────────────────────────────────────────────── */

async function cleanup() {
  const removed = [];

  for (const person of [...PASSENGERS, ...DRIVERS]) {
    const email = emailOf(person.key);

    try {
      const account = await auth.getUserByEmail(email);

      await Promise.all([
        db.ref(`users/${account.uid}`).remove(),
        db.ref(`drivers/${account.uid}`).remove(),
        db.ref(`onlineDrivers/${account.uid}`).remove(),
      ]);

      await auth.deleteUser(account.uid);
      removed.push(email);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
    }
  }

  return removed;
}

/* ── عرض ──────────────────────────────────────────────────────────────────── */

async function list() {
  const rows = [];

  for (const person of [...PASSENGERS, ...DRIVERS]) {
    const email = emailOf(person.key);
    try {
      const account = await auth.getUserByEmail(email);
      rows.push({ email, uid: account.uid, name: account.displayName || '' });
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      rows.push({ email, uid: '—', name: 'غير موجود' });
    }
  }

  return rows;
}

/* ── التشغيل ──────────────────────────────────────────────────────────────── */

async function main() {
  const command = process.argv[2] || 'seed';

  if (command === 'seed') {
    const made = await seed();
    console.log(`\nالقاعدة: ${RTDB_URL}`);
    console.log(`المركز:  ${CENTER_LAT}, ${CENTER_LNG}`);
    console.log(`كلمة المرور الموحّدة: ${PASSWORD}\n`);
    for (const row of made) {
      const where = row.at ? `  @ ${row.at}` : '';
      console.log(`${row.created ? 'أُنشئ ' : 'مُحدَّث'}  ${row.role}  ${row.email}${where}`);
    }
    console.log(`\n${made.length} حساباً جاهزاً.`);
  } else if (command === 'cleanup') {
    const removed = await cleanup();
    console.log(removed.length ? removed.join('\n') : 'لا شيء ليُحذف.');
    console.log(`\nحُذف ${removed.length}.`);
  } else if (command === 'list') {
    for (const row of await list()) {
      console.log(`${row.email}\t${row.uid}\t${row.name}`);
    }
  } else {
    console.error(`أمر غير معروف: ${command} — المتاح: seed | list | cleanup`);
    process.exit(1);
  }

  await admin.app().delete();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
