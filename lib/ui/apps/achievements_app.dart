import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';

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
          for (final a in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: a.value ? C.orange : C.sub),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a.key.tr, style: TextStyle(color: a.value ? C.text : C.sub))),
                    if (a.value) const Icon(Icons.check_circle, color: C.green),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
