import 'package:flutter/material.dart';
import 'package:flutter_projects/auth/guest_session.dart';
import 'package:flutter_projects/pages/home_page.dart';
import 'package:flutter_projects/theme/taibah_splash.dart';

import 'intro_screen.dart';

/// شاشة بداية الراكب.
///
/// المظهر والمؤقّت في `TaibahSplash` — واحدة للنكهات الثلاث. وما يبقى هنا هو
/// القرار وحده: إلى أين بعد الثلاث ثوانٍ.
///
/// **وقد تغيّر القرار.** كان: من ليس مسجّلاً ← شاشة التعريف ← شاشة الدخول.
/// أي أنّ أوّل ما يُطلب ممّن نزّل التطبيق بريدٌ وكلمة سرّ، قبل أن يرى سيّارةً
/// واحدة أو سعراً واحداً. وصار: الجميع ← الشاشة الرئيسيّة. شاشة التعريف مرّةً
/// في عمر التثبيت، والدخول يُطلب عند طلب الرحلة لا قبلها.
///
/// والثلاث ثوانٍ يجري فيها الآن عملٌ حقيقيّ لا انتظار: Firebase يستعيد الجلسة،
/// أو يُنشئ جلسة ضيف لمن لا جلسة له.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _introSeen = true;

  /// يُنشأ مرّةً واحدة — `late final` لا استدعاءٌ في `build`، وإلّا أعادت كلّ
  /// إعادة بناءٍ تشغيلَ الدخول المجهول من جديد.
  late final Future<void> _ready = _prepare();

  Future<void> _prepare() async {
    _introSeen = await GuestSession.introSeen();
    await GuestSession.ensure();
  }

  @override
  Widget build(BuildContext context) {
    return TaibahSplash(
      waitFor: _ready,
      // ومن له حسابٌ قائم لا تُعرض عليه شاشة التعريف ولو لم تُسجَّل رؤيته:
      // التثبيت الذي سبق هذا التغيير لا يحمل العلم، وليس من المعقول أن تُعرض
      // «تعرّف على التطبيق» على من يستعمله منذ شهر.
      next: () => (_introSeen || GuestSession.isSignedIn)
          ? const HomePage()
          : const IntroPage(),
    );
  }
}
