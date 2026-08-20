#!/usr/bin/env node
/**
 * منح صفة المدير — راية على الحساب لا سطر في الشيفرة.
 *
 * لماذا لا يُفحص البريد داخل التطبيق؟ لأن ما في الحزمة يُقرأ ويُعدَّل. أُثبت
 * ذلك في هذا المشروع نفسه: استخراج المفاتيح من APK استغرق ثوانٍ. وشرطٌ مثل
 * `if (email == "...") openAdmin()` يصدّقه التطبيق وحده — ومن يعدّل الحزمة
 * يجعله يصدّقه له.
 *
 * أمّا الـcustom claim فيوقّعه Firebase داخل رمز الهويّة، ولا يستطيع العميل
 * تزويره. والقاعدة تقرأه بـ`auth.token.admin === true` — فتصير الصلاحية على
 * الخادم، حيث لا تُتجاوَز بتعديل واجهة.
 *
 *   node tools/set-admin-claim.js invite mohammed981@gmail.com
 *   node tools/set-admin-claim.js grant  mohammed981@gmail.com
 *   node tools/set-admin-claim.js revoke mohammed981@gmail.com
 *   node tools/set-admin-claim.js list
 *
 * ولا تمرّ كلمة مرور من هنا. وهذا هو سبب وجود `invite`: لوحة الإدارة بلا
 * تسجيل ذاتيّ — عمداً، إذ لو كان فيها زرّ «أنشئ حساباً» لصار كلّ من نزّل
 * الحزمة مرشّحاً للوحة. فبقي المدير الأوّل بلا طريق: لا حساب ينشئه، ولا صفة
 * تُمنح لحساب غير موجود.
 *
 * و`invite` يفتح الطريق دون أن يخلق سرّاً: يُنشئ الحساب بكلمة مرور عشوائيّة
 * **لا تُطبع ولا تُحفظ** — لا أحد يعرفها، بمن فيهم من شغّل الأداة — ثم يمنح
 * الصفة. وصاحب البريد يضبط كلمته من «نسيت كلمة المرور؟» في التطبيق، فتصله
 * رسالة من Firebase إلى بريده وحده.
 *
 * والنتيجة أنّ كلمة المرور لا تمرّ في مستودع، ولا في سجلّ تشغيل عامّ، ولا في
 * محادثة. وهذا مقصود: سجلّات Actions في مستودع عامّ يقرأها الناس.
 */

'use strict';

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('GOOGLE_APPLICATION_CREDENTIALS غير مضبوط — لا مفتاح خادم.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL:
    process.env.RTDB_URL ||
    'https://taxi-taiba-default-rtdb.europe-west1.firebasedatabase.app',
});

const auth = admin.auth();

async function setAdmin(email, value) {
  let user;

  try {
    user = await auth.getUserByEmail(email);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error(`لا حساب بهذا البريد: ${email}`);
      console.error('أنشئه أولاً — من التطبيق أو من كونسول Firebase — ثم أعد.');
      process.exit(1);
    }
    throw error;
  }

  // الرايات تُستبدل لا تُدمج، فتُقرأ الحالية أولاً كي لا تُمحى راية أخرى.
  const claims = { ...(user.customClaims || {}) };

  if (value) {
    claims.admin = true;
  } else {
    delete claims.admin;
  }

  await auth.setCustomUserClaims(user.uid, claims);

  // الراية تدخل رمز الهويّة عند تجديده، والرمز يعيش ساعة. فإبطال الجلسات
  // يجعل الأثر فورياً: منحٌ يعمل الآن، وسحبٌ يقطع الآن — لا بعد ساعة.
  await auth.revokeRefreshTokens(user.uid);

  console.log(`${value ? 'مُنحت' : 'سُحبت'} صفة المدير: ${email}`);
  console.log(`uid: ${user.uid}`);
  console.log('يلزم تسجيل خروج ودخول في التطبيق كي يحمل الرمز الراية.');
}

/// إنشاء الحساب إن لم يكن، ثم منح الصفة.
async function invite(email) {
  let user;

  try {
    user = await auth.getUserByEmail(email);
    console.log(`الحساب موجود مسبقاً: ${email}`);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;

    // كلمة مرور عشوائيّة تُولَّد وتُنسى في السطر نفسه. الغرض منها أن يوجد
    // مزوّد «بريد وكلمة مرور» على الحساب، إذ بدونه لا يعمل رابط إعادة
    // التعيين. ولا تُطبع: ما يُطبع في Actions يُقرأ.
    await auth.createUser({
      email,
      emailVerified: false,
      password: require('crypto').randomBytes(32).toString('base64url'),
    });

    user = await auth.getUserByEmail(email);
    console.log(`أُنشئ الحساب: ${email}`);
  }

  await setAdmin(email, true);

  console.log('');
  console.log('الخطوة التالية — في تطبيق الإدارة:');
  console.log('  اكتب البريد ← «نسيت كلمة المرور؟» ← افتح الرابط في بريدك');
  console.log('  ← اضبط كلمة مرورك ← ادخل بها.');
}

async function list() {
  let found = 0;
  let pageToken;

  do {
    const page = await auth.listUsers(1000, pageToken);

    for (const user of page.users) {
      if (user.customClaims && user.customClaims.admin === true) {
        console.log(`${user.email || '(بلا بريد)'}\t${user.uid}`);
        found += 1;
      }
    }

    pageToken = page.pageToken;
  } while (pageToken);

  console.log(`\n${found} مديراً.`);
}

async function main() {
  const command = process.argv[2];
  const email = process.argv[3];

  if (command === 'list') {
    await list();
  } else if (command === 'invite') {
    if (!email) {
      console.error('البريد مطلوب.');
      process.exit(1);
    }
    await invite(email);
  } else if (command === 'grant' || command === 'revoke') {
    if (!email) {
      console.error('البريد مطلوب.');
      process.exit(1);
    }
    await setAdmin(email, command === 'grant');
  } else {
    console.error(
      'المتاح: invite <email> | grant <email> | revoke <email> | list'
    );
    process.exit(1);
  }

  await admin.app().delete();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
