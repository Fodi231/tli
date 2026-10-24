import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/repair/repair_session.dart';

void performStep(RepairSession s) {
  final step = s.current!;
  if (step.id == 'power_off') {
    s.runtime.shutDown();
    s.runtime.advance(2200, apple: true, bootMs: 12000);
  }
  if (step.id == 'test' && !s.powered) {
    s.runtime.boot();
    s.runtime.advance(16000, apple: true, bootMs: 12000);
  }
  s.tool = step.tool;
  for (final target in step.targets) {
    while (!s.finished && s.current!.id == step.id && !s.targetDone(target)) {
      final result = s.act(
        target,
        step.gesture,
        destination: step.destination,
        heldMs: s.heatingStep ? 6500 : RepairSession.holdDurationMs,
      );
      expect(result.accepted, isTrue, reason: '${step.id} / $target');
    }
  }
}

void advanceTo(RepairSession s, String id) {
  while (!s.finished && s.current!.id != id) {
    performStep(s);
  }
  expect(s.current?.id, id);
}

void main() {
  for (final service in ['display', 'battery', 'camera', 'port', 'diag']) {
    test('$service can finish only after its full physical recipe', () {
      final s = RepairSession('order', service);
      var steps = 0;
      while (!s.finished) {
        performStep(s);
        steps++;
      }
      expect(s.progress, 1);
      expect(s.mistakes, 0);
      expect(s.isOpen, isFalse);
      expect(s.batteryDisconnected, isFalse);
      expect(steps, service == 'diag' ? 1 : greaterThanOrEqualTo(19));
      expect(s.act('screen', RepairGesture.tap).outcome, RepairOutcome.ignored);
    });
  }
  test(
    'wrong tool and unsafe sequence cannot skip disconnecting the battery',
    () {
      final s = RepairSession('o', 'battery');
      expect(
        s.act('screen', RepairGesture.hold, heldMs: 1200).outcome,
        RepairOutcome.mistake,
      );
      expect(s.index, 0);
      advanceTo(s, 'battery_off');
      s.tool = RepairTool.tweezers;
      expect(
        s.act('battery', RepairGesture.drag, destination: 'old_tray').outcome,
        RepairOutcome.mistake,
      );
      expect(s.current!.id, 'battery_off');
      expect(s.mistakes, 2);
    },
  );
  test(
    'early release, wrong drop and missing stock leave the component in place',
    () {
      final s = RepairSession('o', 'display');
      s.tool = RepairTool.meter;
      expect(
        s.act('screen', RepairGesture.hold, heldMs: 700).accepted,
        isFalse,
      );
      expect(s.index, 0);
      advanceTo(s, 'open');
      s.tool = RepairTool.suction;
      expect(
        s.act('screen', RepairGesture.drag, destination: 'old_tray').accepted,
        isFalse,
      );
      expect(s.isOpen, isFalse);
      advanceTo(s, 'part_in');
      s.tool = RepairTool.tweezers;
      expect(
        s
            .act(
              'new_part',
              RepairGesture.drag,
              destination: 'display_park',
              hasPart: false,
            )
            .message,
        'r_missing_part',
      );
      expect(s.partRemoved, isTrue);
      expect(s.mistakes, 0);
    },
  );
  test('save round trip preserves partial screw turns and tool', () {
    final s = RepairSession('o', 'camera');
    advanceTo(s, 'frame_out');
    s.tool = RepairTool.driver;
    s.act('frame_0', RepairGesture.tap);
    s.act('frame_0', RepairGesture.tap);
    final restored = RepairSession.fromJson(
      jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
    );
    expect(restored.turnsFor('frame_0'), 2);
    expect(restored.tool, RepairTool.driver);
    expect(restored.index, s.index);
    expect(restored.progress, s.progress);
    restored.act('frame_0', RepairGesture.tap);
    expect(restored.targetDone('frame_0'), isTrue);
    expect(restored.current!.id, 'frame_out');
    expect(
      restored.act('frame_0', RepairGesture.tap).outcome,
      RepairOutcome.ignored,
    );
    performStep(restored);
    expect(restored.current!.id, 'heat');
  });
  test('practice can install parts without inventory', () {
    final s = RepairSession(
      RepairSession.practiceId,
      'display',
      training: true,
    );
    advanceTo(s, 'part_in');
    s.tool = RepairTool.tweezers;
    expect(
      s
          .act(
            'new_part',
            RepairGesture.drag,
            destination: 'display_park',
            hasPart: false,
          )
          .accepted,
      isTrue,
    );
  });
}
