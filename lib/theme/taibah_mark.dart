import 'package:flutter/material.dart';

import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/theme/app_theme.dart';

/// القوس المنساب — الحركة بلا سيّارة مرسومة.
///
/// كلّ التصاميم التي حملت سيّارةً كانت جميلةً كخلفيّة إعلان وضارّةً كشعار:
/// الشعار يُصغَّر إلى مربّع ٤٨ بكسل على شريط الإشعارات وفي درج التطبيقات،
/// وسيّارةٌ بمرايا ومصابيح تصير هناك لطخة. والقوس يبقى قوساً.
///
/// ومرسومٌ متجهاً لا صورةً: يكبر ويصغر بلا فقدان حدّة، ويتلوّن بالنكهة، ولا
/// يزن بايتاً واحداً في الحزمة — بخلاف صورةٍ تحتاج خمس كثافات لكلّ نكهة.
class TaibahSwoosh extends StatelessWidget {
  const TaibahSwoosh({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 0.62,
        child: CustomPaint(painter: _SwooshPainter(color)),
      );
}

class _SwooshPainter extends CustomPainter {
  const _SwooshPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // قوسٌ يبدأ رفيعاً من اليسار ويثخن في المنعطف ثم يدقّ عند الرأس — سُمكٌ
    // متغيّر يوحي بالتسارع. ولذلك رُسم مساحةً مغلقة لا خطّاً بسُمكٍ ثابت.
    final Path arc = Path()
      ..moveTo(w * 0.02, h * 0.30)
      ..cubicTo(w * 0.34, h * 0.10, w * 0.70, h * 0.16, w * 0.88, h * 0.44)
      ..lineTo(w * 0.74, h * 0.50)
      ..cubicTo(w * 0.60, h * 0.30, w * 0.32, h * 0.26, w * 0.02, h * 0.38)
      ..close();

    canvas.drawPath(arc, paint);

    // الذيل السفليّ: قوسٌ ثانٍ أقصر يلفّ تحت الأوّل، فيصير الشكل انسياباً
    // مغلقاً لا خطّاً معلّقاً.
    final Path tail = Path()
      ..moveTo(w * 0.96, h * 0.34)
      ..cubicTo(w * 1.02, h * 0.72, w * 0.72, h * 0.98, w * 0.36, h * 0.94)
      ..lineTo(w * 0.40, h * 0.80)
      ..cubicTo(w * 0.68, h * 0.82, w * 0.88, h * 0.64, w * 0.84, h * 0.36)
      ..close();

    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant _SwooshPainter old) => old.color != color;
}

/// علامة طيبة — الاسم العربيّ والقوس معاً.
///
/// الاسم **نصٌّ حقيقيّ** بخطّ Cairo لا صورة: يُرسم حادّاً على كلّ كثافة، ولا
/// يحتاج ملفّاً، ويتبع وزن الخطّ الذي يشحنه التطبيق أصلاً.
///
/// و«طيبه» بالعربيّة لا `Taibah` باللاتينيّة: راكبك في المدينة المنوّرة يقرأ
/// الأولى قبل الثانية، وهي تُنطق كما تُكتب — بلا تردّدٍ بين Taiba وTaybah
/// وTaibah، وهو تردّدٌ وقع فيه صاحب المشروع نفسه.
class TaibahMark extends StatelessWidget {
  const TaibahMark({
    super.key,
    this.role,
    this.size = 64,
    this.onDark = false,
    this.showTagline = true,
  });

  final AppRole? role;

  /// ارتفاع الاسم — وكلّ ما عداه مشتقٌّ منه.
  final double size;

  final bool onDark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final AppRole effective = role ?? AppFlavor.role;
    final TaibahPalette palette = TaibahPalette.of(effective);

    final Color ink = onDark ? Colors.white : palette.primary;
    final Color accent = palette.accent;
    final String suffix = TaibahBrand.suffixFor(effective);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // القوس فوق الاسم ومزاحٌ إلى جهة الحركة — كما في التصميم المختار.
        // مزاحٌ إلى **اليمين**، فوق آخر الاسم — كما في التصميم المختار.
        // و`EdgeInsets` غير اتّجاهيّة، فالحشو على اليسار هو ما يدفع القوس
        // يميناً.
        Padding(
          padding: EdgeInsets.only(bottom: size * 0.04, left: size * 0.70),
          child: TaibahSwoosh(size: size * 1.05, color: accent),
        ),

        // ولا يُقصّ حين تضيق النافذة.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                TaibahBrand.nameArabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: size,
                  fontWeight: FontWeight.w700,
                  color: onDark ? accent : palette.primary,
                  height: 1.1,
                ),
              ),
              if (suffix.isNotEmpty) ...<Widget>[
                SizedBox(width: size * 0.16),
                Text(
                  suffix,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.80),
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (showTagline) ...<Widget>[
          SizedBox(height: size * 0.14),
          Text(
            TaibahBrand.taglineFor(effective),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: size * 0.20,
              color: ink.withValues(alpha: 0.62),
            ),
          ),
          SizedBox(height: size * 0.06),
          // سطرٌ لاتينيّ صغير — للسائق الوافد الذي لا يقرأ العربيّة بعد،
          // ولأنّ اسم الحزمة ومتجر التطبيقات لاتينيّان على كلّ حال.
          Text(
            TaibahBrand.latinLineFor(effective),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: size * 0.135,
              letterSpacing: size * 0.055,
              fontWeight: FontWeight.w600,
              color: ink.withValues(alpha: 0.42),
            ),
          ),
        ],
      ],
    );
  }
}
