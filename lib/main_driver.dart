import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_projects/app_bootstrap.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/driver/driver_gate.dart';
import 'package:permission_handler/permission_handler.dart';

/// نقطة دخول تطبيق السائق.
///
///   flutter build apk --release -t lib/main_driver.dart
///
/// لا تستورد شاشات الراكب ولا شاشات الإدارة. الحجّة في `app_flavor.dart`:
/// مترجم Dart يشحن كل ما يُبلَغ من `main()`، فالفصل على مستوى نقطة الدخول لا
/// على مستوى شرطٍ وقت التشغيل.
void main() async {
  AppFlavor.configure(AppRole.driver);

  await bootstrapFirebase();

  // السائق يحتاج الموقع أكثر من الراكب: موقعه هو المنتَج. وطلبه هنا قبل أيّ
  // شاشة كي لا يصل إلى زرّ «اتصال» ثم يُرفض.
  await Permission.locationWhenInUse.isDenied.then((bool denied) {
    if (denied) Permission.locationWhenInUse.request();
  });

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'طيبة — السائق',
      debugShowCheckedModeBanner: false,

      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      home: const DriverGate(),
    );
  }
}
