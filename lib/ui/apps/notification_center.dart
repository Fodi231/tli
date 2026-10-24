import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/market/market_strings.dart';
import '../shell.dart';
import '../widgets.dart';

class IosNotificationCenter extends StatelessWidget {
  const IosNotificationCenter({super.key});
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final p = IosColors.of(context);
    return AppPage(
      title: 'notifications'.tr,
      actions: [
        IconButton(
          tooltip: 'mark_read'.tr,
          onPressed: g.markAllRead,
          icon: Icon(Icons.done_all_rounded, color: p.blue),
        ),
      ],
      child:
          g.notifications.isEmpty
              ? Empty(
                mt(
                  'Пока тихо. Новые события появятся здесь.',
                  'All caught up. New events will appear here.',
                  'Поки тихо. Нові події з’являться тут.',
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.only(top: 3, bottom: 18),
                itemCount: g.notifications.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = g.notifications[index];
                  final color =
                      n.type == 'order'
                          ? const Color(0xFFD47825)
                          : n.type == 'money'
                          ? const Color(0xFF7852D8)
                          : const Color(0xFF008E95);
                  return Panel(
                    onTap: () {
                      g.markNotificationRead(n);
                      final shell = context.read<Shell>();
                      if (n.type == 'order') shell.open('work');
                      if (n.type == 'deal' || n.type == 'deals') {
                        shell.open('messages');
                      }
                      if (n.type == 'money') shell.open('bank');
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            n.type == 'order'
                                ? Icons.build_outlined
                                : n.type == 'money'
                                ? Icons.account_balance_wallet_outlined
                                : Icons.chat_bubble_outline_rounded,
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.titleKey.tr,
                                style: TextStyle(
                                  color: p.label,
                                  fontSize: 15,
                                  fontWeight:
                                      n.read
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                n.body,
                                style: TextStyle(
                                  color: p.secondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${n.time.day.toString().padLeft(2, '0')}.${n.time.month.toString().padLeft(2, '0')}  ${n.time.hour.toString().padLeft(2, '0')}:${n.time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: p.secondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: p.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
