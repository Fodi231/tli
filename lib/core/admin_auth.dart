import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'app_log.dart';

/// Password gate for the admin panel.
///
/// Only a salted SHA-256 hash is stored in the code, never the password itself.
/// To use your own password build with  --dart-define=ADMIN_HASH=<sha256 of "$_salt" + password>
/// (see README). Five wrong attempts lock the form for 60 seconds.
class AdminAuth {
  static const String _salt = 'TechLife|admin|v1|';
  static const String _defaultHash = '2e6ea9b95e67f23490b5f2a46dfbec32fb7264c2f0be47f3e51d7c8c9305fdaa';
  // An optional compile-time override is available for private custom builds.
  static const String _envHash = String.fromEnvironment('ADMIN_HASH');
  static String get _hash => _envHash.isEmpty ? _defaultHash : _envHash;

  static bool unlocked = false;
  static int _fails = 0;
  static DateTime? _lockUntil;

  static int get lockSeconds {
    final u = _lockUntil;
    if (u == null) return 0;
    final s = u.difference(DateTime.now()).inSeconds + 1;
    return s > 0 ? s : 0;
  }

  /// Returns true when the password is correct.
  static bool login(String password) {
    if (lockSeconds > 0) return false;
    final h = sha256.convert(utf8.encode('$_salt$password')).toString();
    if (h == _hash) {
      unlocked = true;
      _fails = 0;
      _lockUntil = null;
      AppLog.I.info('admin', 'вход в админ-панель выполнен');
      return true;
    }
    _fails++;
    AppLog.I.warn('admin', 'неверный пароль админ-панели (попытка $_fails)');
    if (_fails >= 5) {
      _fails = 0;
      _lockUntil = DateTime.now().add(const Duration(seconds: 60));
      AppLog.I.warn('admin', 'вход заблокирован на 60 секунд');
    }
    return false;
  }

  static void logout() {
    unlocked = false;
    AppLog.I.info('admin', 'выход из админ-панели');
  }
}
