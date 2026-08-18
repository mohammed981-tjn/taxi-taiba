import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/theme/app_theme.dart';

/// شعار طيبة — مرسومٌ لا مستورَد.
///
/// لماذا `CustomPainter` بدل ملفّ PNG؟ ثلاثة أسباب عملية:
///
///   • **يتلوّن بالنكهة.** صورة واحدة تعني ثلاث صور، وثلاث صور تعني أن تُعدَّل
///     ألوان الهوية في ثلاثة أماكن ويُنسى أحدها.
///   • **لا يفقد حدّته.** يُرسم بحجم الشاشة أياً كان، ولا يحتاج نسخاً لكل
///     كثافة (mdpi … xxxhdpi) وهي خمس نسخ من كل صورة.
///   • **لا يزن شيئاً.** الحزمة الحالية تحمل `oago_logo.png` وأخواته من
///     القالب الأصلي؛ هذا لا يضيف بايتاً.
///
/// والشكل: حرف طاء مبسَّط داخل حلقة — قوسٌ مفتوح يوحي بالطريق، ونقطةٌ
/// كهرمانية هي الوجهة. بسيطٌ عمداً كي يُقرأ في مربّع ٤٨ بكسل على شريط
/// الإشعارات كما يُقرأ ملءَ شاشة البداية.
class TaibahLogo extends StatelessWidget {
  const TaibahLogo({
    super.key,
    required this.size,
    this.role,
    this.onDark = false,
  });

  final double size;

  /// النكهة التي تُلوّنه — الحالية إن لم تُذكر.
  final AppRole? role;

  /// على خلفية داكنة يُقلَب إلى الأبيض، ويبقى الكهرماني كما هو.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final TaibahPalette palette = TaibahPalette.of(role ?? AppFlavor.role);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TaibahLogoPainter(
          primary: onDark ? Colors.white : palette.primary,
          accent: palette.accent,
        ),
      ),
    );
  }
}

class _TaibahLogoPainter extends CustomPainter {
  _TaibahLogoPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2;

    // كل الأبعاد نسبةٌ من القطر، فالشكل واحدٌ عند كل حجم.
    final double stroke = r * 0.13;

    // الحلقة — مفتوحة من أعلى بزاوية ٧٠°، فتقرأها العين طريقاً لا دائرة.
    final Paint ring = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r - stroke * 0.9),
      _deg(-55),
      _deg(360 - 70),
      false,
      ring,
    );

    // ساق الطاء — عمودٌ يهبط من مركز الحلقة.
    final Paint stem = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      centre + Offset(-r * 0.02, -r * 0.34),
      centre + Offset(-r * 0.02, r * 0.30),
      stem,
    );

    // القاعدة الأفقية.
    canvas.drawLine(
      centre + Offset(-r * 0.34, r * 0.30),
      centre + Offset(r * 0.32, r * 0.30),
      stem,
    );

    // الوجهة — النقطة الكهرمانية في فتحة الحلقة.
    canvas.drawCircle(
      centre + Offset(r * 0.42, -r * 0.60),
      stroke * 0.85,
      Paint()..color = accent,
    );
  }

  double _deg(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(_TaibahLogoPainter old) =>
      old.primary != primary || old.accent != accent;
}

/// الشعار مع الاسم — كتلة العلامة في شاشات الدخول.
class TaibahWordmark extends StatelessWidget {
  const TaibahWordmark({
    super.key,
    this.role,
    this.onDark = false,
    this.logoSize = 76,
    this.showTagline = true,
  });

  final AppRole? role;
  final bool onDark;
  final double logoSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final AppRole effective = role ?? AppFlavor.role;
    final TaibahPalette palette = TaibahPalette.of(effective);
    final Color ink = onDark ? Colors.white : palette.primary;
    final String suffix = TaibahBrand.suffixFor(effective);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TaibahLogo(size: logoSize, role: effective, onDark: onDark),
        SizedBox(height: logoSize * 0.22),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              TaibahBrand.nameLatin,
              style: TextStyle(
                fontSize: logoSize * 0.44,
                fontWeight: FontWeight.w700,
                letterSpacing: logoSize * 0.02,
                color: ink,
              ),
            ),
            if (suffix.isNotEmpty) ...<Widget>[
              SizedBox(width: logoSize * 0.12),
              Text(
                suffix,
                style: TextStyle(
                  fontSize: logoSize * 0.26,
                  fontWeight: FontWeight.w500,
                  color: ink.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
        if (showTagline) ...<Widget>[
          SizedBox(height: logoSize * 0.08),
          Text(
            TaibahBrand.taglineFor(effective),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: logoSize * 0.17,
              color: ink.withValues(alpha: 0.62),
            ),
          ),
        ],
      ],
    );
  }
}
