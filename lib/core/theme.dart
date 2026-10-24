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

class IosColors {
  final bool dark;
  const IosColors(this.dark);
  factory IosColors.of(BuildContext context) =>
      IosColors(Theme.of(context).brightness == Brightness.dark);
  Color get background =>
      dark ? const Color(0xFF101114) : const Color(0xFFF2F2F7);
  Color get surface => dark ? const Color(0xFF202126) : Colors.white;
  Color get inset => dark ? const Color(0xFF2C2D33) : const Color(0xFFE9E9EF);
  Color get label => dark ? const Color(0xFFF5F5F7) : const Color(0xFF17181D);
  Color get secondary =>
      dark ? const Color(0xFFACADB7) : const Color(0xFF686A76);
  Color get separator =>
      dark ? const Color(0xFF37383F) : const Color(0xFFDEDEE7);
  Color get blue => dark ? const Color(0xFF5CA6FF) : const Color(0xFF0066DB);
  Color get green => dark ? const Color(0xFF5AD88D) : const Color(0xFF168348);
}

ThemeData buildTheme([Brightness brightness = Brightness.dark]) {
  final p = IosColors(brightness == Brightness.dark);
  final base = ThemeData(
    brightness: brightness,
    platform: TargetPlatform.iOS,
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.accent,
      brightness: brightness,
      primary: p.blue,
      surface: p.surface,
      onSurface: p.label,
    ),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: p.label, displayColor: p.label),
    dividerColor: p.separator,
    iconTheme: IconThemeData(color: p.blue),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.inset,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: p.secondary),
      prefixIconColor: p.secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.blue, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 46),
        shape: shape,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.blue,
        minimumSize: const Size(44, 44),
        side: BorderSide(color: p.separator),
        shape: shape,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface,
      contentTextStyle: TextStyle(color: p.label, fontFamily: 'Roboto'),
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.blue,
      linearTrackColor: p.inset,
      borderRadius: BorderRadius.circular(10),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected)
                ? const Color(0xFF34C759)
                : p.inset,
      ),
    ),
  );
}

/// Invert + hue-rotate(180): turns the dark UI into a light one without
/// touching any widget colours (used for the light theme).
const ColorFilter lightModeFilter = ColorFilter.matrix(<double>[
  0.574,
  -1.430,
  -0.144,
  0,
  255,
  -0.426,
  -0.430,
  -0.144,
  0,
  255,
  -0.426,
  -1.430,
  0.856,
  0,
  255,
  0,
  0,
  0,
  1,
  0,
]);

/// 0 = follow the device, 1 = light, 2 = dark.
bool isLightMode(int mode, Brightness platform) =>
    mode == 1 || (mode == 0 && platform == Brightness.light);

/// Applies [lightModeFilter] when [light] is true. Wrapping something that is
/// already inside a filtered area cancels the filter again (it is its own
/// inverse), which is used for wallpaper previews.
class ThemeFilter extends StatelessWidget {
  final bool light;
  final Widget child;
  const ThemeFilter({super.key, required this.light, required this.child});

  @override
  Widget build(BuildContext context) =>
      light ? ColorFiltered(colorFilter: lightModeFilter, child: child) : child;
}
