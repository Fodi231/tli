import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

class OrdersApp extends StatefulWidget {
  const OrdersApp({super.key});
  @override
  State<OrdersApp> createState() => _OrdersAppState();
}

class _OrdersAppState extends State<OrdersApp> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final list = gs.orders.where((o) => filter == 'all' || o.status == filter).toList()
      ..sort((a, b) => a.status.compareTo(b.status));
    return AppPage(
      title: 'orders_title'.tr,
      child: Column(
        children: [
          ChipRow(
            ids: const ['all', 'available', 'active', 'done'],
            selected: filter,
            label: (id) => id.tr,
            onSelect: (id) => setState(() => filter = id),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Empty('no_orders'.tr)
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => OrderCard(order: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = services[order.service]!;
    final km = gs.distanceKm(order.lat, order.lng);
    return Panel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: C.card2, borderRadius: BorderRadius.circular(12)),
            child: Icon(serviceIcon(order.service), color: C.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nameKey.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(order.device, style: const TextStyle(color: C.sub, fontSize: 12)),
                Text('${km.toStringAsFixed(1)} km', style: const TextStyle(color: C.sub, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(order.price), style: const TextStyle(color: C.green, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              if (order.status == 'available')
                FilledButton(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => context.read<GameState>().acceptOrder(order),
                  child: Text('accept'.tr),
                )
              else if (order.status == 'active')
                FilledButton(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: C.orange),
                  onPressed: () => context.read<Shell>().open('repair', arg: order.id),
                  child: Text('start_repair'.tr),
                )
              else
                const Icon(Icons.check_circle, color: C.green),
            ],
          ),
        ],
      ),
    );
  }
}
