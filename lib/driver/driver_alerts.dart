import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// تنبيه العرض — الحلقة الناقصة بين «التطبيق حيّ» و«السائق يعرف».
///
/// خدمة المقدّمة تُبقي العمليّة حيّة في الخلفيّة، فيصل العرض من القاعدة
/// ويُحدَّث الحقل — ثم ينتهي عند `setState` على شاشة لا يراها أحد. السائق
/// هاتفه في جيبه، أو في تطبيق آخر، أو الشاشة مقفلة. فالعرض يصل ويمضي.
///
/// منقول من zadgo2 (`lib/providers/local_alerts.dart`) حيث كُتب لنفس السبب
/// حرفياً: «صوته لا يخرج من الخلفية — هذه الحلقة الناقصة».
///
/// وقناةٌ مستقلّة عن قناة «أنت متّصل» عمداً: تلك صامتة دائمة، وهذه بأعلى
/// أهميّة وبصوت واهتزاز. وفصلُهما يجعل السائق قادراً على إسكات إحداهما من
/// إعدادات النظام دون الأخرى — وهو ما سيفعله بالتأكيد لو كانتا واحدة.
class DriverAlerts {
  const DriverAlerts._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;

  /// معرّف ثابت: العرض الجديد يحلّ محلّ السابق بدل أن تتكدّس إشعارات
  /// لعروضٍ انقضت.
  static const int _offerId = 7001;

  static const AndroidNotificationDetails _android =
      AndroidNotificationDetails(
    'taibah_offers',
    'طلبات الرحلات',
    channelDescription: 'تنبيه بصوت عند وصول طلب رحلة جديد',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    // فئة «مكالمة»: تجعل النظام يعامله كشيء يُجاب عليه الآن لا كخبر.
    // ولم يُضَف `fullScreenIntent` — يجرّ صلاحيّة `USE_FULL_SCREEN_INTENT`
    // وإقراراً في Play Console، وأندرويد ١٤ يقصرها على تطبيقات الاتصال
    // والمنبّه أصلاً.
    category: AndroidNotificationCategory.call,
  );

  /// وiOS ذراعٌ قائم بذاته — الحزمة لا تشتقّه من إعدادات أندرويد.
  static const DarwinNotificationDetails _darwin = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  static Future<void> _ensureReady() async {
    if (_ready) return;

    // أيقونة المشغّل نفسها — لا مورد إشعار مخصّص يُدار في ثلاث نكهات.
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    _ready = true;
  }

  /// تنبيه بطلب جديد.
  ///
  /// والفشل صامت عمداً: اللوحة على الشاشة موجودة على كلّ حال، والإشعار طبقةٌ
  /// تزيد الوصول لا شرطُ عملٍ يُعطَّل التدفّق لأجله.
  static Future<void> offer({required String title, required String body}) async {
    try {
      await _ensureReady();
      await _plugin.show(
        _offerId,
        title,
        body,
        const NotificationDetails(android: _android, iOS: _darwin),
      );
    } catch (error) {
      debugPrint('DriverAlerts: $error');
    }
  }

  /// يمسح إشعار العرض.
  ///
  /// ويُنادى في أربعة مواضع لا اثنين — أهمّها انصرافُ الطلب إلى سائق آخر:
  /// مؤقّت الراكب يكتب `idle` بعد عشرين ثانية ويُحيل الرحلة لغيره، وهذا
  /// المسار لا يمرّ بـ«رفض» أبداً. وبلا مسحٍ هناك يفتح السائق إشعاراً لرحلةٍ
  /// صارت لغيره.
  static Future<void> clearOffer() async {
    try {
      await _plugin.cancel(_offerId);
    } catch (_) {
      // لا شيء يُفعل: مسحُ إشعارٍ غير موجود ليس خطأً يُبلَّغ عنه.
    }
  }
}
