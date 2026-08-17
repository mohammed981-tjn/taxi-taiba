import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/locale_provider.dart';
import 'package:flutter_projects/pages/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCglOwiavIK2Qzr4PAP_WTC-GcmjASKcA8",
        authDomain: "rdidago.firebaseapp.com",
        databaseURL: "https://rdidago-default-rtdb.firebaseio.com",
        projectId: "rdidago",
        storageBucket: "rdidago.firebasestorage.app",
        messagingSenderId: "433322846976",
        appId: "1:433322846976:web:a32c8e4f2cee41976821e5",
        measurementId: "G-0FHCN9T6LP",
      ),
    );
  }

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
