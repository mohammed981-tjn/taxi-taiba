import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/locale_provider.dart';
import 'package:flutter_projects/pages/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
const String _rtdbUrl = String.fromEnvironment(
  'RTDB_URL',
  defaultValue:
      'https://taxi-taiba-default-rtdb.europe-west1.firebasedatabase.app',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    // Reads android/app/google-services.json — which is the whole of the
    // configuration on mobile. Nothing below applies here.
    await Firebase.initializeApp();
  } else {
    // Desktop and web have no google-services.json, so the values are literal.
    //
    // They used to be rdidago's — the original developer's project — which made
    // this branch point at a database nobody here owns. It is dead code on the
    // platforms actually built, which is exactly why it went unnoticed.
    //
    // The web appId is not the Android one and cannot be guessed: take it from
    // the web app registered in the Firebase console when web is first built.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDaFmqNkd7IrNUOwvTvY5AQk0nt-kaMJ0k",
        authDomain: "taxi-taiba.firebaseapp.com",
        // Empty until the Realtime Database instance exists. The region is part
        // of the host outside us-central1, so it cannot be derived from the
        // project id — pass it in rather than assume:
        //   --dart-define=RTDB_URL=https://taxi-taiba-default-rtdb...
        databaseURL: _rtdbUrl,
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
  FirebaseDatabase.instance.databaseURL = _rtdbUrl;

  // صلاحية الموقع
  await Permission.locationWhenInUse.isDenied.then((value) {
    if (value) {
      Permission.locationWhenInUse.request();
    }
  });

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root of application
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppInfo()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()..loadLocale()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)?.appTitle ?? 'Users App',
            debugShowCheckedModeBanner: false,

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),

            // 🔹 اللغة الحالية (تتغيّر عبر LocaleProvider) — RTL تلقائي للعربية
            locale: localeProvider.locale,

            // 🔹 اللغات المدعومة + مفوّضو الترجمة (المولّدة + العامة من Flutter)
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,

            // شاشة البداية
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
