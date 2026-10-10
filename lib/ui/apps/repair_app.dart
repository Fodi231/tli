import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

class RepairApp extends StatefulWidget {
  final String? orderId;
  const RepairApp({super.key, this.orderId});
  @override
  State<RepairApp> createState() => _RepairAppState();
}

class _RepairAppState extends State<RepairApp> {
  late final List<int> shuffled;
  int next = 0;
  int mistakes = 0;
  double? reward;

  @override
  void initState() {
    super.initState();
    shuffled = List.generate(6, (i) => i + 1)..shuffle();
  }

  Order? _find(GameState gs) {
    for (final o in gs.orders) {
      if (o.id == widget.orderId) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    // No order chosen: show the list of active orders.
    if (widget.orderId == null) {
      final active = gs.orders.where((o) => o.status == 'active').toList();
      return AppPage(
        title: 'repair'.tr,
        child: active.isEmpty
            ? Empty('no_orders'.tr)
            : ListView(
                children: [
                  for (final o in active)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Panel(
                        onTap: () => context.read<Shell>().open('repair', arg: o.id),
                        child: Row(
                          children: [
                            Icon(serviceIcon(o.service), color: C.accent),
                            const SizedBox(width: 12),
                            Expanded(child: Text('${services[o.service]!.nameKey.tr} · ${o.device}')),
                            Text(money(o.price), style: const TextStyle(color: C.green)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      );
    }

    final order = _find(gs);
    if (order == null) return AppPage(title: 'repair'.tr, child: Empty('no_orders'.tr));
    final s = services[order.service]!;

    if (reward != null) {
      return AppPage(
        title: 'repair'.tr,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 72, color: C.green),
              const SizedBox(height: 12),
              Text('finish_ok'.tr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('${'reward'.tr}: ${money(reward!)}', style: const TextStyle(color: C.green, fontSize: 18)),
              Text('${'mistakes'.tr}: $mistakes', style: const TextStyle(color: C.sub)),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.read<Shell>().open('work'), child: Text('orders_title'.tr)),
            ],
          ),
        ),
      );
    }

    // Needs a part that the player does not have yet.
    if (!gs.hasPartFor(order)) {
      return AppPage(
        title: 'repair'.tr,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 56, color: C.orange),
              const SizedBox(height: 12),
              Text('${'need_part'.tr}: ${'part_${s.cat}'.tr}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.read<Shell>().open('shop'), child: Text('go_shop'.tr)),
            ],
          ),
        ),
      );
    }

    final hints = gs.hasCert('basics');
    return AppPage(
      title: s.nameKey.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Row(
              children: [
                Icon(serviceIcon(order.service), color: C.accent),
                const SizedBox(width: 10),
                Expanded(child: Text(order.device, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(money(order.price), style: const TextStyle(color: C.green, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('steps_hint'.tr, style: const TextStyle(color: C.sub)),
          const SizedBox(height: 4),
          Text('${'mistakes'.tr}: $mistakes', style: TextStyle(color: mistakes > 0 ? C.red : C.sub)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: next / 6, color: C.green, backgroundColor: Colors.white12),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final n in shuffled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _step(context, gs, order, n, hints),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, GameState gs, Order order, int n, bool hints) {
    final done = n <= next;
    return Panel(
      onTap: done
          ? null
          : () {
              if (n == next + 1) {
                setState(() => next++);
                if (gs.haptics) HapticFeedback.lightImpact();
                if (next == 6) {
                  final r = context.read<GameState>().completeRepair(order, mistakes);
                  setState(() => reward = r);
                }
              } else {
                setState(() => mistakes++);
                if (gs.haptics) HapticFeedback.heavyImpact();
              }
            },
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? C.green : C.sub),
          const SizedBox(width: 12),
          Expanded(
            child: Text('step$n'.tr, style: TextStyle(color: done ? C.sub : C.text)),
          ),
          if (hints && !done) Text('#$n', style: const TextStyle(color: C.orange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
