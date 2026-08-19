import 'package:google_maps_flutter/google_maps_flutter.dart';

/// الأسواق — كلٌّ معرَّفٌ كاملاً، وواحدٌ منها فعّال.
///
/// **الفكرة:** كل ما يتغيّر بتغيّر البلد يجتمع في مكان واحد — البلد الذي يبحث
/// فيه الإكمال التلقائي، والعملة، ومركز الخريطة، وشكل رقم الهاتف. وكانت هذه
/// أربعة ثوابت متفرّقة في ثلاثة ملفّات، فإضافة سوق تعني تعديل ثلاثة أماكن
/// وتذكُّر رابعٍ لا يخطر على البال.
///
/// **والسودان معرَّفٌ هنا اليوم ولا يظهر لأحد.** لا شيء في التطبيق يعرض
/// خياراً بين سوقين، ولا يستطيع مستخدم بلوغه: السوق يُنتخَب عند البناء لا عند
/// التشغيل. فحين تريد البدء من الخرطوم:
///
///   Settings ← Variables ← MARKET = SD
///
/// ويُبنى كل شيء جاهزاً. لا تعديل شيفرة، ولا شيء يُكتشَف ناقصاً يومها — لأن
/// الجاهزية تُكتب اليوم وتُختبر مع كل بناء، لا تُترك لليوم الذي تُحتاج فيه.
///
/// وسببٌ ثانٍ لانتخابه عند البناء لا عند التشغيل: مفتاح خرائط مقيَّد ببلد،
/// وقواعد ترخيص نقل تختلف بين البلدين. حزمةٌ تخدم سوقين في وقت واحد تحتاج
/// قراراً تنظيمياً لا خياراً في قائمة.
class Market {
  const Market({
    required this.id,
    required this.name,
    required this.placesCountries,
    required this.currency,
    required this.centreLat,
    required this.centreLng,
    required this.dialCode,
    required this.phoneHint,
    required this.phoneLength,
  });

  /// رمز ISO — وهو نفسه قيمة `--dart-define=MARKET`.
  final String id;

  final String name;

  /// ما يُمرَّر إلى Places، ويقبل عدّة بلدان مفصولة بـ`|`.
  final String placesCountries;

  final String currency;

  final double centreLat;
  final double centreLng;

  /// ما يُعرَض على خريطة الراكب.
  ///
  /// خمسة كيلومترات لا اثنان وعشرون. الفرق ليس تجميلاً: الاستعلام بنصف قطر
  /// ٢٢ كم يغطّي مساحةً تتجاوز ألفي كيلومتر مربّع — أي المدينة كلّها — فيتدفّق
  /// كلّ سائق فيها إلى كلّ هاتف ليُرسَم دبّوساً على حافّة الشاشة لا يعني
  /// راكباً ينتظر أمام بيته. ومع كلّ سائق يتحرّك يُعاد رسم الخريطة.
  ///
  /// والراكب لا يستفيد من سائق يبعد عشرين كيلومتراً في العرض؛ يستفيد منه في
  /// الإرسال وحده، وذاك نطاقٌ آخر.
  double get displayRadiusMeters => 5000;

  /// وما يُبحث فيه عن سائق حين يُطلب فعلاً — أوسع، لأنّ رحلةً بعد عشرين دقيقة
  /// أفضل من «لا يوجد سائقون».
  double get dispatchRadiusMeters => 22000;

  final String dialCode;
  final String phoneHint;

  /// طول الرقم المحلّي — يُستعمل في التحقّق بدل رقمٍ عامّ.
  final int phoneLength;

  CameraPosition get camera => CameraPosition(
        target: LatLng(centreLat, centreLng),
        zoom: 14.4746,
      );

  /* ── السعودية — الفعّالة ────────────────────────────────────────────── */

  static const Market saudiArabia = Market(
    id: 'SA',
    name: 'السعودية',
    placesCountries: 'SA',
    currency: 'ر.س',
    // المدينة المنوّرة — حيث الإطلاق، و«طيبة» اسمُها الذي عُرفت به.
    centreLat: 24.4686,
    centreLng: 39.6142,
    dialCode: '+966',
    phoneHint: '05XXXXXXXX',
    phoneLength: 10,
  );

  /* ── السودان — جاهزٌ ولا يظهر ───────────────────────────────────────── */

  static const Market sudan = Market(
    id: 'SD',
    name: 'السودان',
    placesCountries: 'SD',
    currency: 'ج.س',
    // الخرطوم.
    centreLat: 15.5007,
    centreLng: 32.5599,
    dialCode: '+249',
    phoneHint: '09XXXXXXXX',
    phoneLength: 10,
  );

  static const List<Market> all = <Market>[saudiArabia, sudan];
}

/// السوق المنتخَب عند البناء.
const String _marketId = String.fromEnvironment('MARKET', defaultValue: 'SA');

/// السوق الفعّال.
///
/// رمزٌ غير معروف يعود إلى السعودية بدل أن يُسقط التطبيق: خطأٌ في متغيّر بناء
/// لا يجوز أن يمنع الإقلاع، والخطأ يظهر في السلوك لا في شاشة سوداء.
final Market market = Market.all.firstWhere(
  (Market m) => m.id == _marketId,
  orElse: () => Market.saudiArabia,
);
