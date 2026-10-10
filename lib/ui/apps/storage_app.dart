import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

class StorageApp extends StatelessWidget {
  const StorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return AppPage(
      title: 'storage'.tr,
      child: ListView(
        children: [
          Text('parts_stock'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Panel(
            child: Column(
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(serviceIcon(c), color: C.accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text('part_$c'.tr)),
                        Text('x${gs.parts[c] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('devices_stock'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (gs.stock.isEmpty) Panel(child: Text('empty'.tr, style: const TextStyle(color: C.sub))),
          for (final it in gs.stock)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  children: [
                    const Icon(Icons.phone_iphone, color: C.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${'paid'.tr} ${money(it.cost)}', style: const TextStyle(color: C.sub, fontSize: 12)),
                          Text('${'market_value'.tr} ${money(it.market)}', style: const TextStyle(color: C.sub, fontSize: 12)),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        final g = context.read<GameState>();
                        final d = g.sellDealFor(it) ?? g.spawnDeal('sell', item: it);
                        context.read<Shell>().open('messages', arg: d.id);
                      },
                      child: Text('find_buyer'.tr),
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
