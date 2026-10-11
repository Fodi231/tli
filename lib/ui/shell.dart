import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;

/// Navigation state of the in-game phone.
class Shell extends ChangeNotifier {
  /// Size of the in-game phone screen (set by PhoneScreen, used by the wallpaper editor).
  static Size phoneSize = const Size(9, 19.5);

  bool unlocked = false;
  String? app;
  Object? arg;

  void unlock() {
    unlocked = true;
    notifyListeners();
  }

  void open(String id, {Object? arg}) {
    unlocked = true;
    app = id;
    this.arg = arg;
    notifyListeners();
  }

  void close() {
    app = null;
    arg = null;
    notifyListeners();
  }
}
