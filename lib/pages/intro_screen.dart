import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/auth/signin_page.dart';
import 'package:flutter_projects/auth/signup_page.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/locale_provider.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/theme/taibah_mark.dart';

/// شاشة التعريف — المكان الوحيد الذي تنتمي إليه الصورة.
///
/// رُفضت الصور الفوتوغرافيّة في شاشة البداية لأنّها تُرى ثلاث ثوانٍ ويجب أن
/// تظهر فوراً، فصورةٌ ثقيلة تصل متأخّرةً على هاتفٍ ضعيف. وهنا العكس تماماً:
/// المستخدم يمسك الهاتف ويمرّر بإصبعه، والصورة **محتوى** لا زخرفة — هي التي
/// تقنعه أنّ هذا تطبيقٌ جادّ قبل أن يعطيك رقمه.
///
/// وتُعرَض مرّةً واحدة في عمر التثبيت، فوزنها يُدفع مرّة. والثلاث مجتمعةً ١٣٨
/// كيلوبايت: قُصّت من صور صاحب المشروع عند المناطق النظيفة — النصّ محروقٌ فيها
/// بمقاسٍ ثابت لا يصلح البناء عليه — ثمّ صُغِّرت وضُغطت.
///
/// **وأهمّ ما تغيّر ليس الصور.** كانت ستّ شاشات تَعِد بتأجير سيّارتك وحجز
/// الفنادق واستئجار سائقين للرحلات الطويلة — خدماتٌ لا وجود لها في هذا
/// التطبيق ولا في خطّته. ذلك نصّ القالب النيجيريّ، وهو وعدٌ يقرؤه الراكب قبل
/// أن يسجّل ثمّ لا يجده. صارت ثلاثاً، وكلّ جملةٍ فيها يفعلها التطبيق فعلاً.
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TaibahPalette palette = TaibahPalette.of(AppRole.passenger);
    final bool isArabic =
        context.watch<LocaleProvider>().locale.languageCode == 'ar';

    final List<_Slide> slides = <_Slide>[
      _Slide('assets/intro/road.jpg', l10n.introHeadline1, l10n.introDesc1),
      _Slide('assets/intro/car.jpg', l10n.introHeadline2, l10n.introDesc2),
      _Slide('assets/intro/city.jpg', l10n.introHeadline3, l10n.introDesc3),
    ];

    final bool last = _index == slides.length - 1;

    return Scaffold(
      backgroundColor: palette.primaryDeep,
      body: Stack(
        children: <Widget>[
          // الصورة تملأ الشاشة خلف كلّ شيء، وتتبدّل بالتمرير.
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (int i) => setState(() => _index = i),
              itemBuilder: (BuildContext context, int i) => Image.asset(
                slides[i].image,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                // الصورة رفاهية: غيابها لا يترك شاشةً مكسورة.
                errorBuilder: (_, __, ___) =>
                    ColoredBox(color: palette.primaryDeep),
              ),
            ),
          ),

          // ستارٌ متدرّج — لولاه لا يُقرأ نصٌّ أبيض على صورة فيها مصابيح
          // وسماء. ويثقل نحو الأسفل حيث النصّ، ويخفّ فوق حيث الصورة.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    palette.primaryDeep.withValues(alpha: 0.72),
                    palette.primaryDeep.withValues(alpha: 0.30),
                    palette.primaryDeep.withValues(alpha: 0.94),
                    palette.primaryDeep,
                  ],
                  stops: const <double>[0, 0.30, 0.66, 1],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: <Widget>[
                      const TaibahMark(
                        role: AppRole.passenger,
                        onDark: true,
                        size: 26,
                        showTagline: false,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<LocaleProvider>().toggleLocale(),
                        icon: const Icon(Icons.language,
                            color: Colors.white70, size: 19),
                        label: Text(
                          isArabic ? 'English' : 'العربية',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // النصّ خارج الـPageView: يتبدّل معه، ولا يمرّر معه. تمريرُ
                // النصّ مع الصورة يجعل السطر يمرّ أمام العين وهي تقرؤه.
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Column(
                          key: ValueKey<int>(_index),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              slides[_index].headline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slides[_index].body,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontSize: 14.5,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          slides.length,
                          (int i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: i == _index ? 22 : 6,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? palette.accent
                                  : Colors.white.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.accent,
                          foregroundColor: const Color(0xFF241703),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (last) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const SignUpPage(),
                              ),
                            );
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        child: Text(
                          last ? l10n.signUp : l10n.introNext,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SigninPage(),
                          ),
                        ),
                        child: Text(
                          l10n.alreadyHaveAccount,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide(this.image, this.headline, this.body);

  final String image;
  final String headline;
  final String body;
}
