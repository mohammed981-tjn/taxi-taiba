/// رمز العملة — من البناء لا من الشيفرة.
///
/// كان `₦` مكتوباً في خمسة مواضع: النايرا النيجيرية، عملة القالب الأصلي.
/// وهو الأخ الأوضح لـ`country:NG` — لا يفشل ولا يُنبَّه عليه، فقط يعرض على
/// راكب في الخرطوم سعراً بعملة بلدٍ آخر.
///
/// ورمزٌ يُكتب في خمسة أماكن يُنسى في أربعة. فهو هنا واحد:
///
///   --dart-define=CURRENCY=ج.س       السودان
///   --dart-define=CURRENCY=ر.س       السعودية
///
/// والافتراض `ج.س` مأخوذ من سياق المشروع لا من تصريح — كما في
/// `PLACES_COUNTRIES`. وحين تُبنى شاشة التسعير سيصير هذا حقلاً في القاعدة،
/// لأن العملة والسعر يتغيّران معاً ولا يصحّ أن يحتاج تغييرهما بناءً جديداً.
const String currencySymbol = String.fromEnvironment(
  'CURRENCY',
  defaultValue: 'ج.س',
);

/// مبلغ بعملته، بمسافة فاصلة.
String money(Object? amount) {
  final String text = '$amount'.trim();
  return text.isEmpty ? currencySymbol : '$currencySymbol $text';
}
