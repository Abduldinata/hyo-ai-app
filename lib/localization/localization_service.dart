import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();

  static LocalizationService get instance => _instance;

  LocalizationService._internal();

  String _currentLanguage = 'auto'; // 'auto', 'en', 'id'
  Locale? _systemLocale;

  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('app_language') ?? 'auto';
    } catch (_) {
      _currentLanguage = 'auto';
    }
  }

  void setSystemLocale(Locale locale) {
    _systemLocale = locale;
  }

  Future<void> setLanguage(String lang) async {
    // lang: 'auto', 'en', 'id'
    if (lang == _currentLanguage) return;

    _currentLanguage = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
    } catch (_) {}
  }

  String _getEffectiveLanguage() {
    if (_currentLanguage != 'auto') {
      return _currentLanguage; // User override
    }

    // Auto detect from system locale
    final locale = _systemLocale;
    if (locale != null) {
      final langCode = locale.languageCode.toLowerCase();
      if (langCode == 'id') return 'id';
      if (langCode == 'en') return 'en';
    }

    return 'en'; // Default fallback
  }

  String t(String key, {Map<String, dynamic>? args}) {
    final lang = _getEffectiveLanguage();
    final langMap = translations[lang] ?? translations['en']!;
    var value = langMap[key] ?? '[$key]';

    // Simple string interpolation
    if (args != null) {
      args.forEach((k, v) {
        value = value.replaceAll('\${$k}', v.toString());
      });
    }

    return value;
  }
}

// Global helper function
String t(String key, {Map<String, dynamic>? args}) {
  return LocalizationService.instance.t(key, args: args);
}
