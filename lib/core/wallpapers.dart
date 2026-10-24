import 'package:flutter/material.dart';

const bundledWallpapers = <String, String>{
  'assets/wallpapers/peach.jpg': 'wp_peach_glass',
  'assets/wallpapers/blue.jpg': 'wp_blue_glass',
  'assets/wallpapers/teal.jpg': 'wp_teal_glass',
  'assets/wallpapers/lavender.jpg': 'wp_lavender_glass',
};

/// Gradient wallpaper presets (4 colours each, top to bottom).
const wallpaperPresets = <List<Color>>[
  [Color(0xFF050B1E), Color(0xFF0B3B4A), Color(0xFF0A1530), Color(0xFF070C1A)],
  [Color(0xFF1B1035), Color(0xFF7A2E6E), Color(0xFFE2724F), Color(0xFF2A1033)],
  [Color(0xFF03162B), Color(0xFF0B5C8A), Color(0xFF0A2A4F), Color(0xFF03101F)],
  [Color(0xFF04140D), Color(0xFF14532D), Color(0xFF0B2E1B), Color(0xFF03100A)],
  [Color(0xFF110A2B), Color(0xFF4C2A9A), Color(0xFF241257), Color(0xFF0B0620)],
  [Color(0xFF0B0B0F), Color(0xFF2A2D36), Color(0xFF15161B), Color(0xFF08080B)],
  [Color(0xFF2B0B1B), Color(0xFFB03A6C), Color(0xFF5A1740), Color(0xFF1B0711)],
  [Color(0xFF000000), Color(0xFF0A0F2C), Color(0xFF050818), Color(0xFF000000)],
];

const wallpaperKeys = [
  'wp_aurora',
  'wp_sunset',
  'wp_ocean',
  'wp_forest',
  'wp_violet',
  'wp_graphite',
  'wp_rose',
  'wp_midnight',
];
