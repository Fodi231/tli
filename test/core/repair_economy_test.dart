import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/core/repair/repair_session.dart';

Order order(String id, {String service = 'display'}) => Order(
  id: id,
  device: 'iPhone 13',
  service: service,
  price: 300,
  lat: 0,
  lng: 0,
  status: 'active',
);
void finishStep(GameState gs, String id) {
  final s = gs.repairs[id]!;
  final step = s.current!;
  gs.selectRepairTool(id, step.tool);
  for (final target in step.targets) {
    while (s.current?.id == step.id && !s.targetDone(target)) {
      final r = gs.repairAction(
        id,
        target,
        step.gesture,
        destination: step.destination,
        heldMs: 1200,
      );
      expect(r.accepted, isTrue, reason: step.id);
    }
  }
}

void advance(GameState gs, String id, String stepId) {
  while (gs.repairs[id]!.current?.id != stepId) {
    finishStep(gs, id);
  }
}

void main() {
  test(
    'part is charged once at installation; payout once after final tests',
    () {
      final gs = GameState();
      final o = order('a');
      gs.orders.add(o);
      gs.parts['display'] = 1;
      gs.startWorkbench(o.id);
      expect(gs.completeRepair(o, 0), 0);
      advance(gs, o.id, 'part_in');
      expect(gs.parts['display'], 1);
      finishStep(gs, o.id);
      expect(gs.parts['display'], 0);
      expect(gs.repairs[o.id]!.partConsumed, isTrue);
      expect(gs.balance, 1500);
      while (!gs.repairs[o.id]!.finished) {
        finishStep(gs, o.id);
      }
      expect(gs.balance, 1800);
      expect(gs.completedOrders, 1);
      expect(o.status, 'done');
      gs.completeRepair(o, 0);
      gs.repairAction(o.id, 'test_screen', RepairGesture.hold, heldMs: 1200);
      expect(gs.balance, 1800);
      expect(gs.parts['display'], 0);
      expect(gs.completedOrders, 1);
      gs.dispose();
    },
  );
  test('another open order cannot reuse a consumed part', () {
    final gs = GameState();
    for (final id in ['a', 'b']) {
      gs.orders.add(order(id));
      gs.startWorkbench(id);
    }
    gs.parts['display'] = 1;
    advance(gs, 'a', 'part_in');
    advance(gs, 'b', 'part_in');
    finishStep(gs, 'a');
    gs.selectRepairTool('b', RepairTool.tweezers);
    final r = gs.repairAction(
      'b',
      'new_part',
      RepairGesture.drag,
      destination: 'display_park',
    );
    expect(r.message, 'r_missing_part');
    expect(gs.repairs['b']!.partRemoved, isTrue);
    expect(gs.balance, 1500);
    gs.dispose();
  });
  test(
    'export/import restores an open order and installation without charging twice',
    () {
      final gs = GameState();
      gs.orders.add(order('a'));
      gs.parts['display'] = 1;
      gs.startWorkbench('a');
      advance(gs, 'a', 'part_in');
      finishStep(gs, 'a');
      final restore = GameState();
      expect(restore.importSave(gs.exportSave()), isTrue);
      expect(restore.orders.single.id, 'a');
      expect(restore.repairs['a']!.partConsumed, isTrue);
      expect(restore.parts['display'], 0);
      while (!restore.repairs['a']!.finished) {
        finishStep(restore, 'a');
      }
      expect(restore.balance, 1800);
      expect(restore.parts['display'], 0);
      gs.dispose();
      restore.dispose();
    },
  );
  test('old saves preserve money, stock and courses with no repair fields', () {
    final gs = GameState();
    expect(
      gs.importSave(
        jsonEncode({
          'balance': 735,
          'parts': {'battery': 2},
          'courses': {'basics': 1.0},
        }),
      ),
      isTrue,
    );
    expect(gs.balance, 735);
    expect(gs.parts['battery'], 2);
    expect(gs.hasCert('basics'), isTrue);
    expect(gs.repairs, isEmpty);
    gs.dispose();
  });
  test('practice never changes money, tax, reputation or parts', () {
    final gs = GameState();
    gs.startWorkbench(RepairSession.practiceId);
    while (!gs.repairs[RepairSession.practiceId]!.finished) {
      finishStep(gs, RepairSession.practiceId);
    }
    expect(gs.balance, 1500);
    expect(gs.completedOrders, 0);
    expect(gs.taxDue, 0);
    expect(gs.reputation, 4);
    expect(gs.parts, isEmpty);
    gs.dispose();
  });
}
