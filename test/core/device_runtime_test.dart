import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/repair/device_runtime.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/core/market/device_catalog.dart';
import 'repair_session_test.dart' show performStep, advanceTo;

void main() {
  test('Apple power chord, shutdown and boot have distinct timed states', () {
    final r = DeviceRuntime();
    r.press('side');
    r.advance(1000, apple: true, bootMs: 12000);
    r.release('side');
    expect(r.page, DevicePage.lock);
    r.press('up');
    r.press('side');
    r.advance(900, apple: true, bootMs: 12000);
    expect(r.page, DevicePage.power);
    r.release('up');
    r.release('side');
    r.shutDown();
    expect(r.power, DevicePower.shuttingDown);
    r.advance(2100, apple: true, bootMs: 12000);
    expect(r.power, DevicePower.shuttingDown);
    r.advance(100, apple: true, bootMs: 12000);
    expect(r.power, DevicePower.off);
    r.boot();
    r.advance(11900, apple: true, bootMs: 12000);
    expect(r.power, DevicePower.booting);
    r.advance(100, apple: true, bootMs: 12000);
    expect(r.power, DevicePower.on);
  });
  test(
    'airplane, disconnected battery, calculator and preferences survive reload',
    () {
      final r =
          DeviceRuntime()
            ..wifi = false
            ..cellular = true
            ..note = 'Проверить камеру';
      r.setAirplane(true);
      expect(r.cellular, false);
      r.setCellular(true);
      expect(r.cellular, false);
      r.setAirplane(false);
      expect(r.cellular, true);
      for (final k in ['8', '÷', '2', '=']) {
        r.calcKey(k);
      }
      expect(r.calculator, '4');
      r.disconnectBattery();
      r.boot(batteryConnected: false);
      expect(r.power, DevicePower.off);
      final loaded = DeviceRuntime()..load(r.toJson(), panels: 3);
      expect(loaded.wifi, false);
      expect(loaded.note, r.note);
      expect(loaded.calculator, '4');
      loaded.boot();
      loaded.advance(5000, apple: false, bootMs: 14000);
      final interrupted = DeviceRuntime()..load(loaded.toJson(), panels: 3);
      interrupted.advance(9000, apple: false, bootMs: 14000);
      expect(interrupted.power, DevicePower.on);
    },
  );
  test('repair refuses fake shutdown and final tests on an unbooted phone', () {
    final s = RepairSession('test', 'display');
    performStep(s);
    s.tool = RepairTool.hand;
    expect(
      s.act('power', RepairGesture.hold, heldMs: 1200).message,
      'r_use_shutdown',
    );
    performStep(s);
    advanceTo(s, 'test');
    s.tool = RepairTool.meter;
    expect(
      s.act('test_screen', RepairGesture.hold, heldMs: 1200).message,
      'r_use_boot',
    );
    performStep(s);
    expect(s.finished, true);
  });
  test('every battery of a foldable must be disconnected and replaced', () {
    for (final model in deviceCatalog.where((d) => d.panels > 1)) {
      final s = RepairSession(model.id, 'battery', device: model.id);
      advanceTo(s, 'battery_off');
      expect(s.current!.targets.length, model.panels == 3 ? 3 : 2);
      s.tool = RepairTool.spudger;
      s.act(s.current!.targets.first, RepairGesture.tap);
      expect(s.batteryDisconnected, isTrue);
      performStep(s);
      expect(s.powered, false);
      advanceTo(s, 'part_out');
      expect(s.current!.targets.length, model.panels == 3 ? 3 : 2);
      performStep(s);
      expect(s.partRemoved, true);
      while (!s.finished) {
        performStep(s);
      }
      expect(s.mistakes, 0);
    }
  });
  test(
    'v2 current step migrates by id when new opening stages are inserted',
    () {
      final s = RepairSession('legacy', 'camera');
      advanceTo(s, 'battery_off');
      final j =
          s.toJson()
            ..['v'] = 2
            ..['index'] = 7
            ..remove('runtime');
      final restored = RepairSession.fromJson(j);
      expect(restored.current!.id, 'battery_off');
      expect(restored.runtime.power, DevicePower.off);
    },
  );
}
