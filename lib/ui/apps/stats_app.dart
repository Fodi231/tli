import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/market/market_strings.dart';
import '../widgets.dart';
import '../ios_components.dart';

class StatsApp extends StatelessWidget {
  const StatsApp({super.key});
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final p = IosColors.of(context);
    final rows = [
      (
        Icons.star_rounded,
        const Color(0xFFE2A02E),
        'reputation'.tr,
        '${g.reputation.toStringAsFixed(2)} / 5',
      ),
      (
        Icons.build_outlined,
        p.blue,
        'completed_orders'.tr,
        '${g.completedOrders}',
      ),
      (
        Icons.payments_outlined,
        p.green,
        'total_earned'.tr,
        money(g.totalEarned),
      ),
    ];
    return AppPage(
      title: 'stats'.tr,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF286AE6),
                  Color(0xFF1844A3),
                  Color(0xFF4E4BBA),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFFAED1FF),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mt(
                          'Твой бизнес в цифрах',
                          'Your business at a glance',
                          'Твій бізнес у цифрах',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFD9E7FF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'balance'.tr,
                  style: const TextStyle(
                    color: Color(0xFFD9E7FF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    money(g.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 39,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Divider(color: Color(0x44FFFFFF), height: 1),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'net_worth'.tr,
                      style: const TextStyle(
                        color: Color(0xFFD9E7FF),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      money(g.netWorth),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IosSectionTitle(mt('Результаты', 'Results', 'Результати')),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: rows[i].$2.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(rows[i].$1, color: rows[i].$2, size: 23),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rows[i].$3,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            rows[i].$4,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < rows.length - 1)
                    Divider(height: 1, indent: 68, color: p.separator),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              mt(
                'Показатели обновляются после покупок, продаж и выполненных заказов.',
                'Figures update after purchases, sales and completed orders.',
                'Показники оновлюються після купівель, продажів і виконаних замовлень.',
              ),
              style: TextStyle(color: p.secondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
