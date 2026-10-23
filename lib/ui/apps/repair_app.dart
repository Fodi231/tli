import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/repair/repair_session.dart';
import '../../core/repair/repair_strings.dart';
import '../repair/repair_bench.dart';
import '../shell.dart';
import '../widgets.dart';
import 'legacy_repair_app.dart';

class RepairApp extends StatelessWidget {
  final String? orderId;
  const RepairApp({super.key, this.orderId});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    if (orderId == RepairSession.practiceId) {
      return const RepairBench(orderId: RepairSession.practiceId);
    }
    if (orderId != null) {
      for (final order in gs.orders) {
        if (order.id != orderId) continue;
        return supportsWorkbench(order.device)
            ? RepairBench(key: ValueKey(orderId), orderId: orderId!)
            : LegacyRepairApp(orderId: orderId);
      }
      return AppPage(title: 'repair'.tr, child: Empty('no_orders'.tr));
    }
    final active = gs.orders.where((o) => o.status == 'active').toList();
    return AppPage(
      title: rt('r_workbench'),
      child: ListView(
        children: [
          Panel(
            onTap:
                () => context.read<Shell>().open(
                  'repair',
                  arg: RepairSession.practiceId,
                ),
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF65E6AE),
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rt('r_training'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        rt('r_training_desc'),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'active'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('no_orders'.tr),
            ),
          for (final order in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                onTap:
                    () => context.read<Shell>().open('repair', arg: order.id),
                child: Row(
                  children: [
                    Icon(
                      serviceIcon(order.service),
                      color: const Color(0xFF57C5FF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.device,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            services[order.service]!.nameKey.tr,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            rt(
                              supportsWorkbench(order.device)
                                  ? 'r_2d'
                                  : 'r_legacy',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF57C5FF),
                              fontSize: 11,
                            ),
                          ),
                          if (gs.repairs[order.id] case final session?) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: session.progress),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      money(order.price),
                      style: const TextStyle(color: Color(0xFF65E6AE)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
