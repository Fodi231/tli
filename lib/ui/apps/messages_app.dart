import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class MessagesApp extends StatefulWidget {
  final String? initialDealId;
  const MessagesApp({super.key, this.initialDealId});
  @override
  State<MessagesApp> createState() => _MessagesAppState();
}

class _MessagesAppState extends State<MessagesApp> {
  String? openId;
  final ctrl = TextEditingController();
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    openId = widget.initialDealId;
  }

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  Deal? _deal(GameState gs) {
    for (final d in gs.deals) {
      if (d.id == openId) return d;
    }
    return null;
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  void _send(Deal d, String text) {
    if (text.trim().isEmpty) return;
    ctrl.clear();
    context.read<GameState>().sendToDeal(d, text).then((_) {
      // The AI failed and an offline phrase was used instead: tell the player.
      if (mounted && d.messages.isNotEmpty && d.messages.last.fallback) {
        toast(context, 'ai_failed'.tr);
      }
    });
  }

  Widget _newBtn(BuildContext context) => TextButton.icon(
        onPressed: () {
          final nd = context.read<GameState>().spawnDeal('buy');
          setState(() => openId = nd.id);
        },
        icon: const Icon(Icons.add, size: 18),
        label: Text('new_deal'.tr, style: const TextStyle(fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final d = _deal(gs);
    return LayoutBuilder(builder: (context, box) {
      // Tablet / PC: conversation list on the left, chat on the right.
      if (box.maxWidth >= 800) {
        if (d != null) _scrollDown();
        return AppPage(
          title: 'messages'.tr,
          wide: true,
          actions: [_newBtn(context)],
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 340, child: _listBody(context, gs)),
              const SizedBox(width: 12),
              Expanded(
                child: d == null
                    ? Empty('no_deals'.tr)
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${d.counterpart} · ${d.item}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          Expanded(child: _chatBody(context, d)),
                        ],
                      ),
              ),
            ],
          ),
        );
      }
      if (d == null) return _list(context, gs);
      _scrollDown();
      return _chat(context, d);
    });
  }

  Widget _list(BuildContext context, GameState gs) {
    return AppPage(
      title: 'messages'.tr,
      actions: [_newBtn(context)],
      child: _listBody(context, gs),
    );
  }

  Widget _listBody(BuildContext context, GameState gs) {
    return gs.deals.isEmpty
          ? Empty('no_deals'.tr)
          : ListView.separated(
              itemCount: gs.deals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final x = gs.deals[i];
                final last = x.messages.isEmpty ? '' : x.messages.last.text;
                return Panel(
                  onTap: () => setState(() => openId = x.id),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: x.kind == 'buy' ? C.accent : C.green,
                        child: Text(x.counterpart[0]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${x.counterpart} · ${x.item}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.sub, fontSize: 12)),
                          ],
                        ),
                      ),
                      _statusChip(x),
                    ],
                  ),
                );
              },
            );
  }

  Widget _statusChip(Deal d) {
    final color = d.status == 'won' ? C.green : (d.status == 'lost' ? C.red : C.accent);
    final text = d.status == 'won' ? 'deal_won' : (d.status == 'lost' ? 'deal_lost' : (d.kind == 'buy' ? 'deal_buy' : 'deal_sell'));
    return Text(text.tr, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600));
  }

  Widget _chat(BuildContext context, Deal d) {
    return AppPage(
      title: '${d.counterpart} · ${d.item}',
      actions: [
        IconButton(icon: const Icon(Icons.list), onPressed: () => setState(() => openId = null)),
      ],
      child: _chatBody(context, d),
    );
  }

  Widget _chatBody(BuildContext context, Deal d) {
    final open = d.status == 'open';
    final online = context.watch<GameState>().online;
    final canSend = open && online && !d.busy;
    final base = d.market;
    final quick = d.kind == 'buy' ? [0.7, 0.8, 0.9] : [1.0, 1.1, 1.2];
    return Column(
        children: [
          Panel(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${'market_value'.tr}: ${money(d.market)} · ${(d.kind == 'buy' ? 'tip_buy' : 'tip_sell').tr}',
                    style: const TextStyle(color: C.sub, fontSize: 11),
                  ),
                ),
                _statusChip(d),
              ],
            ),
          ),
          if (!online)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Panel(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  const Icon(Icons.wifi_off, color: C.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${'no_internet'.tr}. ${'ai_needs_net'.tr}', style: const TextStyle(fontSize: 12, color: C.red)),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: scroll,
              children: [
                for (final m in d.messages)
                  Align(
                    alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 270),
                      decoration: BoxDecoration(
                        color: m.mine ? C.accent : C.card2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: m.fallback
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m.text),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.cloud_off, size: 12, color: C.orange),
                                    const SizedBox(width: 4),
                                    Text('ai_offline_reply'.tr, style: const TextStyle(fontSize: 10, color: C.orange)),
                                  ],
                                ),
                              ],
                            )
                          : Text(m.text),
                    ),
                  ),
                if (d.busy)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
              ],
            ),
          ),
          if (open) ...[
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final q in quick)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(money(((base * q) / 5).round() * 5)),
                        onPressed: canSend ? () => _send(d, '${((base * q) / 5).round() * 5}') : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    enabled: canSend,
                    onSubmitted: (v) => _send(d, v),
                    decoration: InputDecoration(
                      hintText: 'type_offer'.tr,
                      filled: true,
                      fillColor: C.card,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: C.accent),
                  onPressed: canSend ? () => _send(d, ctrl.text) : null,
                ),
              ],
            ),
          ],
        ],
      );
  }
}
