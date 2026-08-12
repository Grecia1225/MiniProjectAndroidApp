import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppTheme {
  final String id;
  final String name;
  final String emoji;
  final Color primary;
  final Color background;
  final Color card;
  final Color cardLight;
  final String backgroundImage;

  const AppTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.background,
    required this.card,
    required this.cardLight,
    required this.backgroundImage,
  });

  static const List<AppTheme> themes = [
    AppTheme(
      id: 'navy_gold',
      name: 'Navy Gold',
      emoji: '⚓',
      primary: Color(0xFFF4A532),
      background: Color(0xFF0D1F35),
      card: Color(0xFF162D47),
      cardLight: Color(0xFF1E3A58),
      backgroundImage: 'assets/images/theme_navy_gold.jpg',
    ),
    AppTheme(
      id: 'midnight_cyan',
      name: 'Midnight Cyan',
      emoji: '🌊',
      primary: Color(0xFF00E5FF),
      background: Color(0xFF0A1A2E),
      card: Color(0xFF122540),
      cardLight: Color(0xFF1A3050),
      backgroundImage: 'assets/images/theme_midnight_cyan.jpg',
    ),
    AppTheme(
      id: 'ocean_green',
      name: 'Ocean Green',
      emoji: '🐚',
      primary: Color(0xFF00E676),
      background: Color(0xFF071A10),
      card: Color(0xFF0F2D1C),
      cardLight: Color(0xFF174028),
      backgroundImage: 'assets/images/theme_ocean_green.jpg',
    ),
    AppTheme(
      id: 'deep_blue',
      name: 'Deep Blue',
      emoji: '🔱',
      primary: Color(0xFF82B1FF),
      background: Color(0xFF08102A),
      card: Color(0xFF121E45),
      cardLight: Color(0xFF1A2860),
      backgroundImage: 'assets/images/theme_deep_blue.jpg',
    ),
    // Coral sunset — fixed to warm amber ocean horizon, not muddy brown
    AppTheme(
      id: 'coral_sunset',
      name: 'Coral Sunset',
      emoji: '🌅',
      primary: Color(0xFFFFAB40),       // warm amber — like the sun on water
      background: Color(0xFF1A1208),    // deep warm dusk, not red-brown
      card: Color(0xFF2C1F0E),          // dark amber wood
      cardLight: Color(0xFF3D2C14),
      backgroundImage: 'assets/images/theme_coral_sunset.jpg',
    ),
  ];

  static AppTheme fromId(String id) =>
      themes.firstWhere((t) => t.id == id, orElse: () => themes.first);
}

class ThemeProvider extends ChangeNotifier {
  AppTheme _current = AppTheme.themes.first;
  String _currentThemeId = 'navy_gold';

  AppTheme get current => _current;
  String get currentThemeId => _currentThemeId;

  void setTheme(String id) {
    _currentThemeId = id;
    _current = AppTheme.fromId(id);
    notifyListeners();
    _saveToFirestore(id);
  }

  // Sets theme locally without saving to Firestore
  // Used on login to load user's saved theme without triggering a write loop
  void setThemeLocal(String id) {
    if (_currentThemeId == id) return;
    _currentThemeId = id;
    _current = AppTheme.fromId(id);
    notifyListeners();
  }

  Future<void> loadThemeFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final themeId = doc.data()?['theme'] as String?;
      if (themeId != null && themeId.isNotEmpty) {
        _currentThemeId = themeId;
        _current = AppTheme.fromId(themeId);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToFirestore(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'theme': id}, SetOptions(merge: true));
    } catch (_) {}
  }
}