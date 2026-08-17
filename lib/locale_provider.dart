import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale';
  static const List<String> supportedLanguageCodes = ['en', 'ar'];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Loads the saved language (if any) when the app starts.
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);
    if (savedCode != null && supportedLanguageCodes.contains(savedCode)) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  /// Sets the locale and persists the choice.
  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    if (_locale.languageCode == locale.languageCode) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Quickly toggles between English and Arabic.
  Future<void> toggleLocale() async {
    final next = _locale.languageCode == 'ar' ? 'en' : 'ar';
    await setLocale(Locale(next));
  }
}
