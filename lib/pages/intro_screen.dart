import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/auth/signup_page.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/locale_provider.dart';
import 'package:provider/provider.dart';
import '../auth/signin_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.locale.languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    List introData = [
      {
        'headline': l10n.introHeadline1,
        'description': l10n.introDesc1,
      },
      {
        'headline': l10n.introHeadline2,
        'description': l10n.introDesc2,
      },
      {
        'headline': l10n.introHeadline3,
        'description': l10n.introDesc3,
      },
      {
        'headline': l10n.introHeadline4,
        'description': l10n.introDesc4,
      },
      {
        'headline': l10n.introHeadline5,
        'description': l10n.introDesc5,
      },
      {
        'headline': l10n.introHeadline6,
        'description': l10n.introDesc6,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // زر تبديل اللغة (عربي / إنجليزي)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => context.read<LocaleProvider>().toggleLocale(),
                icon: const Icon(Icons.language, color: Colors.black),
                label: Text(
                  isArabic ? 'English' : 'العربية',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // صورة البداية (الشعار أو مقدمة جذابة)
            SizedBox(
              height: size.height * 0.35,
              child: Image.asset(
                'assets/images/oago_onboarding_${selectedIndex + 1}.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 100),
              ),
            ),

            SizedBox(height: size.height * 0.05),

            // المحتوى المتغيّر
            Expanded(
              child: PageView.builder(
                itemCount: introData.length,
                onPageChanged: (val) {
                  setState(() => selectedIndex = val);
                },
                itemBuilder: (context, index) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      introData[index]['headline'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        introData[index]['description'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // نقاط المؤشر (page indicator)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                introData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 10,
                  width: selectedIndex == index ? 28 : 10,
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? TaibahPalette.passenger.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // الأزرار
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: TaibahPalette.passenger.primary, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.signUp,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: TaibahPalette.passenger.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SigninPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: TaibahPalette.passenger.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.signIn,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
