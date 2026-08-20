import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_projects/admin/admin_gate.dart';
import 'package:flutter_projects/widgets/connectivity_banner.dart';
import 'package:flutter_projects/theme/taibah_splash.dart';
import 'package:flutter_projects/app_bootstrap.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/theme/app_theme.dart';

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
      title: '${TaibahBrand.nameLatin} إدارة',
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

      theme: TaibahTheme.of(AppRole.admin),

      // نفس شاشة البداية التي يراها الراكب، بلون هذه النكهة.
      // والثلاث ثوانٍ ليست انتظاراً فارغاً: Firebase يستعيد الجلسة
      // خلالها، فلولاها لظهرت شاشة الدخول ثم اختفت لمن هو داخلٌ أصلاً.
      // الشريط فوق الـNavigator كي يظهر على أيّ شاشة. والنصّ حرفيّ هنا لأنّ
      // هذه النكهة عربيّةٌ مثبَّتة ولا مندوب ترجمة مسجَّلاً فيها — قراءةُ
      // الترجمة هنا تعطي `null` وتستبدل التطبيق بشاشة خطأ.
      builder: (BuildContext context, Widget? child) => ConnectivityBanner(
        message: 'لا يوجد اتصال بالإنترنت',
        child: child ?? const SizedBox.shrink(),
      ),
      home: TaibahSplash(next: () => const AdminGate()),
    );
  }
}
