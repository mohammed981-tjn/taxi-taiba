import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/pages/home_page.dart';
import 'package:flutter_projects/theme/taibah_splash.dart';

import 'intro_screen.dart';

/// شاشة بداية الراكب.
///
/// المظهر والمؤقّت انتقلا إلى `TaibahSplash` — واحدة للنكهات الثلاث. وما يبقى
/// هنا هو القرار وحده: إلى أين بعد الثلاث ثوانٍ.
///
/// وكانت الشيفرة السابقة تستدعي `Future.delayed` **داخل `build`**، فكل إعادة
/// بناء تجدول انتقالاً جديداً. لم يظهر ذلك لأن الشاشة نادراً ما تُبنى مرّتين،
/// لكنه عطلٌ ينتظر أول تغيير حجم أو لوحة مفاتيح.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TaibahSplash(
      next: () => FirebaseAuth.instance.currentUser == null
          ? const IntroPage()
          : const HomePage(),
    );
  }
}
