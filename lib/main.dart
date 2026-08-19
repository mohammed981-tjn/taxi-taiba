import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_projects/app_bootstrap.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/locale_provider.dart';
import 'package:flutter_projects/pages/splash_screen.dart';
import 'package:flutter_projects/theme/app_theme.dart';
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
                AppLocalizations.of(context)?.appTitle ?? TaibahBrand.nameLatin,
            debugShowCheckedModeBanner: false,

            // الهوية من مكان واحد — راجع lib/theme/app_theme.dart. كانت
            // `seedColor: Colors.deepPurple`، وهي قيمة `flutter create`
            // الافتراضية التي لم يمسّها أحد.
            theme: TaibahTheme.of(AppRole.passenger),

            // اللغة — و`null` تعني «لغة الجهاز».
            //
            // كانت `Locale('en')` مثبَّتة في المزوّد، فيفتح التطبيق
            // بالإنجليزيّة على هاتف عربيّ في السعوديّة. و`null` تجعل Flutter
            // يوفّق لغة الجهاز مع المدعوم، ويقع على الأولى في
            // `supportedLocales` حين لا يجد — وهي العربيّة.
            locale: localeProvider.localeOrNull,

            // العربيّة أوّلاً: هذا الترتيب هو ما يُحسم به التوفيق حين لا
            // تُطابِق لغةُ الجهاز شيئاً.
            supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,

            // شاشة البداية
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
