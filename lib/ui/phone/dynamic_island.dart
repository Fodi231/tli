import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/market/market_strings.dart';
import '../shell.dart';
import '../widgets.dart';

class DynamicIsland extends StatefulWidget {
  const DynamicIsland({super.key});
  @override
  State<DynamicIsland> createState() => _DynamicIslandState();
}

class _DynamicIslandState extends State<DynamicIsland>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  Timer? tick;
  bool expanded = false;
  @override
  void initState() {
    super.initState();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final busy = gs.deals.any((d) => d.busy);
    final txn = gs.txns.firstOrNull;
    final recent =
        txn != null && DateTime.now().difference(txn.time).inSeconds < 7;
    final repairs = gs.orders.where((o) => o.status == 'active').length;
    final title =
        busy
            ? mt('Сообщение', 'Message', 'Повідомлення')
            : recent
            ? money(txn.amount)
            : repairs > 0
            ? mt('Ремонт', 'Repair', 'Ремонт')
            : 'TechLife';
    final tint =
        busy
            ? const Color(0xFF9AC9FF)
            : recent
            ? (txn.amount >= 0
                ? const Color(0xFF64EAA1)
                : const Color(0xFFFFBB82))
            : const Color(0xFF82C9FC);
    return Semantics(
      button: true,
      label: 'Dynamic Island · $title',
      child: GestureDetector(
        onTap: () => setState(() => expanded = !expanded),
        onLongPress: () => context.read<Shell>().lock(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          width: expanded ? 310 : 132,
          height: expanded ? 126 : 35,
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 16 : 10,
            vertical: expanded ? 12 : 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF030405),
            borderRadius: BorderRadius.circular(expanded ? 29 : 25),
            border: Border.all(color: const Color(0xFF25272B), width: .7),
            boxShadow:
                expanded
                    ? const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ]
                    : [],
          ),
          child: ClipRect(
            child:
                expanded
                    ? SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                busy
                                    ? Icons.auto_awesome
                                    : recent
                                    ? Icons.account_balance_wallet_outlined
                                    : Icons.build_circle_outlined,
                                size: 19,
                                color: tint,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tint,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _waves(tint, busy),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            busy
                                ? mt(
                                  'Собеседник готовит ответ…',
                                  'Your contact is replying…',
                                  'Співрозмовник готує відповідь…',
                                )
                                : '${mt("Активных ремонтов", "Active repairs", "Активних ремонтів")}: $repairs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              _link(
                                mt('Сообщения', 'Inbox', 'Повідомлення'),
                                'messages',
                              ),
                              const SizedBox(width: 8),
                              _link(
                                mt('Мастерская', 'Workbench', 'Майстерня'),
                                'repair',
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    : Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Color(0xFF24486E), Color(0xFF060A12)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: Text(
                              title,
                              key: ValueKey(title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    busy || recent || repairs > 0
                                        ? tint
                                        : Colors.white38,
                              ),
                            ),
                          ),
                        ),
                        _waves(tint, busy),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _link(String title, String app) => Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() => expanded = false);
        context.read<Shell>().open(app);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      ),
    ),
  );
  Widget _waves(Color color, bool busy) => AnimatedBuilder(
    animation: animation,
    builder:
        (c, _) => SizedBox(
          width: 19,
          height: 19,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 2.4,
                  height:
                      busy
                          ? 5 +
                              (math.sin(animation.value * 2 * math.pi + i) +
                                      1) *
                                  5
                          : (i.isEven ? 5 : 9),
                  decoration: BoxDecoration(
                    color: busy ? color : color.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
  );
}
