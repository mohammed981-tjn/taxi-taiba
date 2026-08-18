import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_projects/app_bootstrap.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/locale_provider.dart';
import 'package:flutter_projects/pages/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

/// نقطة دخول تطبيق الراكب — وهي الافتراضية، فـ`flutter build` يقصدها بلا `-t`.
///
/// ولا تستورد شيئاً من `lib/admin/`. هذا ليس ترتيباً بل شرط: ما يُستورد
/// يُشحن، وشاشات الإدارة لا مكان لها في هاتف راكب. الحجّة كاملةً في
/// `app_flavor.dart`.
///
/// وإقلاع Firebase انتقل إلى `app_bootstrap.dart` لمّا صارت نقاط الدخول أكثر
/// من واحدة — نسخُه هنا وهناك هو ما يجعل نسخةً تُصلَح وأخرى تُنسى.
void main() async {
  AppFlavor.configure(AppRole.passenger);

  await bootstrapFirebase();

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
