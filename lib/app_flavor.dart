/// دور التطبيق — يُثبَّت عند الإقلاع ولا يتغيّر بعده.
///
/// **الحجّة الأمنية، وهي سبب وجود هذا الملف:**
///
/// مترجم Dart يُبقي في الحزمة كل شيفرة يمكن بلوغها سكونياً من `main()`،
/// بصرف النظر عن أي شرط وقت تشغيل. فلو استوردت شاشةٌ واحدة مشتركة شاشاتِ
/// الإدارة خلف `if (isAdmin)`، لشُحنت شيفرة الإدارة كاملةً داخل تطبيق كل
/// راكب — ولقرأها من فكّ الحزمة، ولعدّل الشرط من عدّلها.
///
/// فالفصل هنا على مستوى **ما يُشحن** لا **ما يُعرض**. والفرق بينهما هو الفرق
/// بين إخفاء زرّ وبين ألّا تكون الشيفرة على الجهاز أصلاً.
///
/// ولذلك لكل دور نقطة دخول مستقلّة، ولا تستورد أيٌّ منها شاشاتِ غيرها:
///
///   flutter build apk -t lib/main.dart        ← الراكب (الافتراضي)
///   flutter build apk -t lib/main_admin.dart  ← الإدارة
///
/// وهذا وحده لا يكفي. الحزمة تصل إلى يد من يريد تفكيكها، فمن يبني نسخة
/// الإدارة بنفسه يملك شاشاتها. ما يمنعه هو القاعدة: `auth.token.admin` راية
/// موقّعة من Firebase لا يزوّرها عميل، وكل ما تديره اللوحة مشروط بها في
/// `database.rules.json`. النكهة تمنع الشيفرة من الانتشار؛ القاعدة تمنع
/// الفعل. والثانية هي الحارس.
enum AppRole { passenger, driver, admin }

class AppFlavor {
  const AppFlavor._();

  static AppRole _role = AppRole.passenger;

  /// يُستدعى مرة واحدة في `main()` قبل `runApp`.
  static void configure(AppRole role) {
    _role = role;
  }

  static AppRole get role => _role;

  static bool get isPassenger => _role == AppRole.passenger;
  static bool get isDriver => _role == AppRole.driver;
  static bool get isAdmin => _role == AppRole.admin;
}
