import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/theme/taibah_logo.dart';

/// شاشة البداية — واحدة للنكهات الثلاث.
///
/// ثلاث ثوانٍ، وهي مدّة مقصودة: أقلّ من ثانيتين يجعل الحركة ترتجف بلا معنى،
/// وأكثر من ثلاث ينتظر المستخدم بلا سبب. وفي هذه الثلاث يجري شيء حقيقي —
/// Firebase يستعيد جلسة المستخدم، فلو انتقلنا فوراً لظهرت شاشة الدخول ثم
/// اختفت. الانتظار هنا يخفي وميضاً لا يخترعه.
///
/// والحركة ليست زينة: الشعار يظهر من الشفافية ويصعد قليلاً، فتتبعه العين إلى
/// موضعه في شاشة الدخول التالية بدل أن تبحث عنه من جديد.
class TaibahSplash extends StatefulWidget {
  const TaibahSplash({
    super.key,
    required this.next,
    this.role,
    this.duration = const Duration(seconds: 3),
  });

  /// يُستدعى بعد انتهاء المدّة — وهو ما يقرّر الوجهة، لا هذه الشاشة.
  final Widget Function() next;

  final AppRole? role;
  final Duration duration;

  @override
  State<TaibahSplash> createState() => _TaibahSplashState();
}

class _TaibahSplashState extends State<TaibahSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();

    // المؤقّت هنا لا في `build`: الشيفرة السابقة كانت تستدعي `Future.delayed`
    // داخل `build`، فكل إعادة بناء تجدول انتقالاً جديداً — ثلاثة مؤقّتات تنقل
    // ثلاث مرّات.
    _timer = Timer(widget.duration, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => widget.next(),
          transitionsBuilder: (_, Animation<double> animation, __, Widget c) =>
              FadeTransition(opacity: animation, child: c),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppRole role = widget.role ?? AppFlavor.role;
    final TaibahPalette palette = TaibahPalette.of(role);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // شريط الحالة يُطابق الخلفية الداكنة، فلا يظهر شريطٌ فاتح فوق التدرّج.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: palette.primaryDeep,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[palette.primary, palette.primaryDeep],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.18),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    )),
                    child: TaibahWordmark(
                      role: role,
                      onDark: true,
                      logoSize: 96,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    // يتأخّر عن الشعار: الترتيب يجعل العين تقرأ العلامة أولاً.
                    curve: const Interval(0.5, 1, curve: Curves.easeIn),
                  ),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
