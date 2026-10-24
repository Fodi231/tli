import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/market/device_catalog.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/core/repair/device_profile.dart';
import 'repair_session_test.dart' show performStep, advanceTo;

void main() {
  test('MagSafe capability is not inferred from a Qi coil, brand or case', () {
    const magnetic = {'iphone12', 'iphone13', 'iphone15pro', 'iphoneduo'};
    for (final d in deviceCatalog) {
      expect(d.magSafe, magnetic.contains(d.id), reason: d.id);
      expect(d.wirelessCharging, true);
    }
    expect(deviceFor('iphone11')!.magSafe, false);
    expect(deviceFor('matext')!.magSafe, false);
  });
  for (final d in deviceCatalog) {
    test('${d.id} switching off does not flip the phone', () {
      final s = RepairSession('s', 'display', device: d.id);
      expect(s.rearSideUp, false);
      advanceTo(s, 'power_off');
      performStep(s);
      expect(s.powered, false);
      expect(s.rearSideUp, false);
      if (profileFor(d.id).rearAccess) {
        expect(s.current!.id, 'flip_rear');
        performStep(s);
        expect(s.rearSideUp, true);
        advanceTo(s, 'flip_front');
        expect(s.rearSideUp, true);
        performStep(s);
        expect(s.rearSideUp, false);
        advanceTo(s, 'flip_back');
        expect(s.rearSideUp, false);
        performStep(s);
        expect(s.rearSideUp, true);
        advanceTo(s, 'flip_test_front');
        expect(s.rearSideUp, true);
        performStep(s);
        expect(s.rearSideUp, false);
      } else {
        expect(s.steps.any((x) => x.id == 'flip_rear'), false);
      }
    });
  }
  test('schema 4 repairs migrate by stable step id, not shifted index', () {
    final s = RepairSession('s', 'battery', device: 'matext');
    advanceTo(s, 'part_out');
    final j = Map<String, dynamic>.from(s.toJson());
    j['v'] = 4;
    j['index'] = (j['index'] as int) - 1;
    final restored = RepairSession.fromJson(jsonDecode(jsonEncode(j)));
    expect(restored.current!.id, 'part_out');
    expect(restored.rearSideUp, true);
    expect(restored.batteryDisconnected, true);
  });
  test(
    'Mate XT board and camera share one panel, battery codes are model-specific',
    () {
      final p = profileFor('matext');
      expect(p.board.x, lessThan(224));
      expect(p.camera.x, lessThan(224));
      expect(p.auxiliaryBatteries.length, 2);
      for (final model in deviceCatalog) {
        expect(profileFor(model.id).manufacturer, model.brand);
      }
    },
  );
}
