import 'dart:io' show Platform;
import 'dart:ui' show Size, Color;

import 'package:window_manager/window_manager.dart';

import 'app_log.dart';

/// Controls the real OS window on Windows / Linux / macOS
/// (title, size, full screen). Everything is guarded so that a failure never
/// stops the game from starting.
class WinService {
  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static Future<void> init({required int w, required int h, required bool fullscreen, required String title}) async {
    if (!isDesktop) return;
    try {
      await windowManager.ensureInitialized();
      final opts = WindowOptions(
        size: Size(w.toDouble(), h.toDouble()),
        minimumSize: const Size(480, 640),
        center: true,
        title: title,
        backgroundColor: const Color(0xFF0A0F1E),
      );
      await windowManager.waitUntilReadyToShow(opts, () async {
        await windowManager.setTitle(title);
        await windowManager.show();
        await windowManager.focus();
        if (fullscreen) await windowManager.setFullScreen(true);
      });
    } catch (e) {
      AppLog.I.warn('window', 'не удалось настроить окно: $e');
    }
  }

  static Future<void> setFullscreen(bool v) async {
    if (!isDesktop) return;
    try {
      await windowManager.setFullScreen(v);
    } catch (e) {
      AppLog.I.warn('window', 'полный экран: $e');
    }
  }

  static Future<bool> isFullscreen() async {
    if (!isDesktop) return false;
    try {
      return await windowManager.isFullScreen();
    } catch (_) {
      return false;
    }
  }

  static Future<void> setSize(int w, int h) async {
    if (!isDesktop) return;
    try {
      if (await windowManager.isFullScreen()) await windowManager.setFullScreen(false);
      if (await windowManager.isMaximized()) await windowManager.unmaximize();
      await windowManager.setSize(Size(w.toDouble(), h.toDouble()));
      await windowManager.center();
    } catch (e) {
      AppLog.I.warn('window', 'размер окна: $e');
    }
  }

  static Future<void> maximize() async {
    if (!isDesktop) return;
    try {
      await windowManager.maximize();
    } catch (e) {
      AppLog.I.warn('window', 'развернуть окно: $e');
    }
  }

  static Future<Size> size() async {
    if (!isDesktop) return const Size(0, 0);
    try {
      return await windowManager.getSize();
    } catch (_) {
      return const Size(0, 0);
    }
  }
}
