import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class LearningApp extends StatelessWidget {
  const LearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return AppPage(
      title: 'learning'.tr,
      child: ListView(
        children: [
          for (final c in courses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Builder(builder: (context) {
                  final p = gs.courseProgress[c.id] ?? 0;
                  final unlocked = c.prereq == null || gs.hasCert(c.prereq!);
                  final done = p >= 1;
                  return Row(
                    children: [
                      Icon(
                        done ? Icons.verified : (unlocked ? Icons.school : Icons.lock),
                        color: done ? C.green : (unlocked ? C.accent : C.sub),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.nameKey.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            if (!unlocked)
                              Text('locked'.tr, style: const TextStyle(color: C.sub, fontSize: 12))
                            else if (done)
                              Text('certified'.tr, style: const TextStyle(color: C.green, fontSize: 12))
                            else
                              LinearProgressIndicator(value: p, color: C.accent, backgroundColor: Colors.white12),
                          ],
                        ),
                      ),
                      if (unlocked && !done) ...[
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () {
                            if (!context.read<GameState>().study(c)) toast(context, 'no_money'.tr);
                          },
                          child: Text('study'.tr, style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
