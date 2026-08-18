import 'dart:math' as math;

import 'package:flutter_projects/methods/geo_query.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبار حساب نطاقات الجيوهاش.
///
/// السبب في وجوده أن خطأً في هذا الحساب لا يُسقط التطبيق. سائق قريب لا يدخل
/// أيّ مدى فلا يصل خبره، وتقرأ الشاشة «لا يوجد سائقون» وهي صادقة في ما ترى.
/// عطلٌ صامت من هذا النوع لا يُكتشف بالتجربة اليدوية إلا بالمصادفة، فيُكتشف
/// هنا.
///
/// والادّعاء المركزي واحد: **لا يفوت الاستعلامَ أحدٌ داخل نصف القطر**. أمّا
/// جلب الزائد فمقبول — يقصّه هافرساين على الجهاز.

void main() {
  const double khartoumLat = 15.5007;
  const double khartoumLng = 32.5599;
  const double radius = 22000;

  bool coveredBy(List<List<String>> bounds, String hash) {
    for (final List<String> range in bounds) {
      if (hash.compareTo(range[0]) >= 0 && hash.compareTo(range[1]) <= 0) {
        return true;
      }
    }
    return false;
  }

  group('encodeGeohash', () {
    test('يطابق قيماً مرجعية معروفة', () {
      // قيم منشورة من خارج هذا المستودع — لا من تشغيل هذه الشيفرة، وإلّا لكان
      // الاختبار يسأل الشيفرة أن تصدّق نفسها.
      expect(encodeGeohash(57.64911, 10.40744, precision: 11),
          equals('u4pruydqqvj'));
      expect(encodeGeohash(-25.382708, -49.265506, precision: 8),
          equals('6gkzwgjz'));
      expect(encodeGeohash(42.6, -5.6, precision: 5), equals('ezs42'));
      expect(encodeGeohash(37.8324, 112.5584, precision: 9),
          equals('ww8p1r4t8'));
    });

    test('نقطتان متجاورتان تشتركان في بادئة طويلة', () {
      final String a = encodeGeohash(khartoumLat, khartoumLng);
      final String b = encodeGeohash(khartoumLat + 0.0001, khartoumLng);

      int shared = 0;
      while (shared < a.length && a[shared] == b[shared]) {
        shared += 1;
      }

      // هذه هي الخاصيّة التي يقوم عليها كل شيء: القرب في المكان قربٌ في
      // الترتيب النصّي. لو انكسرت، لصار استعلام المدى بلا معنى.
      expect(shared, greaterThanOrEqualTo(7));
    });
  });

  group('geohashQueryBounds', () {
    test('لا يفوته أحد داخل نصف القطر', () {
      final List<List<String>> bounds =
          geohashQueryBounds(khartoumLat, khartoumLng, radius);

      // بذرة ثابتة: فشلٌ يُعاد إنتاجه هو فشل يُصلَح.
      final math.Random random = math.Random(7);

      int inside = 0;
      int missed = 0;
      int fetched = 0;
      const int samples = 40000;

      for (int i = 0; i < samples; i += 1) {
        // مربّع ≈ ٤٠٠ كم حول المركز.
        final double lat = khartoumLat + (random.nextDouble() * 3.6 - 1.8);
        final double lng = khartoumLng + (random.nextDouble() * 3.6 - 1.8);

        final bool covered =
            coveredBy(bounds, encodeGeohash(lat, lng));
        if (covered) fetched += 1;

        if (distanceInMeters(khartoumLat, khartoumLng, lat, lng) <= radius) {
          inside += 1;
          if (!covered) missed += 1;
        }
      }

      expect(inside, greaterThan(100), reason: 'العيّنة أضعف من أن تُثبت شيئاً');
      expect(missed, equals(0), reason: 'سائق داخل النطاق لم يدخل أيّ مدى');

      // الحدّ فضفاض عمداً: المقصود إثبات أن الاستعلام يقصّ فعلاً، لا تثبيت
      // رقم يتغيّر مع تغيّر نصف القطر.
      expect(fetched, lessThan(samples ~/ 4));
    });

    test('يستبعد مدينة بعيدة', () {
      final List<List<String>> bounds =
          geohashQueryBounds(khartoumLat, khartoumLng, radius);

      // القاهرة — ١٥٠٠ كم شمالاً.
      expect(coveredBy(bounds, encodeGeohash(30.0444, 31.2357)), isFalse);
    });

    test('يشمل الخرطوم بحري', () {
      final List<List<String>> bounds =
          geohashQueryBounds(khartoumLat, khartoumLng, radius);

      expect(coveredBy(bounds, encodeGeohash(15.6333, 32.5333)), isTrue);
    });

    test('ينضغط إلى عدد صغير من الاستعلامات', () {
      final List<List<String>> bounds =
          geohashQueryBounds(khartoumLat, khartoumLng, radius);

      // تسع نقاط تُحسب، لكن أكثرها يقع في الخليّة نفسها. لو عادت تسعة، فحذف
      // المكرّر لا يعمل — وذلك تسعة اشتراكات مفتوحة بدل اثنين.
      expect(bounds.length, lessThanOrEqualTo(4));
      expect(bounds, isNotEmpty);
      for (final List<String> range in bounds) {
        expect(range[0].compareTo(range[1]) <= 0, isTrue);
      }
    });

    test('يعمل عند خطوط عرض عالية', () {
      // درجة الطول تنكمش قرب القطبين. حسابٌ يفترضها ثابتة ينجح في الخرطوم
      // ويفشل في أوسلو — وهذا ما يمسكه هذا الاختبار.
      const double osloLat = 59.9139;
      const double osloLng = 10.7522;

      final List<List<String>> bounds =
          geohashQueryBounds(osloLat, osloLng, radius);

      expect(bounds, isNotEmpty);
      expect(coveredBy(bounds, encodeGeohash(osloLat + 0.1, osloLng + 0.2)),
          isTrue);
    });
  });

  group('distanceInMeters', () {
    test('تطابق مسافات معروفة في حدود ١٪', () {
      // الخرطوم ← القاهرة ≈ ١٦٢٣ كم.
      final double d = distanceInMeters(15.5007, 32.5599, 30.0444, 31.2357);
      expect(d / 1000, closeTo(1623, 15));

      expect(distanceInMeters(0, 0, 0, 0), equals(0));
    });
  });
}
