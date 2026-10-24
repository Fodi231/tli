import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';
import '../../core/market/market_strings.dart';

class AchievementsApp extends StatelessWidget {
  const AchievementsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final items = <MapEntry<String, bool>>[
      MapEntry('ach_first', gs.completedOrders >= 1),
      MapEntry('ach_five', gs.completedOrders >= 5),
      MapEntry('ach_rep', gs.reputation >= 4.8),
      MapEntry('ach_cert', gs.certCount >= 1),
      MapEntry('ach_rich', gs.balance >= 10000),
    ];
    return AppPage(
      title: 'achievements'.tr,
      child: ListView(
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: C.orange,
                      size: 31,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mt(
                          'Каждый шаг считается',
                          'Every step counts',
                          'Кожен крок важливий',
                        ),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: items.where((a) => a.value).length / items.length,
                  minHeight: 7,
                  color: C.orange,
                ),
                const SizedBox(height: 9),
                Text(
                  '${items.where((a) => a.value).length} / ${items.length}',
                  style: TextStyle(
                    color: IosColors.of(context).secondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final a in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color:
                          a.value ? C.orange : IosColors.of(context).secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a.key.tr,
                        style: TextStyle(
                          color:
                              a.value
                                  ? IosColors.of(context).label
                                  : IosColors.of(context).secondary,
                        ),
                      ),
                    ),
                    if (a.value)
                      Icon(
                        Icons.check_circle,
                        color: IosColors.of(context).green,
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
