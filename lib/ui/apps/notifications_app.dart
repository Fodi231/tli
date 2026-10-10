import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

class NotificationsApp extends StatelessWidget {
  const NotificationsApp({super.key});

  IconData _icon(String t) {
    switch (t) {
      case 'order':
        return Icons.build;
      case 'deal':
        return Icons.chat_bubble;
      case 'money':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return AppPage(
      title: 'notifications'.tr,
      actions: [
        TextButton(onPressed: context.read<GameState>().markAllRead, child: Text('mark_read'.tr, style: const TextStyle(fontSize: 12))),
      ],
      child: gs.notifications.isEmpty
          ? Empty('empty'.tr)
          : ListView.separated(
              itemCount: gs.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = gs.notifications[i];
                final t = n.time;
                final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                return Panel(
                  onTap: () {
                    final sh = context.read<Shell>();
                    if (n.type == 'order') sh.open('work');
                    if (n.type == 'deal') sh.open('messages');
                    if (n.type == 'money') sh.open('bank');
                  },
                  child: Row(
                    children: [
                      Icon(_icon(n.type), color: n.read ? C.sub : C.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.titleKey.tr, style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w700)),
                            Text(n.body, style: const TextStyle(color: C.sub, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(hm, style: const TextStyle(color: C.sub, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
