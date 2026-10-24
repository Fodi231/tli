import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../shell.dart';
import '../liquid_surface.dart';
import '../market/market_style.dart';

class NotificationsApp extends StatelessWidget {
  const NotificationsApp({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Theme(
      data: marketTheme(),
      child: Material(
        color: const Color(0xFFF3F8FC),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 7, 10, 7),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.read<Shell>().close(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'notifications'.tr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'mark_read'.tr,
                    onPressed: gs.markAllRead,
                    icon: const Icon(Icons.done_all, color: Color(0xFF176B81)),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  gs.notifications.isEmpty
                      ? Center(
                        child: Text(
                          'empty'.tr,
                          style: const TextStyle(color: Color(0xFF405970)),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: gs.notifications.length,
                        separatorBuilder:
                            (_, index) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final n = gs.notifications[index];
                          final icon =
                              n.type == 'order'
                                  ? Icons.build_outlined
                                  : n.type == 'money'
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.chat_bubble_outline;
                          return GestureDetector(
                            onTap: () {
                              gs.markNotificationRead(n);
                              final shell = context.read<Shell>();
                              if (n.type == 'order') shell.open('work');
                              if (n.type == 'deal' || n.type == 'deals') {
                                shell.open('messages');
                              }
                              if (n.type == 'money') shell.open('bank');
                            },
                            child: LiquidSurface(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F0F6),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: const Color(0xFF176B81),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.titleKey.tr,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                n.read
                                                    ? FontWeight.w500
                                                    : FontWeight.w700,
                                            color: const Color(0xFF10283C),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          n.body,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF405970),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          '${n.time.hour.toString().padLeft(2, '0')}:${n.time.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF526A80),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!n.read)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6, top: 4),
                                      child: Icon(
                                        Icons.circle,
                                        color: Color(0xFF008E95),
                                        size: 7,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
