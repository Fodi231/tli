import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogEntry {
  final DateTime time;
  final String level, source, message;
  LogEntry(this.level, this.source, this.message, [DateTime? t]) : time = t ?? DateTime.now();

  Map<String, dynamic> toJson() => {'t': time.millisecondsSinceEpoch, 'l': level, 's': source, 'm': message};
  factory LogEntry.fromJson(Map<String, dynamic> j) =>
      LogEntry(j['l'] as String, j['s'] as String, j['m'] as String, DateTime.fromMillisecondsSinceEpoch(j['t'] as int));

  @override
  String toString() => '${time.toIso8601String()} [$level/$source] $message';
}

/// In-app error / event log shown in the admin panel. Newest entries first.
class AppLog extends ChangeNotifier {
  static final AppLog I = AppLog._();
  AppLog._();

  final List<LogEntry> entries = [];
  SharedPreferences? _prefs;
  Timer? _saveTimer;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    try {
      for (final s in prefs.getStringList('applog') ?? <String>[]) {
        entries.add(LogEntry.fromJson(jsonDecode(s) as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  void add(String level, String source, String message) {
    var m = message;
    if (m.length > 600) m = '${m.substring(0, 600)}…';
    entries.insert(0, LogEntry(level, source, m));
    if (entries.length > 300) entries.removeRange(300, entries.length);
    debugPrint('[$level/$source] $m');
    _scheduleSave();
    Future.microtask(notifyListeners);
  }

  void info(String source, String msg) => add('info', source, msg);
  void warn(String source, String msg) => add('warn', source, msg);
  void error(String source, String msg) => add('error', source, msg);

  void clear() {
    entries.clear();
    _scheduleSave();
    notifyListeners();
  }

  String dump() => entries.reversed.map((e) => e.toString()).join('\n');

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final p = _prefs;
      if (p == null) return;
      p.setStringList('applog', entries.take(120).map((e) => jsonEncode(e.toJson())).toList());
    });
  }
}
