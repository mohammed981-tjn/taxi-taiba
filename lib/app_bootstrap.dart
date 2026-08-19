import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The Realtime Database instance, in full.
///
/// This has to be stated rather than discovered. `google-services.json` carries
/// a `firebase_url` only for databases in us-central1; this one is in Belgium,
/// so the downloaded file has no such field and the SDK has nothing to derive
/// from — `FirebaseDatabase.instance` would resolve to a host that does not
/// exist, and every read would simply never arrive.
///
/// Overridable so a staging database needs no code change:
///   --dart-define=RTDB_URL=https://...
const String rtdbUrl = String.fromEnvironment(
  'RTDB_URL',
  defaultValue:
      'https://taxi-taiba-default-rtdb.europe-west1.firebasedatabase.app',
);

/// إقلاع Firebase — واحد لكل النكهات.
///
/// كان داخل `main.dart`، فصار هنا حين صارت نقاط الدخول أكثر من واحدة. ونسخُه
/// في كل نقطة دخول هو بالضبط ما يجعل نسخةً تُصلَح وأخرى تُنسى.
Future<void> bootstrapFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    // Reads android/app/google-services.json — which is the whole of the
    // configuration on mobile. Nothing below applies here.
    await Firebase.initializeApp();
  } else {
    // Desktop and web have no google-services.json, so the values are literal.
    //
    // The web appId is not the Android one and cannot be guessed: take it from
    // the web app registered in the Firebase console when web is first built.
    // That matters sooner than it looks — the admin flavour is the first thing
    // here meant to run on the web.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDaFmqNkd7IrNUOwvTvY5AQk0nt-kaMJ0k",
        authDomain: "taxi-taiba.firebaseapp.com",
        databaseURL: rtdbUrl,
        projectId: "taxi-taiba",
        storageBucket: "taxi-taiba.firebasestorage.app",
        messagingSenderId: "19401527632",
        appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
      ),
    );
  }

  // Set once here so every `FirebaseDatabase.instance` in the app resolves to
  // the Belgian host. The alternative — passing the URL at each of the call
  // sites — is the same value repeated in a dozen files, where one missed copy
  // fails silently rather than loudly.
  FirebaseDatabase.instance.databaseURL = rtdbUrl;

  _reportCrashes();
}

/// توصيل الأعطال.
///
/// لم يكن في المستودع كلّه أثرٌ لتقرير أعطال: لا Crashlytics ولا Sentry ولا
/// حتى `FlutterError.onError`. أي أنّ سائقاً يسقط تطبيقه في المدينة وسط رحلة
/// لا يترك خبراً — يعيد التشغيل، أو يحذف التطبيق، ولا نعرف أنّ شيئاً وقع.
/// والعطل الذي لا يُرى لا يُصلَح.
///
/// و`versionCode` رُبط برقم التشغيل تحديداً كي يُنسب العطل إلى بنائه. كان
/// نصف الترتيب قائماً بلا نصفه الآخر.
void _reportCrashes() {
  // الويب خارج هذا: الحزمة بلا تنفيذ هناك، ولوحة الإدارة تُبنى للويب.
  if (kIsWeb) return;
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

  // أخطاء إطار Flutter — البناء والتخطيط والرسم.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    crashlytics.recordFlutterFatalError(details);
  };

  // وما يقع خارج الإطار: أخطاء غير مُلتقَطة في `Future` ومناطق غير متزامنة —
  // وهي أكثر ما يقع في تطبيق كلّ شاشة فيه تُصغي إلى قاعدة بيانات.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}
