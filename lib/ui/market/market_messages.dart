import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/models.dart';
import '../../core/market/market_strings.dart';
import 'market_style.dart';

class MarketMessages extends StatefulWidget {
  final ValueChanged<Deal> onChat;
  final VoidCallback onBrowse;
  const MarketMessages({
    super.key,
    required this.onChat,
    required this.onBrowse,
  });
  @override
  State<MarketMessages> createState() => _MarketMessagesState();
}

class _MarketMessagesState extends State<MarketMessages> {
  final search = TextEditingController();
  String filter = 'all';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String time(Deal d) {
    final at = d.messages.lastOrNull?.at;
    if (at == null) return '';
    final now = DateTime.now();
    final days =
        DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(at.year, at.month, at.day)).inDays;
    if (days == 1) return mt('Вчера', 'Yesterday', 'Учора');
    if (days > 1) return '${at.day}.${at.month.toString().padLeft(2, '0')}';
    return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final q = search.text.toLowerCase().trim();
    final list =
        gs.deals
            .where(
              (d) =>
                  (filter == 'all' || d.kind == filter) &&
                  '${d.counterpart} ${d.item} ${d.messages.lastOrNull?.text ?? ''}'
                      .toLowerCase()
                      .contains(q),
            )
            .toList()
          ..sort(
            (a, b) => (b.messages.lastOrNull?.at ?? DateTime(2000)).compareTo(
              a.messages.lastOrNull?.at ?? DateTime(2000),
            ),
          );
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        MarketHeading(
          mt('Сообщения', 'Messages', 'Повідомлення'),
          mt(
            'Договаривайся о покупке и продаже',
            'Make a deal, one conversation at a time',
            'Домовляйся про купівлю та продаж',
          ),
        ),
        TextField(
          key: const ValueKey('messages_search'),
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: mt(
              'Поиск по сообщениям',
              'Search conversations',
              'Пошук у повідомленнях',
            ),
            prefixIcon: const Icon(Icons.search, color: marketDeep, size: 25),
          ),
        ),
        const SizedBox(height: 10),
        MarketPills(
          children: [
            for (final v in ['all', 'buy', 'sell'])
              MarketPill(
                v == 'all'
                    ? mt('Все', 'All', 'Усі')
                    : v == 'buy'
                    ? mt('Покупки', 'Buying', 'Купівлі')
                    : mt('Продажи', 'Selling', 'Продажі'),
                key: ValueKey('messages_filter_$v'),
                selected: filter == v,
                onTap: () => setState(() => filter = v),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          MarketEmpty(
            icon: Icons.forum_outlined,
            title: mt(
              'Начни разговор',
              'Start a conversation',
              'Почни розмову',
            ),
            subtitle: mt(
              'Напиши продавцу или опубликуй своё объявление.',
              'Message a seller or publish your own listing.',
              'Напиши продавцю або опублікуй своє оголошення.',
            ),
            action: mt('Открыть каталог', 'Open catalog', 'Відкрити каталог'),
            onAction: widget.onBrowse,
          ),
        for (final d in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('market_conversation_${d.id}'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => widget.onChat(d),
                child: MarketSurface(
                  padding: const EdgeInsets.all(11),
                  radius: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: MarketAvatar(d.counterpart, size: 48),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    d.counterpart,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  time(d),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: marketMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              d.item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: marketMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.busy
                                  ? mt('Печатает…', 'Typing…', 'Друкує…')
                                  : d.messages.lastOrNull?.text ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                if (d.unreadMessages > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: marketBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${d.unreadMessages}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    d.status == 'won'
                                        ? Icons.task_alt_rounded
                                        : d.messages.lastOrNull?.mine == true
                                        ? Icons.done_all
                                        : Icons.chat_bubble_outline,
                                    color: marketBlue,
                                    size: 15,
                                  ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    d.status == 'won'
                                        ? mt(
                                          'Сделка завершена',
                                          'Deal completed',
                                          'Угоду завершено',
                                        )
                                        : d.status == 'agreed'
                                        ? mt(
                                          'Цена согласована',
                                          'Price agreed',
                                          'Ціну узгоджено',
                                        )
                                        : d.status == 'lost'
                                        ? mt(
                                          'Диалог закрыт',
                                          'Conversation closed',
                                          'Розмову закрито',
                                        )
                                        : d.kind == 'buy'
                                        ? mt('Покупка', 'Buying', 'Купівля')
                                        : mt('Продажа', 'Selling', 'Продаж'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: marketMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 55,
                        height: 78,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DevicePhoto(d.deviceId ?? d.item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: marketMint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: marketBlue,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mt(
                        'Общайся внутри ТехМаркета',
                        'Keep the conversation here',
                        'Спілкуйся в ТехМаркеті',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mt(
                        'История сделки сохранится в переписке',
                        'Your trade history stays in the chat',
                        'Історія угоди збережеться в листуванні',
                      ),
                      style: const TextStyle(fontSize: 11, color: marketMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
