import 'package:flutter/material.dart';
import 'package:flutter_projects/app_flavor.dart';

/// هوية طيبة — لوحة واحدة بثلاثة وجوه.
///
/// **المبدأ:** التطبيقات الثلاثة منظومة واحدة لا ثلاثة منتجات. فما يجمعها
/// أكثر مما يفرّقها: نفس الخطّ، ونفس الاستدارات، ونفس المسافات، ونفس اللون
/// الثانوي الكهرماني. والذي يفرّقها لونٌ أساسي واحد لكلٍّ — يكفي أن يعرف
/// المستخدم في أيّ تطبيق هو من نظرة، ولا يزيد فيبدو كأنها من جهات مختلفة.
///
/// واختيار الألوان ليس ذوقاً محضاً:
///
///   الراكب  كحلي   — الثقة والليل، ولون سيارات الأجرة في أكثر المدن
///   السائق  زمردي  — «متصل» و«ابدأ»، وهو الفعل الأكثر تكراراً في يومه
///   الإدارة بنفسجي — بعيدٌ عن الاثنين عمداً: لوحة تُدار منها الأموال يجب
///                    ألّا تُشبه شاشةً يفتحها راكب بالخطأ
///
/// والكهرماني مشترك: لون الأجرة والتقييم والنجوم في الثلاثة، فيقرأ المستخدم
/// «هذا رقم يخصّ المال» قبل أن يقرأ الرقم.
class TibaBrand {
  const TibaBrand._();

  /// الاسم كما يُكتب — لاتينيّاً وعربيّاً.
  static const String nameLatin = 'Tiba';
  static const String nameArabic = 'طيبة';

  /// ما يُعرض تحت الاسم في شاشات الدخول.
  static String taglineFor(AppRole role) {
    switch (role) {
      case AppRole.passenger:
        return 'رحلتك تبدأ من هنا';
      case AppRole.driver:
        return 'اتصل، واستقبل رحلاتك';
      case AppRole.admin:
        return 'لوحة التحكّم';
    }
  }

  static String suffixFor(AppRole role) {
    switch (role) {
      case AppRole.passenger:
        return '';
      case AppRole.driver:
        return 'سائق';
      case AppRole.admin:
        return 'إدارة';
    }
  }
}

/// ألوان النكهة الواحدة.
class TibaPalette {
  const TibaPalette({
    required this.primary,
    required this.primaryDeep,
    required this.accent,
  });

  final Color primary;

  /// أغمق درجةً — للتدرّجات وأشرطة الحالة، لا لأي نصّ.
  final Color primaryDeep;

  /// الكهرماني المشترك.
  final Color accent;

  static const TibaPalette passenger = TibaPalette(
    primary: Color(0xFF0D1B4C),
    primaryDeep: Color(0xFF060E2C),
    accent: Color(0xFFF5A524),
  );

  static const TibaPalette driver = TibaPalette(
    primary: Color(0xFF0E7C5A),
    primaryDeep: Color(0xFF064434),
    accent: Color(0xFFF5A524),
  );

  static const TibaPalette admin = TibaPalette(
    primary: Color(0xFF5B3E96),
    primaryDeep: Color(0xFF33215C),
    accent: Color(0xFFF5A524),
  );

  static TibaPalette of(AppRole role) {
    switch (role) {
      case AppRole.passenger:
        return passenger;
      case AppRole.driver:
        return driver;
      case AppRole.admin:
        return admin;
    }
  }
}

class TibaTheme {
  const TibaTheme._();

  /// الاستدارة ثابتة عبر التطبيقات الثلاثة: أزرار وبطاقات وحقول بنفس اللغة.
  static const double radius = 14;

  static ThemeData of(AppRole role) {
    final TibaPalette palette = TibaPalette.of(role);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
    ).copyWith(
      // البذرة تولّد تناغماً، لكنها تُزيح اللون الأساسي عن قيمته المختارة.
      // تثبيته هنا يُبقي الهوية كما قُصدت ويترك الباقي للتوليد.
      primary: palette.primary,
      secondary: palette.accent,
      surface: const Color(0xFFFAFAFC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          // حدٌّ رفيع بدل ظلّ: الظلال تتكدّس في القوائم الطويلة وتُتعب العين،
          // والحدّ يفصل بنفس الوضوح وبلا ضجيج.
          side: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.primary, width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: palette.primary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.primary),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: palette.primary.withValues(alpha: 0.12),
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.07),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
