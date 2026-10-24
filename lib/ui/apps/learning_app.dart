import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';
import '../../core/market/market_strings.dart';

class LearningApp extends StatelessWidget {
  const LearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return AppPage(
      title: 'learning'.tr,
      subtitle: mt(
        'Новые навыки для более сложного ремонта',
        'New skills for more advanced repairs',
        'Нові навички для складнішого ремонту',
      ),
      child: ListView(
        children: [
          Panel(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: IosColors.of(context).blue.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: IosColors.of(context).blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mt(
                          'Твои сертификаты',
                          'Your certificates',
                          'Твої сертифікати',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${gs.certCount} / ${courses.length}',
                        style: TextStyle(
                          color: IosColors.of(context).secondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final c in courses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Builder(
                  builder: (context) {
                    final p = gs.courseProgress[c.id] ?? 0;
                    final unlocked = c.prereq == null || gs.hasCert(c.prereq!);
                    final done = p >= 1;
                    return Row(
                      children: [
                        Icon(
                          done
                              ? Icons.verified
                              : (unlocked ? Icons.school : Icons.lock),
                          color:
                              done
                                  ? IosColors.of(context).green
                                  : (unlocked
                                      ? C.accent
                                      : IosColors.of(context).secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nameKey.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (!unlocked)
                                Text(
                                  'locked'.tr,
                                  style: TextStyle(
                                    color: IosColors.of(context).secondary,
                                    fontSize: 12,
                                  ),
                                )
                              else if (done)
                                Text(
                                  'certified'.tr,
                                  style: TextStyle(
                                    color: IosColors.of(context).green,
                                    fontSize: 12,
                                  ),
                                )
                              else
                                LinearProgressIndicator(
                                  value: p,
                                  color: C.accent,
                                  backgroundColor: Colors.white12,
                                ),
                            ],
                          ),
                        ),
                        if (unlocked && !done) ...[
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              if (!context.read<GameState>().study(c)) {
                                toast(context, 'no_money'.tr);
                              }
                            },
                            child: Text(
                              'study'.tr,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
