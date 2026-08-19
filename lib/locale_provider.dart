import 'package:flutter/material.dart';
import 'package:flutter_projects/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale';

  /// اللغات المدعومة.
  ///
  /// العربيّة **أوّلاً** لا الإنجليزيّة: حين لا يختار المستخدم شيئاً يُمرَّر
  /// `null` إلى `MaterialApp.locale`، فيقع الحلّ الافتراضي على أوّل عنصر هنا.
  /// وسوق هذا التطبيق المدينة المنوّرة.
  static const List<String> supportedLanguageCodes = <String>['ar', 'en'];

  /// `null` = لم يختر المستخدم بعد، فيتولّى النظام.
  ///
  /// كان `Locale('en')` مثبَّتاً: التطبيق يفتح بالإنجليزيّة على هاتفٍ عربيّ في
  /// السعوديّة، ويُنتظَر من الراكب أن يبحث عن مبدّل اللغة ليصلح ما لم يكسره.
  /// و`null` يجعل Flutter يوفّق لغة الجهاز مع المدعوم، فمن لغته عربيّة يجدها
  /// عربيّة، ومن لغته أردية — ولا نملكها بعد — يقع على العربيّة لا على
  /// الإنجليزيّة.
  Locale? _locale;

  /// ما يُمرَّر إلى `MaterialApp` — و`null` تعني «اترك الأمر للنظام».
  Locale? get localeOrNull => _locale;

  /// وما تقرؤه الشاشات التي تحتاج لغةً بعينها.
  Locale get locale => _locale ?? const Locale('ar');

  /// Loads the saved language (if any) when the app starts.
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);
    if (savedCode != null && supportedLanguageCodes.contains(savedCode)) {
      _locale = Locale(savedCode);
      placesLanguage = savedCode;
      notifyListeners();
    }
  }

  /// Sets the locale and persists the choice.
  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    if (_locale?.languageCode == locale.languageCode) return;

    _locale = locale;
    placesLanguage = locale.languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// يتنقّل بين اللغات المدعومة بالترتيب.
  ///
  /// كان تبديلاً ثنائياً مكتوباً بالاسم (`ar` ↔ `en`)، فلغةٌ ثالثة تُضاف إلى
  /// القائمة لا يصل إليها المستخدم بأيّ زرّ. والآن يدور على `supportedLanguageCodes`
  /// مهما طالت — وهو ما يجعل إضافة الأردية أو البنغالية تغييراً في سطر واحد.
  ///
  /// والدوران يبدأ من اللغة **الفعليّة** لا المخزَّنة: من لم يختر بعد ويرى
  /// عربيّةً بحكم لغة جهازه ينتقل إلى الإنجليزيّة، لا إلى العربيّة التي هو
  /// فيها.
  Future<void> toggleLocale() async {
    final int current = supportedLanguageCodes.indexOf(locale.languageCode);
    final int next = (current + 1) % supportedLanguageCodes.length;
    await setLocale(Locale(supportedLanguageCodes[next]));
  }
}
