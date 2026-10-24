/// Local simulation of the repaired device. Never changes the host's radios.
enum DevicePower { on, asleep, shuttingDown, off, booting }

enum DevicePage {
  lock,
  home,
  controls,
  power,
  settings,
  camera,
  photos,
  calculator,
  notes,
  clock,
  browser,
  dialer,
  diagnostics,
}

class DeviceRuntime {
  DevicePower power = DevicePower.on;
  DevicePage page = DevicePage.lock;
  bool wifi = true, cellular = true, bluetooth = false, airplane = false;
  bool _cellularBeforeFlight = true;
  bool flashlight = false, silent = false;
  bool restartQueued = false;
  double volume = .5, brightness = .75;
  int battery = 76, foldStage = 0, elapsedMs = 0, photos = 0;
  String note = '', dialed = '', calculator = '0';
  int stopwatchMs = 0;
  bool stopwatchRunning = false;
  int? _backgroundAt;
  bool get inBackground => _backgroundAt != null;

  void enterBackground({DateTime? now}) {
    pressed.clear();
    _backgroundAt = (now ?? DateTime.now()).millisecondsSinceEpoch;
  }

  void resume({
    required bool apple,
    required int bootMs,
    bool batteryConnected = true,
    DateTime? now,
  }) {
    final start = _backgroundAt;
    _backgroundAt = null;
    if (start == null) return;
    final gap = ((now ?? DateTime.now()).millisecondsSinceEpoch - start).clamp(
      0,
      86400000,
    );
    advance(
      gap,
      apple: apple,
      bootMs: bootMs,
      batteryConnected: batteryConnected,
    );
  }

  final Set<String> pressed = {};
  int _buttonHeldMs = 0;
  bool _holdHandled = false;
  bool get lit => power == DevicePower.on;
  bool get transitioning =>
      power == DevicePower.booting || power == DevicePower.shuttingDown;
  bool get network => wifi || (cellular && !airplane);

  void setAirplane(bool value) {
    if (value == airplane) return;
    airplane = value;
    if (value) {
      _cellularBeforeFlight = cellular;
      cellular = false;
    } else {
      cellular = _cellularBeforeFlight;
    }
  }

  void setCellular(bool value) {
    if (!airplane) cellular = value;
  }

  void open(DevicePage value) {
    if (lit) page = value;
  }

  void unlock() {
    if (lit) page = DevicePage.home;
  }

  void setFold(int stage, int panels) => foldStage = stage.clamp(0, panels - 1);
  void press(String button) {
    pressed.add(button);
    _buttonHeldMs = 0;
    _holdHandled = false;
    if (button == 'up' || button == 'down') {
      volume = (volume + (button == 'up' ? .0625 : -.0625)).clamp(0, 1);
    }
  }

  void release(String button) {
    final wasHeld = _holdHandled;
    final wasChord = pressed.length > 1;
    pressed.remove(button);
    if (button == 'side' && !wasHeld && !wasChord && _buttonHeldMs < 650) {
      if (power == DevicePower.on) {
        power = DevicePower.asleep;
        page = DevicePage.lock;
      } else if (power == DevicePower.asleep) {
        power = DevicePower.on;
        page = DevicePage.lock;
      }
    }
    if (pressed.isEmpty) {
      _buttonHeldMs = 0;
      _holdHandled = false;
    }
  }

  void powerMenu() {
    if (!lit) return;
    page = DevicePage.power;
  }

  void shutDown() {
    if (!lit) return;
    power = DevicePower.shuttingDown;
    elapsedMs = 0;
    page = DevicePage.lock;
    flashlight = false;
  }

  void restart() {
    if (!lit) return;
    restartQueued = true;
    shutDown();
  }

  void boot({bool batteryConnected = true}) {
    if (!batteryConnected || battery <= 0 || power != DevicePower.off) return;
    power = DevicePower.booting;
    elapsedMs = 0;
    page = DevicePage.lock;
  }

  void disconnectBattery() {
    power = DevicePower.off;
    elapsedMs = 0;
    restartQueued = false;
    pressed.clear();
  }

  /// Returns true when a power transition finishes.
  bool advance(
    int ms, {
    required bool apple,
    required int bootMs,
    bool batteryConnected = true,
  }) {
    if (!batteryConnected) {
      final changed = power != DevicePower.off;
      disconnectBattery();
      return changed;
    }
    if (stopwatchRunning && lit) stopwatchMs += ms;
    if (pressed.isNotEmpty) {
      _buttonHeldMs += ms;
      if (!_holdHandled && _buttonHeldMs >= 850 && pressed.contains('side')) {
        if (power == DevicePower.off) {
          boot();
          _holdHandled = true;
        } else if (lit &&
            (!apple || pressed.contains('up') || pressed.contains('down'))) {
          powerMenu();
          _holdHandled = true;
        }
      }
    }
    if (!transitioning) return false;
    elapsedMs += ms;
    if (power == DevicePower.shuttingDown && elapsedMs >= 2200) {
      final remaining = elapsedMs - 2200;
      power = restartQueued ? DevicePower.booting : DevicePower.off;
      restartQueued = false;
      elapsedMs = 0;
      if (power == DevicePower.booting && remaining > 0) {
        advance(
          remaining,
          apple: apple,
          bootMs: bootMs,
          batteryConnected: batteryConnected,
        );
      }
      return true;
    }
    if (power == DevicePower.booting && elapsedMs >= bootMs) {
      power = DevicePower.on;
      page = DevicePage.lock;
      elapsedMs = 0;
      return true;
    }
    return false;
  }

  void calcKey(String key) {
    if (key == 'AC') {
      calculator = '0';
      return;
    }
    if (key == '⌫') {
      calculator =
          calculator.length > 1
              ? calculator.substring(0, calculator.length - 1)
              : '0';
      return;
    }
    if (key == '=') {
      final match = RegExp(
        r'^(-?\d+(?:\.\d+)?)([+−×÷])(-?\d+(?:\.\d+)?)$',
      ).firstMatch(calculator);
      if (match == null) return;
      final a = double.parse(match[1]!), b = double.parse(match[3]!);
      if (match[2] == '÷' && b == 0) {
        calculator = 'Error';
        return;
      }
      final n = switch (match[2]) {
        '+' => a + b,
        '−' => a - b,
        '×' => a * b,
        _ => a / b,
      };
      calculator =
          n == n.truncateToDouble()
              ? n.toInt().toString()
              : n.toStringAsPrecision(8).replaceFirst(RegExp(r'0+$'), '');
      return;
    }
    if (calculator == 'Error') calculator = '0';
    if (calculator.length > 24) return;
    if (['+', '−', '×', '÷'].contains(key)) {
      if (calculator.endsWith('+') ||
          calculator.endsWith('−') ||
          calculator.endsWith('×') ||
          calculator.endsWith('÷')) {
        calculator = calculator.substring(0, calculator.length - 1) + key;
      } else if (!RegExp(r'[+−×÷]').hasMatch(calculator.substring(1))) {
        calculator += key;
      }
    } else if (RegExp(r'^[0-9.]$').hasMatch(key)) {
      final operand = calculator.split(RegExp(r'[+−×÷]')).last;
      if (key == '.' && operand.contains('.')) return;
      calculator = calculator == '0' && key != '.' ? key : calculator + key;
    }
  }

  Map<String, dynamic> toJson() => {
    'clock': _backgroundAt ?? DateTime.now().millisecondsSinceEpoch,
    'power': power.name,
    'restart': restartQueued,
    'page': page.name,
    'wifi': wifi,
    'cellular': cellular,
    'bluetooth': bluetooth,
    'airplane': airplane,
    'cellBefore': _cellularBeforeFlight,
    'flashlight': flashlight,
    'silent': silent,
    'volume': volume,
    'brightness': brightness,
    'battery': battery,
    'fold': foldStage,
    'elapsed': elapsedMs,
    'photos': photos,
    'note': note,
    'dialed': dialed,
    'calc': calculator,
    'stopwatch': stopwatchMs,
  };
  void load(Map<String, dynamic>? j, {required int panels}) {
    if (j == null) return;
    _backgroundAt = j['clock'] is int ? j['clock'] as int : null;
    power = DevicePower.values.firstWhere(
      (v) => v.name == j['power'],
      orElse: () => DevicePower.on,
    );
    restartQueued = j['restart'] == true;
    page = DevicePage.values.firstWhere(
      (v) => v.name == j['page'],
      orElse: () => DevicePage.lock,
    );
    wifi = j['wifi'] != false;
    cellular = j['cellular'] != false;
    bluetooth = j['bluetooth'] == true;
    airplane = j['airplane'] == true;
    _cellularBeforeFlight = j['cellBefore'] != false;
    if (airplane) cellular = false;
    flashlight = j['flashlight'] == true;
    silent = j['silent'] == true;
    volume = (j['volume'] as num? ?? .5).toDouble().clamp(0, 1);
    brightness = (j['brightness'] as num? ?? .75).toDouble().clamp(0, 1);
    battery = (j['battery'] as num? ?? 76).toInt().clamp(0, 100);
    foldStage = (j['fold'] as num? ?? 0).toInt().clamp(0, panels - 1);
    elapsedMs = (j['elapsed'] as num? ?? 0).toInt().clamp(0, 60000);
    photos = (j['photos'] as num? ?? 0).toInt().clamp(0, 100);
    note = (j['note'] as String? ?? '').substring(
      0,
      (j['note'] as String? ?? '').length.clamp(0, 4000),
    );
    dialed = j['dialed'] as String? ?? '';
    calculator = j['calc'] as String? ?? '0';
    stopwatchMs = (j['stopwatch'] as num? ?? 0).toInt().clamp(0, 86400000);
  }
}
