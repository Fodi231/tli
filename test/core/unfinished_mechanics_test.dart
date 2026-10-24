import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/models.dart';
import 'repair_economy_test.dart' show finishStep;
import 'package:techlife/core/repair/device_runtime.dart';
import 'package:techlife/core/repair/repair_session.dart';

import 'repair_session_test.dart' show advanceTo;

void main() {
  test(
    'tri-fold replacement consumes one kit across save and individual cell installation',
    () {
      final gs = GameState();
      final o = Order(
        id: 'tri-kit',
        device: 'HUAWEI Mate XT',
        service: 'battery',
        price: 300,
        lat: 0,
        lng: 0,
        status: 'active',
      );
      gs.orders.add(o);
      gs.parts['battery'] = 1;
      final s = gs.startWorkbench(o.id)!;
      while (s.current?.id != 'part_in') {
        finishStep(gs, o.id);
      }
      finishStep(gs, o.id);
      expect(gs.parts['battery'], 0);
      expect(s.newPartInstalled, isFalse);
      expect(s.current?.id, 'aux_in_0');
      gs.repairs[o.id] = RepairSession.fromJson(s.toJson());
      while (!gs.repairs[o.id]!.finished) {
        finishStep(gs, o.id);
      }
      expect(gs.parts['battery'], 0);
      expect(gs.repairs[o.id]!.newPartInstalled, isTrue);
      gs.dispose();
    },
  );
  test(
    'background boot finishes on the bench without reopening inspection',
    () {
      final gs = GameState();
      final s = gs.startWorkbench(RepairSession.practiceId)!;
      s.runtime.disconnectBattery();
      s.runtime.boot();
      final time = DateTime.utc(2026, 10, 24);
      s.runtime.enterBackground(now: time);
      gs.advanceRepairClocks(now: time.add(const Duration(seconds: 20)));
      expect(s.runtime.power, DevicePower.on);
      gs.dispose();
    },
  );
  test('completed v3 repairs remain completed after new cell steps', () {
    final s = RepairSession('old', 'battery', device: 'matext');
    final j =
        s.toJson()
          ..['v'] = 3
          ..['step'] = null
          ..['index'] = s.steps.length - 2;
    expect(RepairSession.fromJson(j).finished, isTrue);
  });
  test('boot catches up while inspector is closed', () {
    final r = DeviceRuntime()..disconnectBattery();
    r.boot();
    r.advance(3000, apple: true, bootMs: 12000);
    final time = DateTime.utc(2026, 10, 24);
    r.enterBackground(now: time);
    r.resume(
      apple: true,
      bootMs: 12000,
      now: time.add(const Duration(seconds: 10)),
    );
    expect(r.power, DevicePower.on);
  });
  test('one catch-up covers shutdown and restart', () {
    final r = DeviceRuntime()..restart();
    r.advance(20000, apple: false, bootMs: 11000);
    expect(r.power, DevicePower.on);
  });
  test('heat requires a valid temperature and penalizes overheating', () {
    final s = RepairSession('heat', 'battery');
    advanceTo(s, 'heat');
    s.tool = RepairTool.heater;
    expect(
      s.act('screen', RepairGesture.hold, heldMs: 1200).message,
      'r_too_cold',
    );
    expect(
      s.act('screen', RepairGesture.hold, heldMs: 12000).message,
      'r_overheated',
    );
    expect(s.mistakes, 1);
    expect(s.act('screen', RepairGesture.hold, heldMs: 6500).accepted, isTrue);
  });
  test('battery connector graphics follow each individual action', () {
    final s = RepairSession('connectors', 'battery', device: 'matext');
    advanceTo(s, 'battery_off');
    s.tool = RepairTool.spudger;
    s.act('battery_connector', RepairGesture.tap);
    expect(s.connectorDisconnected('battery_connector'), isTrue);
    expect(s.connectorDisconnected('aux_battery_connector_0'), isFalse);
    expect(s.batteryDisconnected, isTrue);
  });
}
