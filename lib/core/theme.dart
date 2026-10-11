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

/// Invert + hue-rotate(180): turns the dark UI into a light one without
/// touching any widget colours (used for the light theme).
const ColorFilter lightModeFilter = ColorFilter.matrix(<double>[
  0.574, -1.430, -0.144, 0, 255,
  -0.426, -0.430, -0.144, 0, 255,
  -0.426, -1.430, 0.856, 0, 255,
  0, 0, 0, 1, 0,
]);

/// 0 = follow the device, 1 = light, 2 = dark.
bool isLightMode(int mode, Brightness platform) => mode == 1 || (mode == 0 && platform == Brightness.light);

/// Applies [lightModeFilter] when [light] is true. Wrapping something that is
/// already inside a filtered area cancels the filter again (it is its own
/// inverse), which is used for wallpaper previews.
class ThemeFilter extends StatelessWidget {
  final bool light;
  final Widget child;
  const ThemeFilter({super.key, required this.light, required this.child});

  @override
  Widget build(BuildContext context) => light ? ColorFiltered(colorFilter: lightModeFilter, child: child) : child;
}
