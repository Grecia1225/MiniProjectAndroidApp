import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English',  'native': 'English',  'flag': '🇬🇧', 'tts': 'en-IN'},
    {'code': 'hi', 'name': 'Hindi',    'native': 'हिन्दी',    'flag': '🇮🇳', 'tts': 'hi-IN'},
    {'code': 'ta', 'name': 'Tamil',    'native': 'தமிழ்',     'flag': '🇮🇳', 'tts': 'ta-IN'},
    {'code': 'te', 'name': 'Telugu',   'native': 'తెలుగు',    'flag': '🇮🇳', 'tts': 'te-IN'},
    {'code': 'ar', 'name': 'Arabic',   'native': 'العربية',   'flag': '🇦🇪', 'tts': 'ar-SA'},
    {'code': 'fr', 'name': 'French',   'native': 'Français',  'flag': '🇫🇷', 'tts': 'fr-FR'},
  ];

  // Updates the locale locally only — no Firestore write.
  // Use this on app startup when restoring a previously saved language.
  void setLanguageLocal(String code) {
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
  }

  // Updates the locale AND persists it to Firestore.
  // Use this when the user manually picks a language (e.g. in Settings).
  void setLanguage(String code) {
    setLanguageLocal(code);
    _save(code);
  }

  Future<void> loadFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .get(const GetOptions(source: Source.cache));
      final code = (doc.data() ?? {})['language'] as String?;
      if (code != null && code.isNotEmpty && code != _locale.languageCode) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        final doc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).get();
        final code = (doc.data() ?? {})['language'] as String?;
        if (code != null && code.isNotEmpty && code != _locale.languageCode) {
          _locale = Locale(code);
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> _save(String code) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .set({'language': code}, SetOptions(merge: true));
    } catch (_) {}
  }

  String get currentLanguageName => supportedLanguages
      .firstWhere((l) => l['code'] == _locale.languageCode,
      orElse: () => supportedLanguages[0])['name'] ?? 'English';

  String get currentFlag => supportedLanguages
      .firstWhere((l) => l['code'] == _locale.languageCode,
      orElse: () => supportedLanguages[0])['flag'] ?? '🇬🇧';

  String get ttsLocale => supportedLanguages
      .firstWhere((l) => l['code'] == _locale.languageCode,
      orElse: () => supportedLanguages[0])['tts'] ?? 'en-IN';

  bool get isRTL => _locale.languageCode == 'ar';
}