import 'dart:ui' show Size;

/// Web / mobile: there is no desktop window to control.
class WinService {
  static bool get isDesktop => false;
  static Future<void> init({required int w, required int h, required bool fullscreen, required String title}) async {}
  static Future<void> setFullscreen(bool v) async {}
  static Future<bool> isFullscreen() async => false;
  static Future<void> setSize(int w, int h) async {}
  static Future<void> maximize() async {}
  static Future<Size> size() async => const Size(0, 0);
}
