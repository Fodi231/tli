import 'package:flutter/foundation.dart';

/// Navigation state of the in-game phone.
class Shell extends ChangeNotifier {
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
