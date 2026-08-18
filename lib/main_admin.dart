import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_projects/admin/admin_gate.dart';
import 'package:flutter_projects/app_bootstrap.dart';
import 'package:flutter_projects/app_flavor.dart';

/// نقطة دخول لوحة الإدارة.
///
///   flutter build apk --release -t lib/main_admin.dart
///   flutter build web           -t lib/main_admin.dart   ← نفس الملف، بلا هجرة
///
/// لا تستورد شيئاً من `lib/pages/` — شاشات الراكب ليست هنا، وشاشات الإدارة
/// ليست هناك. الحجّة في `app_flavor.dart`.
void main() async {
  AppFlavor.configure(AppRole.admin);

  await bootstrapFirebase();

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لوحة تحكّم طيبة',
      debugShowCheckedModeBanner: false,

      // اللوحة عربية ثابتة، بلا مبدّل لغة. أداة داخلية لمستخدم واحد لا تحتاج
      // ٤٠ مفتاح ترجمة، ونصوصها مكتوبة في مكانها. لو صار لها مشغّلون بلغات
      // أخرى فهذا وقت نقلها إلى ARB — لا قبله.
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF010E4C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      home: const AdminGate(),
    );
  }
}
