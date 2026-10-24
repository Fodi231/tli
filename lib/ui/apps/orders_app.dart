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
    final list =
        gs.orders.where((o) => filter == 'all' || o.status == filter).toList()
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
            child:
                list.isEmpty
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
    final p = IosColors.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: p.blue.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(serviceIcon(order.service), color: p.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.nameKey.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.device,
                      style: TextStyle(color: p.secondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (order.status == 'done')
                Icon(Icons.check_circle_rounded, color: p.green),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                money(order.price),
                style: TextStyle(
                  color: p.green,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${km.toStringAsFixed(1)} km',
                style: TextStyle(color: p.secondary, fontSize: 12),
              ),
            ],
          ),
          if (order.status != 'done') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    () =>
                        order.status == 'available'
                            ? context.read<GameState>().acceptOrder(order)
                            : context.read<Shell>().open(
                              'repair',
                              arg: order.id,
                            ),
                child: Text(
                  (order.status == 'available' ? 'accept' : 'start_repair').tr,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
