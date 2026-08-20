import 'package:flutter/material.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/theme/taibah_mark.dart';
import '../l10n/app_localizations.dart';

/// «عن التطبيق».
///
/// **كانت هذه آخر شاشة بقي فيها القالب كاملاً.** شعار «OAGo RIDE» بالحرف
/// اللاتينيّ، ونصٌّ يَعِد بتأجير السيّارات وإعارة أصحابها سيّاراتِهم
/// للمسافرين، وبحجز الفنادق والمساعدة في السفر. ولا واحدة منها موجودة في هذا
/// التطبيق ولا في خطّته القريبة — وهي بالضبط الوعود التي أُزيلت من شاشة
/// التعريف، فبقيت هنا تناقضها على بُعد نقرتين.
///
/// والنصّ الجديد لا يعد بشيء لا يفعله التطبيق اليوم.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TaibahPalette.of(AppFlavor.role).primary,
        title: Text(
          AppLocalizations.of(context)!.aboutTitle,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // العلامة نفسها التي في شاشة البداية وشاشة الدخول — لا صورة
            // ثانية تُنسى حين تتغيّر الهويّة.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: TaibahMark(role: AppFlavor.role, size: 58),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.aboutDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.feedbackText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                AppLocalizations.of(context)!.copyright,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
