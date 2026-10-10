import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF0A0F1E);
  static const card = Color(0xFF131A2D);
  static const card2 = Color(0xFF1B2440);
  static const accent = Color(0xFF3B82F6);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const text = Color(0xFFE8ECF8);
  static const sub = Color(0xFF8B96B5);
}

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(primary: C.accent, surface: C.card),
      snackBarTheme: const SnackBarThemeData(backgroundColor: C.card2),
    );
