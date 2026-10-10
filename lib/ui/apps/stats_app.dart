import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class StatsApp extends StatelessWidget {
  const StatsApp({super.key});

  Widget _tile(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Panel(
          child: Row(
            children: [
              Icon(icon, color: C.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return AppPage(
      title: 'stats'.tr,
      child: ListView(
        children: [
          _tile('balance'.tr, money(gs.balance), Icons.account_balance_wallet),
          _tile('net_worth'.tr, money(gs.netWorth), Icons.trending_up),
          _tile('reputation'.tr, gs.reputation.toStringAsFixed(2), Icons.star),
          _tile('completed_orders'.tr, '${gs.completedOrders}', Icons.build),
          _tile('total_earned'.tr, money(gs.totalEarned), Icons.payments),
        ],
      ),
    );
  }
}
