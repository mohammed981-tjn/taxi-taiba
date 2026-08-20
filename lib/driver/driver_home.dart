import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/driver/driver_earnings_page.dart';
import 'package:flutter_projects/driver/driver_alerts.dart';
import 'package:flutter_projects/driver/driver_service.dart';
import 'package:flutter_projects/driver/driver_trip_panel.dart';
import 'package:flutter_projects/widgets/taibah_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// شاشة السائق.
///
/// حالتان لا أكثر: متصل وغير متصل. وبينهما رحلة إن وُجدت.
class DriverHome extends StatefulWidget {
  const DriverHome({super.key, required this.profile});

  final Map<String, Object?> profile;

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _online = false;
  bool _busy = false;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DatabaseEvent>? _tripOfferSubscription;

  /// معرّف الرحلة المعروضة أو الجارية.
  String? _tripId;

  /// آخر موقع — يُعرض ويُبثّ.
  Position? _position;

  @override
  void initState() {
    super.initState();
    _recoverThenListen();
  }

  /// الاسترجاع أوّلاً، ثم الإصغاء.
  ///
  /// الترتيب هنا ليس تفصيلاً. لو رُكّب المستمع أوّلاً — كما كان — لوصل عرضٌ
  /// جديد كُتب أثناء غياب السائق فداس على الرحلة المسترجَعة، ووجد السائق نفسه
  /// في عرضٍ جديد ورحلتُه الجارية معلّقة عند راكب ينتظر.
  Future<void> _recoverThenListen() async {
    try {
      final String? active = await DriverService.activeTripId();
      if (active != null && mounted) {
        setState(() {
          _tripId = active;
          _tripStarted = true;
        });
        // الرحلة تحتاج موقعاً يُبثّ: السائق عاد من إغلاق التطبيق وسط رحلة،
        // والراكب ما زال ينتظر أن تتحرّك السيّارة على خريطته.
        await _resumeLocationForTrip();
      }
    } catch (_) {
      // الاسترجاع رفاهية: فشله لا يمنع السائق من العمل من جديد.
    } finally {
      // الإصغاء يبدأ هنا وحده — بعد أن يُعرف إن كانت هناك رحلة جارية.
      _listenForOffers();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tripOfferSubscription?.cancel();
    super.dispose();
  }

  /* ── الطلبات الواردة ───────────────────────────────────────────────── */

  /// الراكب يكتب معرّف الرحلة في `drivers/$uid/newTripStatus`.
  ///
  /// وهذه هي القناة الوحيدة التي يملكها الراكب إلى السائق، والقاعدة تسمح بها
  /// صراحةً: `newTripStatus` وحدها مفتوحة لأي مستخدم مسجَّل، وما عداها في
  /// ملفّ السائق مغلق عليه.
  void _listenForOffers() {
    _tripOfferSubscription =
        DriverService.me.child('newTripStatus').onValue.listen(
      (DatabaseEvent event) {
        final String value = '${event.snapshot.value ?? 'idle'}';

        if (value == 'idle' || value.isEmpty) {
          // لا تمسح رحلةً جارية: `idle` تُكتب أيضاً لحظة القبول.
          if (_tripId != null && !_tripStarted) {
            // وهذا هو الموضع غير البديهيّ لمسح الإشعار.
            //
            // مؤقّت الراكب يكتب `idle` هنا بعد عشرين ثانية ويُحيل الرحلة إلى
            // سائق آخر — ولا يمرّ هذا المسار بـ«رفض» إطلاقاً. فبلا مسحٍ هنا
            // يبقى على شاشة السائق إشعارٌ يعلن رحلةً صارت لغيره، يفتحه بعد
            // دقيقة فيجد لوحةً فارغة.
            DriverAlerts.clearOffer();
            setState(() => _tripId = null);
          }
          return;
        }

        if (!mounted) return;

        // سائقٌ في رحلة لا يُعرَض عليه شيء.
        //
        // كان أيّ نصّ غير `idle` يُقبل بلا شرط ويصير معرّفَ الرحلة المعروضة.
        // فعرضٌ جديد يصل أثناء رحلة جارية كان يخطفها: تُستبدل اللوحة، ويضيع
        // الراكب الذي في السيّارة. ونفس الشيء يحدث مع الكلمات التي كان تطبيق
        // الراكب يكتبها هنا (`timeout` و`cancelled`) — كانت تُعامَل معرّفاتِ
        // رحلات ثم تُفتح لها لوحة لرحلة لا وجود لها.
        if (_tripStarted) {
          DriverService.declineTrip();
          return;
        }

        // مفاتيح Firebase تبدأ بـ`-` وطولها عشرون محرفاً. أيّ نصّ آخر ليس
        // رحلة، ولا يُفتح له شيء.
        if (!value.startsWith('-') || value.length < 15) return;

        // القاعدة تعيد تسليم القيمة الحاليّة عند كلّ إعادة اتّصال — وشبكة
        // الجوّال تنقطع وتعود كثيراً. فبلا هذا الحارس يرنّ الهاتف مرّةً بعد
        // مرّة لعرضٍ واحد لم يتغيّر.
        final bool isNew = value != _tripId;

        setState(() {
          _tripId = value;
          _tripStarted = false;
        });

        // التنبيه بعد الحارسَين لا قبلهما: قبلَهما يرنّ للنصوص التي ليست
        // رحلات، ولعروضٍ تصل وسط رحلة جارية.
        if (isNew) {
          DriverAlerts.offer(
            title: 'طلب رحلة جديد',
            body: 'اضغط للاطّلاع وقبول الطلب قبل انتهاء المهلة.',
          );
        }
      },
    );
  }

  /// تُرفع حين يُقبل الطلب، فلا يمحو `idle` الرحلةَ الجارية.
  bool _tripStarted = false;

  /* ── الاتصال ───────────────────────────────────────────────────────── */

  Future<void> _toggleOnline(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      if (value) {
        await _goOnline();
        await _askNotificationPermission();
        await _showBatteryAdviceOnce();
      } else {
        await _goOffline();
      }
    } catch (error) {
      _say('تعذّر: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// إعدادات التدفّق — ومعها خدمة المقدّمة.
  ///
  /// هذا هو الفرق بين سائق يعمل وسائق يظنّ أنه يعمل. `LocationSettings`
  /// المجرّدة تتوقّف لحظة خروج التطبيق من الواجهة: يُقفل السائق الشاشة ويضع
  /// الهاتف في جيبه — وهو ما يفعله كلّ سائق — فيتوقّف البثّ، ويمحوه
  /// `onDisconnect` من `onlineDrivers` خلال دقيقة، بينما المفتاح على شاشته
  /// ما زال يقول «متصل». فينتظر ساعةً ولا يصله طلب، ولا شيء يخبره لماذا.
  ///
  /// و`ForegroundNotificationConfig` تجعل أندرويد يبقي العمليّة حيّة مقابل
  /// إشعار دائم يراه السائق — وهو شرط النظام لا خيارنا، ومن حقّ المستخدم أن
  /// يعرف أنّ موقعه يُقرأ.
  static LocationSettings get _trackingSettings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        // عشرون متراً لا كل متر: تحديثٌ لكل خطوة يكتب في القاعدة عشرات المرات
        // في الدقيقة ويُحاسَب عليه.
        distanceFilter: 20,
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Taibah سائق — أنت متّصل',
          notificationText: 'موقعك يُبثّ لاستقبال الطلبات.',
          notificationChannelName: 'حالة الاتصال',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        // `best` لا `bestForNavigation`: الثانية توثّقها Apple للملاحة
        // وللجهاز الموصول بالطاقة، وتستنزف بطاريّة سائقٍ ينتظر في موقف.
        // وعلى أندرويد لا فرق — الثلاثة تُخطَّط إلى الأولويّة القصوى نفسها،
        // ولذلك بقي فرعها كما هو.
        accuracy: LocationAccuracy.best,
        distanceFilter: 20,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 20,
    );
  }

  Future<void> _goOnline() async {
    // خدمة الموقع نفسها قبل الصلاحية.
    //
    // صلاحيةٌ ممنوحة وGPS مطفأ حالةٌ شائعة، وكانت تُخرج استثناءً خاماً بالإنجليزية
    // في شريط سفليّ — رسالةٌ لا تقول للسائق أن يفتح إعداداً واحداً.
    if (!await Geolocator.isLocationServiceEnabled()) {
      _askToOpen(
        title: 'خدمة الموقع مطفأة',
        body: 'شغّل «الموقع» في إعدادات الهاتف كي تستقبل الطلبات.',
        open: Geolocator.openLocationSettings,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // `deniedForever` طريق مسدود من داخل التطبيق: النظام لا يعرض الطلب مرّة
      // أخرى مهما استُدعي. الطريق الوحيد صفحة إعدادات التطبيق — فتُفتح له.
      _askToOpen(
        title: 'صلاحية الموقع مرفوضة',
        body: 'لن يراك أيّ راكب بلا موقع. افتح إعدادات التطبيق واسمح بالموقع.',
        open: Geolocator.openAppSettings,
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      _say('بلا صلاحية الموقع لا يمكن الاتصال — موقعك هو ما يراه الراكب.');
      return;
    }

    // لقطةٌ محدودةٌ بمهلة، ولها بديل.
    //
    // كانت `bestForNavigation` **بلا مهلة**، وتسبق كلّ شيء في مسار الاتصال.
    // فسائقٌ داخل مبنى أو في قبو ينتظر تثبيتاً قد لا يأتي: يحدّق في دوّار
    // والمفتاح لا يخضرّ، ولا رسالة تقول لماذا. والدقّة القصوى هنا لا تشتري
    // شيئاً — هذه نقطة ظهورٍ أوّليّة يصحّحها التدفّق خلال ثوانٍ.
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // آخر موقع معروف أفضل من لا شيء: يجعل السائق ظاهراً الآن، ثم يصحّحه
      // أوّل حدث من التدفّق.
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) {
      _say('تعذّر تحديد موقعك — اخرج إلى مكان مكشوف وأعد المحاولة.');
      return;
    }

    // موقعٌ مزيّف لا يُنشَر أصلاً.
    //
    // التوزيع عندنا جغرافيٌّ صرف: `g` وحدها تقرّر مَن يُعرَض عليه الطلب.
    // فسائقٌ بتطبيق تزييف يثبّت نفسه عند مدخل الحرم يحصد طلبات أزحم منطقة في
    // المدينة وهو في بيته، والراكب ينتظر سيّارةً على بعد ثمانية كيلومترات.
    //
    // وحدٌّ مُصارَحٌ به: `isMocked` جوهريّة على أندرويد وحده. على iOS تعيد
    // `false` دائماً، فهذا الحاجز لا يحميك هناك.
    if (position.isMocked) {
      _say('موقعك يبدو مزيَّفاً. أوقف تطبيقات الموقع الوهمي ثم أعد المحاولة.');
      return;
    }

    // يُسجَّل قبل أول كتابة: لو مات التطبيق بعدها مباشرةً، يمحو الخادمُ
    // السائقَ من القائمة بدل أن يبقى ظاهراً لا يجيب.
    await DriverService.clearOnDisconnect();
    await DriverService.goOnline(position);

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: _trackingSettings).listen(
      (Position p) {
        // ولا يُسقَط بصمت: إسقاطه يعيد بالضبط حالة السائق الشبح — المفتاح
        // يقول «متّصل»، وآخر موقع صادق باقٍ في `onlineDrivers`، و`onDisconnect`
        // لا يعمل لأنّ المقبس حيّ. يُخبَر ويُخرَج، كما يُفعل مع أيّ خطأ.
        if (p.isMocked) {
          _say('توقّف البثّ: موقعك يبدو مزيَّفاً.');
          _goOffline();
          return;
        }

        _position = p;
        DriverService.publishLocation(p);

        // وأثناء الرحلة يُكتب الموضع على الرحلة نفسها — وهو ما يرسم السيّارة
        // على خريطة الراكب. بدونه يرى الراكب اسم سائق ولا يرى أين هو.
        final String? trip = _tripId;
        if (trip != null && _tripStarted) {
          DriverService.publishTripLocation(trip, p);
        }
      },
      // تدفّقٌ بلا `onError` ينتهي بصمت حين يُطفأ GPS أثناء الاتصال: يبقى
      // المفتاح «متصل» ولا يُبثّ شيء — سائقٌ شبح على خريطة الراكب.
      onError: (Object error) {
        if (!mounted) return;
        _say('انقطع تتبّع الموقع — أعد الاتصال.');
        _goOffline();
      },
      cancelOnError: true,
    );

    if (!mounted) return;
    setState(() {
      _online = true;
      _position = position;
    });
  }

  Future<void> _goOffline() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await DriverService.goOffline();

    if (!mounted) return;
    setState(() => _online = false);
  }

  /// إذن الإشعارات — يُطلب وقت التشغيل، لا بإعلانه في البيان وحده.
  ///
  /// `POST_NOTIFICATIONS` معلَنة في AndroidManifest منذ إضافة خدمة المقدّمة،
  /// ولا شيء في التطبيق كان يطلبها. وعلى أندرويد ١٣ فما فوق يعني ذلك أنّ
  /// إشعار «أنت متّصل» **يُنشَر ولا يُعرَض**: الخدمة تعمل والسائق لا يرى
  /// دليلاً واحداً على أنّه متّصل. وهو بعينه الالتباس الذي كُتبت الخدمة
  /// لمنعه — سائقٌ يعمل وسائقٌ يظنّ أنه يعمل.
  ///
  /// ويُطلب هنا لا عند إقلاع التطبيق: لحظةُ قلبِ المفتاح هي اللحظة الوحيدة
  /// التي يفهم فيها السائق **لماذا** يُسأل. وطلبٌ عند الإقلاع بلا سياق
  /// يُرفَض انعكاساً، والرفض على أندرويد لا رجعة فيه إلا من الإعدادات.
  ///
  /// ولا يُوضَع داخل `_goOnline()`: تلك يستدعيها أيضاً استئنافُ رحلة جارية،
  /// فيُقذَف حوارٌ في وجه سائق يقود.
  Future<void> _askNotificationPermission() async {
    // أندرويد وحده: على iOS يفتح هذا حوار APNs لقدرةٍ لا يملكها التطبيق بعد.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final PermissionStatus status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
    // ولا يُعلَّق الاتصال على الجواب: من رفض الإشعار يبقى قادراً على العمل.
  }

  /// نافذة العتاد الصينيّ — تُعرَض مرّةً واحدة في عمر التثبيت.
  ///
  /// خدمة المقدّمة عقدٌ مع أندرويد الأصليّ، و**MIUI وEMUI وColorOS تنقضه**:
  /// تقتل العمليّة رغم الخدمة ما لم يكن التطبيق في قائمة البطاريّة البيضاء.
  /// ولMIUI فوق ذلك مفتاح «التشغيل التلقائي» **لا يقرؤه ولا يضبطه أيّ واجهة
  /// برمجيّة في أندرويد** — لا من التطبيق ولا من أيّ حزمة.
  ///
  /// أي أنّ ما بنيناه من خدمة مقدّمة لا يكفي وحده على هذه الأجهزة، ولا شيء
  /// في الشيفرة يستطيع إصلاحه. الطريق الوحيد أن يفعلها السائق بيده — فيُقال
  /// له، بوضوح، مرّةً واحدة.
  ///
  /// ولا يُعلَن `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` في البيان: يجرّ
  /// مراجعةً إجباريّة في Play للنكهات الثلاث، ولا نحتاجه — قراءة الحالة
  /// وحدها لا تحتاج إذناً معلَناً.
  ///
  /// ويُعرَض النصّ حتى لو كانت البطاريّة غير مقيَّدة: الفحص أعمى تماماً عن
  /// مفتاح «التشغيل التلقائي»، فسائقٌ مستثنىً من قيود البطاريّة يُقتَل مع
  /// ذلك. تُليَّن الفقرة الأولى فقط.
  Future<void> _showBatteryAdviceOnce() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_batteryAdviceKey) ?? false) return;

    final bool unrestricted =
        await Permission.ignoreBatteryOptimizations.isGranted;

    await prefs.setBool(_batteryAdviceKey, true);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('كي تبقى متّصلاً والشاشة مقفلة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!unrestricted) ...<Widget>[
                const Text(
                  '١) إعدادات الهاتف ← التطبيقات ← Taibah سائق ← البطاريّة\n'
                  '    اختر «بلا قيود».',
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'مع أجهزة شاومي وهواوي وأوبو فعّل أيضاً «التشغيل التلقائي» '
                '(Autostart).',
              ),
              const SizedBox(height: 12),
              const Text(
                'ثم ثبّت التطبيق في قائمة المهامّ الأخيرة (القفل الصغير) — '
                'فإزالته من القائمة توقف البثّ مهما كانت الإعدادات.',
              ),
              const SizedBox(height: 14),
              Text(
                'بدون ذلك قد يُغلق النظام التطبيق وأنت تقود، فلا تصلك طلبات '
                'ويختفي موقعك عن الركّاب.',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('افتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  static const String _batteryAdviceKey = 'driver_battery_advice_shown';

  /// إعادة تشغيل البثّ لرحلة استُرجعت بعد إعادة تشغيل التطبيق.
  Future<void> _resumeLocationForTrip() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    final LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    await _goOnline();
  }

  /// حوارٌ بزرّ يفتح الإعداد المطلوب.
  ///
  /// شريطٌ سفليّ يقول «افتح الإعدادات» يختفي بعد ثانيتين ولا يفتح شيئاً. وهذه
  /// حالة يقف فيها السائق تماماً — فتستحقّ حواراً وزرّاً يعمل.
  void _askToOpen({
    required String title,
    required String body,
    required Future<bool> Function() open,
  }) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              open();
            },
            child: const Text('افتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /* ── البناء ────────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final Object? car = widget.profile['car_details'];
    final String carText = car is Map
        ? '${car['model'] ?? ''} · ${car['number'] ?? ''}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profile['name'] ?? 'السائق'}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'الأرباح',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const DriverEarningsPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'خروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (_online) await _goOffline();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _StatusCard(
            online: _online,
            busy: _busy,
            carText: carText,
            position: _position,
            onChanged: _toggleOnline,
          ),
          Expanded(
            child: _tripId == null
                ? _Idle(online: _online, position: _position)
                : DriverTripPanel(
                    tripId: _tripId!,
                    profile: widget.profile,
                    position: _position,
                    // يُرفع **قبل** الكتابة لا بعدها.
                    //
                    // `acceptTrip` تكتب `newTripStatus = 'idle'`، وRTDB يُطلق
                    // الحدث محلياً قبل أن يعود `await`. فكان المستمع يرى
                    // `idle` والعلم لم يُرفع بعد، فيمسح اللوحة في اللحظة التي
                    // ضغط فيها السائق «قبول» — القاعدة تقول إنّ الرحلة له،
                    // وشاشته تقول إنّه على الخريطة.
                    onAccepting: () => setState(() => _tripStarted = true),
                    onAcceptFailed: () => setState(() => _tripStarted = false),
                    onFinished: () => setState(() {
                      _tripId = null;
                      _tripStarted = false;
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.online,
    required this.busy,
    required this.carText,
    required this.position,
    required this.onChanged,
  });

  final bool online;
  final bool busy;
  final String carText;
  final Position? position;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    online ? 'متصل' : 'غير متصل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: online ? Colors.green : Colors.black54,
                    ),
                  ),
                  if (carText.isNotEmpty)
                    Text(
                      carText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  if (online && position != null)
                    Text(
                      '${position!.latitude.toStringAsFixed(4)}, '
                      '${position!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(value: online, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// الانتظار — على خريطة لا على فراغ.
///
/// كانت الشاشة بين الطلبات مساحةً بيضاء فيها سطران. وهي الشاشة التي يقضي
/// السائق أمامها أطول وقته، ولا تقول له شيئاً يحتاجه: أين هو، وأين يقف، وهل
/// موقعه الذي تراه الخدمة هو موقعه فعلاً.
///
/// والسؤال الأخير هو الجوهر. إحداثيّتان مكتوبتان بالأرقام لا تُقرآن — أمّا
/// دبّوسٌ في الحيّ الخطأ فيُرى فوراً. فالخريطة هنا ليست زينة بل أداة تحقّق:
/// السائق أوّل من يكتشف أنّ موقعه غلط، قبل أن يُرسَل إليه راكب من حيّ آخر.
class _Idle extends StatefulWidget {
  const _Idle({required this.online, required this.position});

  final bool online;
  final Position? position;

  @override
  State<_Idle> createState() => _IdleState();
}

class _IdleState extends State<_Idle> {
  TaibahMapController? _controller;

  @override
  void didUpdateWidget(covariant _Idle oldWidget) {
    super.didUpdateWidget(oldWidget);

    final Position? now = widget.position;
    if (now == null || _controller == null) return;

    // أوّل موقع يستدعي قفزةً إلى مكانه؛ وما بعده تتبُّعٌ ناعم. ولولا الشرط
    // لعادت الكاميرا إلى السائق كلّما تحرّك عشرين متراً، فلا يستطيع أن ينظر
    // إلى شارعٍ مجاور.
    if (oldWidget.position == null) {
      _controller!.moveTo(LatLng(now.latitude, now.longitude), 15.5);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Position? at = widget.position;

    final Set<Marker> markers = <Marker>{
      if (at != null)
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(at.latitude, at.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'موقعك كما تراه الخدمة'),
        ),
    };

    return Stack(
      children: <Widget>[
        TaibahMap(
          initial: at == null
              ? null
              : CameraPosition(
                  target: LatLng(at.latitude, at.longitude),
                  zoom: 15.5,
                ),
          markers: markers,
          myLocation: widget.online,
          onReady: (TaibahMapController c) => _controller = c,
          padding: const EdgeInsets.only(bottom: 96),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _IdleBanner(online: widget.online),
        ),
      ],
    );
  }
}

class _IdleBanner extends StatelessWidget {
  const _IdleBanner({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(
          online ? Icons.wifi_tethering : Icons.wifi_tethering_off,
          size: 32,
          color: online ? Colors.green : Colors.black26,
        ),
        title: Text(
          online ? 'بانتظار طلب' : 'أنت غير متصل',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          online
              ? 'موقعك يُحدَّث تلقائياً. أبقِ الشاشة مفتوحة لتصلك الطلبات.'
              : 'لن تصلك طلبات ولن يراك أحد حتى تتصل.',
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
