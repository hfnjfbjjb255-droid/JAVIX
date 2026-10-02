import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JarvisLanguage {
  final String code;
  final String name;
  final String nativeName;
  final bool rtl;

  const JarvisLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    this.rtl = false,
  });
}

class LanguageService extends ChangeNotifier {
  static const _prefKey = 'jarvis_language';

  static const languages = <JarvisLanguage>[
    JarvisLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', rtl: true),
    JarvisLanguage(code: 'en', name: 'English', nativeName: 'English'),
    JarvisLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
    JarvisLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
    JarvisLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
    JarvisLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano'),
    JarvisLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    JarvisLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
    JarvisLanguage(code: 'fa', name: 'Persian', nativeName: 'فارسی', rtl: true),
    JarvisLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو', rtl: true),
    JarvisLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    JarvisLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
    JarvisLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
    JarvisLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    JarvisLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
    JarvisLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    JarvisLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
    JarvisLanguage(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
    JarvisLanguage(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
    JarvisLanguage(code: 'th', name: 'Thai', nativeName: 'ไทย'),
  ];

  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  JarvisLanguage get currentLanguage =>
      languages.firstWhere(
        (item) => item.code == _locale.languageCode,
        orElse: () => languages.first,
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code == null || !languages.any((item) => item.code == code)) return;
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!languages.any((item) => item.code == code)) return;
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    notifyListeners();
  }

  static bool isRtl(String code) =>
      languages.any((item) => item.code == code && item.rtl);
}
