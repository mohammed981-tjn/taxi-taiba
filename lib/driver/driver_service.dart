import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_projects/methods/geo_query.dart';
import 'package:geolocator/geolocator.dart';

/// كل ما يكتبه تطبيق السائق في القاعدة — في ملف واحد.
///
/// السبب أنّ الكتابات هنا مقيَّدة بقواعد دقيقة: حقول يملكها السائق وأخرى
/// ممنوعة عليه، وشروط تسبق الاتصال. نثرُها في الشاشات يعني اكتشاف كل قيد
/// مرّتين — مرّةً في كل شاشة تلمسه.
class DriverService {
  const DriverService._();

  static String get uid => FirebaseAuth.instance.currentUser!.uid;

  static DatabaseReference get _root => FirebaseDatabase.instance.ref();

  static DatabaseReference get me => _root.child('drivers').child(uid);

  static DatabaseReference get _online =>
      _root.child('onlineDrivers').child(uid);

  /* ── التسجيل ───────────────────────────────────────────────────────── */

  /// ملفّ سائق جديد.
  ///
  /// القيم الثلاث الأخيرة ليست اختيارية ولا تجميلية: قاعدة `drivers/$uid`
  /// تشترط عند الإنشاء أن تكون `earnings` صفراً و`blockStatus` = no
  /// و`approvalStatus` = pending بالضبط. أي أنّ **السائق لا يستطيع اعتماد
  /// نفسه** — يكتب طلبه معلَّقاً، ولا يغيّره أحد إلا المدير.
  static Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String carModel,
    required String carNumber,
    required String carColor,
    required String carType,
  }) {
    return me.set(<String, Object?>{
      'id': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'car_details': <String, Object?>{
        'model': carModel,
        'number': carNumber,
        'color': carColor,
        'type': carType,
      },
      'earnings': 0,
      'blockStatus': 'no',
      'approvalStatus': 'pending',
      'newTripStatus': 'idle',
    });
  }

  /* ── الاتصال ───────────────────────────────────────────────────────── */

  /// الظهور للركّاب.
  ///
  /// الحقلان `g` و`l` هما ما يقرأه تطبيق الراكب حرفياً، و`g` هو المفهرس الذي
  /// يقوم عليه استعلام النطاق. ولا يُقبل هذا الكتابة أصلاً ما لم يكن السائق
  /// معتمَداً — القاعدة ترفضها، فلا حاجة إلى فحص هنا يمكن تخطّيه.
  static Future<void> goOnline(Position position) {
    return _online.set(<String, Object?>{
      'g': encodeGeohash(position.latitude, position.longitude),
      'l': <double>[position.latitude, position.longitude],
    });
  }

  static Future<void> publishLocation(Position position) => goOnline(position);

  /// الاختفاء.
  ///
  /// وحذفُ `newTripStatus` معه مقصود: طلبٌ معلَّق لسائق خرج يبقى معروضاً على
  /// شاشته حين يعود، بعد أن يكون الراكب قد صرفه إلى غيره.
  static Future<void> goOffline() async {
    await _online.remove();
    await me.child('newTripStatus').set('idle');
  }

  /// يُخرج السائق تلقائياً إن مات التطبيق أو انقطعت الشبكة.
  ///
  /// بدونه يبقى سائقٌ أُغلق هاتفه ظاهراً للركّاب إلى الأبد: يُرسَل إليه طلب،
  /// فلا يجيب، فينتظر الراكب عشرين ثانية ثم ينتقل إلى غيره. `onDisconnect`
  /// يُسجَّل على الخادم لا على الجهاز، فينفَّذ حتى لو لم يعمل الجهاز شيئاً.
  static Future<void> clearOnDisconnect() => _online.onDisconnect().remove();

  /* ── الرحلة ────────────────────────────────────────────────────────── */

  static DatabaseReference trip(String tripId) =>
      _root.child('tripRequests').child(tripId);

  /// قبول الرحلة.
  ///
  /// كتابةٌ واحدة تحمل الهوية والحالة معاً، ولا تُقبل إلا و`driverID` ما زال
  /// `waiting`. فسائقان يضغطان «قبول» في اللحظة نفسها: الأول يمرّ، والثاني
  /// ترفضه القاعدة لا الشيفرة.
  static Future<void> acceptTrip({
    required String tripId,
    required String name,
    required String phone,
    required String carDetails,
  }) async {
    await trip(tripId).update(<String, Object?>{
      'driverID': uid,
      'driverName': name,
      'driverPhone': phone,
      'carDetails': carDetails,
      'status': 'accepted',
    });

    await me.child('newTripStatus').set('idle');
  }

  /// الرفض — لا يُكتب في الرحلة شيء.
  ///
  /// الراكب ينتقل إلى السائق التالي بانتهاء مهلته. وكتابة الرفض في الرحلة
  /// تعني أن يرى الراكب «رُفض» بدل «نبحث عن سائق»، وهو أسوأ.
  static Future<void> declineTrip() => me.child('newTripStatus').set('idle');

  static Future<void> setTripStatus(String tripId, String status) =>
      trip(tripId).update(<String, Object?>{'status': status});

  /// إنهاء الرحلة بالأجرة.
  ///
  /// `fareAmount` لا تكتبه إلا يدُ السائق المُسنَد — تحقّقٌ في القاعدة، وهو ما
  /// يُبطل اللغم القديم في تطبيق الراكب حيث كان `currentUser.uid` هو الراكب.
  static Future<void> endTrip(String tripId, double fare) {
    return trip(tripId).update(<String, Object?>{
      'fareAmount': fare.toStringAsFixed(1),
      'status': 'ended',
      'endedAt': DateTime.now().toIso8601String(),
    });
  }

  /// تقييم الراكب — الطرف المفقود من التقييم المتبادل.
  static Future<void> ratePassenger({
    required String tripId,
    required String passengerId,
    required int stars,
  }) async {
    await trip(tripId).update(<String, Object?>{'driverRating': stars});

    await _root
        .child('users')
        .child(passengerId)
        .child('ratings')
        .runTransaction((Object? current) {
      final Map<String, dynamic> data =
          current is Map ? Map<String, dynamic>.from(current) : <String, dynamic>{};

      final int count = (data['count'] as num?)?.toInt() ?? 0;
      final double sum = (data['sum'] as num?)?.toDouble() ?? 0;

      final int newCount = count + 1;
      final double newSum = sum + stars;

      return Transaction.success(<String, Object?>{
        'count': newCount,
        'sum': newSum,
        'average': double.parse((newSum / newCount).toStringAsFixed(2)),
      });
    });
  }

  /* ── الأرباح ───────────────────────────────────────────────────────── */

  /// رحلات هذا السائق، بالاستعلام لا بتنزيل الجدول.
  ///
  /// والقاعدة تشترط هذا الشكل بالذات: القراءة مسموحة إن كان الاستعلام
  /// `orderByChild('driverID').equalTo(uid)` — أي أنّ السائق لا يقدر على
  /// قراءة رحلات غيره حتى لو حاول، ولا على تنزيل الجدول كلّه ليصفّيه بنفسه.
  ///
  /// **والأرباح تُشتقّ ولا تُخزَّن.** عدّادٌ في `drivers/$uid/earnings` يكتبه
  /// من يملك الحساب هو دعوةٌ لأن يكتب ما يشاء؛ ومجموعٌ يُحسب من الرحلات
  /// المنتهية لا يكذب إلا إذا كذبت الرحلات. ولذلك القاعدة تجمّد ذلك الحقل،
  /// وهذه الشاشة لا تقرؤه.
  static Query get myTrips => _root
      .child('tripRequests')
      .orderByChild('driverID')
      .equalTo(uid);
}
