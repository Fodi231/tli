import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/models.dart';
import '../../core/market/market_strings.dart';
import '../widgets.dart';
import 'marketplace_app.dart';

class MarketChat extends StatefulWidget {
  final Deal deal;
  final VoidCallback onBack;
  const MarketChat({super.key, required this.deal, required this.onBack});
  @override
  State<MarketChat> createState() => _MarketChatState();
}

class _MarketChatState extends State<MarketChat> {
  final input = TextEditingController();
  final scroll = ScrollController();
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send(String text, {double? price}) async {
    if (text.trim().isEmpty) return;
    input.clear();
    final pending = context.read<GameState>().sendToDeal(
      widget.deal,
      text,
      priceOffer: price,
    );
    _bottom();
    await pending;
    _bottom();
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  });
  Future<void> offer() async {
    final amount = TextEditingController(
      text: widget.deal.currentPrice.round().toString(),
    );
    final price = await showDialog<double>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(
              mt('Предложить цену', 'Make an offer', 'Запропонувати ціну'),
            ),
            content: TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: mt(
                  'Игровые доллары',
                  'Game dollars',
                  'Ігрові долари',
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(mt('Отмена', 'Cancel', 'Скасувати')),
              ),
              FilledButton(
                onPressed: () {
                  final n = double.tryParse(amount.text.replaceAll(',', '.'));
                  if (n != null && n.isFinite && n > 0 && n <= 1000000) {
                    Navigator.pop(c, n);
                  }
                },
                child: Text(mt('Предложить', 'Offer', 'Запропонувати')),
              ),
            ],
          ),
    );
    // Wait for the closing route animation before disposing its controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    amount.dispose();
    if (price != null && mounted) {
      await send(
        '${mt("Предлагаю", "I offer", "Пропоную")} ${money(price)}',
        price: price,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final d = widget.deal;
    final open = d.status == 'open';
    final agreed = d.status == 'agreed';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
              CircleAvatar(
                backgroundColor: marketGray,
                child: Text(
                  d.counterpart.isEmpty ? '?' : d.counterpart[0],
                  style: const TextStyle(color: marketBlue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.counterpart,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      d.busy
                          ? mt('печатает…', 'typing…', 'друкує…')
                          : mt(
                            'Игровой собеседник',
                            'Game character',
                            'Ігровий співрозмовник',
                          ),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz),
            ],
          ),
        ),
        Container(
          color: marketGray,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: DevicePhoto(d.deviceId ?? d.item),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.item,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${money(d.currentPrice)} · ${faultText(d.fault)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(12),
            itemCount: d.messages.length + (d.busy ? 1 : 0),
            itemBuilder: (c, i) {
              if (i == d.messages.length) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final m = d.messages[i];
              return Align(
                alignment:
                    m.mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width.clamp(220, 440) * .76,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: m.mine ? const Color(0xFFDFF2FF) : marketGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.text,
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m.fallback) ...[
                            const Icon(
                              Icons.cloud_off_outlined,
                              size: 11,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              mt('Без ИИ', 'Offline', 'Без ШІ'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(width: 7),
                          ],
                          Text(
                            '${m.at.hour.toString().padLeft(2, "0")}:${m.at.minute.toString().padLeft(2, "0")}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blueGrey,
                            ),
                          ),
                          if (m.mine)
                            const Icon(
                              Icons.done_all,
                              size: 13,
                              color: marketBlue,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (gs.aiKey.isEmpty || !gs.online)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Text(
              mt(
                'Работают игровые ответы. Для Gemini: Профиль → Настроить Gemini.',
                'Using offline replies. For Gemini: Profile → Configure Gemini.',
                'Працюють ігрові відповіді. Gemini: Профіль → Налаштувати Gemini.',
              ),
              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
          ),
        if (agreed)
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    d.busy
                        ? null
                        : () {
                          final ok = gs.confirmDeal(d);
                          if (!ok) {
                            toast(
                              context,
                              mt(
                                'Недостаточно денег или устройство уже недоступно',
                                'Insufficient funds or device unavailable',
                                'Недостатньо грошей або пристрій недоступний',
                              ),
                            );
                          }
                        },
                icon: const Icon(Icons.handshake_outlined),
                label: Text(
                  '${d.kind == "buy" ? mt("Купить", "Buy", "Купити") : mt("Продать", "Sell", "Продати")} · ${money(d.currentPrice)}',
                ),
              ),
            ),
          ),
        if (open) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: d.busy ? null : offer,
                  icon: const Icon(Icons.local_offer_outlined, size: 16),
                  label: Text(
                    mt(
                      'Предложить цену',
                      'Make an offer',
                      'Запропонувати ціну',
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  money(gs.balance),
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    enabled: !d.busy,
                    maxLength: 3000,
                    minLines: 1,
                    maxLines: 3,
                    onSubmitted: d.busy ? null : (v) => send(v),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: mt('Сообщение…', 'Message…', 'Повідомлення…'),
                      filled: true,
                      fillColor: marketGray,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: d.busy ? null : () => send(input.text),
                  icon: const Icon(Icons.send_rounded, color: marketBlue),
                ),
              ],
            ),
          ),
        ],
        if (!open && !agreed)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              d.status == 'won'
                  ? mt(
                    'Сделка завершена ✓',
                    'Trade completed ✓',
                    'Угоду завершено ✓',
                  )
                  : mt(
                    'Переписка завершена',
                    'Conversation closed',
                    'Розмову завершено',
                  ),
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),
      ],
    );
  }
}
