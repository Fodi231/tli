import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/game_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../core/repair/repair_session.dart';
import 'apps/achievements_app.dart';
import 'apps/bank_app.dart';
import 'apps/learning_app.dart';
import 'apps/map_app.dart';
import 'apps/messages_app.dart';
import 'apps/notifications_app.dart';
import 'apps/orders_app.dart';
import 'apps/placeholder_app.dart';
import 'apps/repair_app.dart';
import 'apps/settings_app.dart';
import 'apps/shop_app.dart';
import 'apps/stats_app.dart';
import 'apps/storage_app.dart';
import 'shell.dart';
import '../core/market/market_strings.dart';
import 'market/marketplace_app.dart';
import 'phone/dynamic_island.dart';
import 'wallpaper.dart';
import 'widgets.dart';

/// Layout modes (Settings -> Display): automatic, phone or tablet / PC.
/// Tablet / PC fills the whole window; "phone" on a wide screen shows a
/// phone-shaped frame in the middle.
bool useTabletLayout(GameState gs, double width) => gs.layoutMode == 2;

class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final sh = context.watch<Shell>();
    // A workbench is a game scene, so it uses the whole display even when
    // the player chose a framed phone layout for the in-game applications.
    if (sh.app == 'repair' && sh.arg is String) {
      final id = sh.arg as String;
      final matching = gs.orders.where((o) => o.id == id);
      if (id == RepairSession.practiceId ||
          (matching.isNotEmpty && supportsWorkbench(matching.first.device))) {
        return Scaffold(body: RepairApp(key: ValueKey(id), orderId: id));
      }
    }
    return LayoutBuilder(
      builder: (context, c) {
        final tablet = useTabletLayout(gs, c.maxWidth);
        final framed = !tablet && c.maxWidth > 600 && c.maxHeight > 600;
        return Scaffold(
          backgroundColor: framed ? const Color(0xFF05070D) : C.bg,
          body:
              framed
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AspectRatio(
                          aspectRatio: 9 / 19.5,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(42),
                              border: Border.all(
                                color: Colors.white24,
                                width: 5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: const PhoneScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  : const PhoneScreen(),
        );
      },
    );
  }
}

class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final sh = context.watch<Shell>();
    final light = isLightMode(
      gs.themeMode,
      MediaQuery.platformBrightnessOf(context),
    );
    Widget body;
    String key;
    if (!sh.unlocked) {
      body = const LockScreen();
      key = 'lock';
    } else if (sh.app == null) {
      body = const HomeScreen();
      key = 'home';
    } else {
      // Apps are drawn dark; the light theme inverts them (the wallpaper,
      // lock screen and home screen are not affected).
      body = ThemeFilter(
        light:
            light &&
            sh.app != 'market' &&
            sh.app != 'messages' &&
            sh.app != 'notifications',
        child: AppHost(id: sh.app!, arg: sh.arg),
      );
      key = 'app_${sh.app}_${sh.arg}_$light';
    }
    return LayoutBuilder(
      builder: (context, c) {
        Shell.phoneSize = Size(c.maxWidth, c.maxHeight);
        return Stack(
          children: [
            Positioned.fill(child: Aurora(lock: !sh.unlocked)),
            Column(
              children: [
                StatusBar(
                  light:
                      sh.unlocked &&
                      (sh.app == 'market' ||
                          (sh.app == 'messages' || sh.app == 'notifications')),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder:
                        (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.92, end: 1.0).animate(anim),
                            child: child,
                          ),
                        ),
                    child: KeyedSubtree(key: ValueKey(key), child: body),
                  ),
                ),
                GestureDetector(
                  onTap: () => sh.unlocked ? sh.close() : sh.unlock(),
                  onVerticalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < -100) {
                      sh.unlocked ? sh.close() : sh.unlock();
                    }
                  },
                  child: Container(
                    height: 19,
                    color:
                        sh.app == 'market' ||
                                (sh.app == 'messages' ||
                                    sh.app == 'notifications')
                            ? Colors.white
                            : Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      width: 115,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            sh.app == 'market' ||
                                    (sh.app == 'messages' ||
                                        sh.app == 'notifications')
                                ? Colors.black87
                                : Colors.white70,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 9,
              left: 18,
              right: 14,
              child: const Align(
                alignment: Alignment.topCenter,
                child: DynamicIsland(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Wallpaper layer. The lock screen uses its own wallpaper only when the
/// "separate lock screen wallpaper" option is on, otherwise it matches home.
class Aurora extends StatelessWidget {
  final bool lock;
  const Aurora({super.key, this.lock = false});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return WallpaperView(
      cfg: lock ? gs.lockCfg : gs.homeWp,
      dim: gs.wallpaperDim,
    );
  }
}

class ClockText extends StatefulWidget {
  final TextStyle style;
  const ClockText({super.key, required this.style});
  @override
  State<ClockText> createState() => _ClockTextState();
}

class _ClockTextState extends State<ClockText> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final s =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
    return Text(s, style: widget.style);
  }
}

class StatusBar extends StatelessWidget {
  final bool light;
  const StatusBar({super.key, this.light = false});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final fg = light ? Colors.black : Colors.white;
    return ColoredBox(
      color: light ? Colors.white : Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.paddingOf(context).top + 9,
          14,
          9,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                children: [
                  ClockText(
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.signal_cellular_alt, size: 15, color: fg),
                  const SizedBox(width: 3),
                  Icon(
                    gs.online ? Icons.wifi : Icons.wifi_off,
                    size: 15,
                    color: fg,
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.battery_full_rounded, size: 21, color: fg),
                ],
              ),
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = const Color(0x28FFFFFF),
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(25),
    child: BackdropFilter(
      enabled: context.watch<GameState>().liquidGlass,
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color:
              context.watch<GameState>().liquidGlass
                  ? color
                  : const Color(0xFF293A50),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withValues(alpha: .16),
            width: .7,
          ),
        ),
        child: child,
      ),
    ),
  );
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool unlocking = false;
  Future<void> unlock() async {
    if (unlocking) return;
    setState(() => unlocking = true);
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (mounted) context.read<Shell>().unlock();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final n = DateTime.now();
    final wd = I18n.weekdays[gs.lang]![n.weekday - 1];
    final mo = I18n.months[gs.lang]![n.month - 1];
    final date = gs.lang == 'en' ? '$wd, $mo ${n.day}' : '$wd, ${n.day} $mo';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: unlock,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -100) unlock();
      },
      child: LayoutBuilder(
        builder:
            (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 5),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            unlocking
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            key: ValueKey(unlocking),
                            size: 23,
                            color: Colors.white.withValues(alpha: .85),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ClockText(
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Color(0xFFF0F4FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 90,
                              letterSpacing: -5,
                              height: 1.08,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _metric(
                                Icons.account_balance_wallet_outlined,
                                money(gs.balance),
                                'balance'.tr,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _metric(
                                Icons.build_circle_outlined,
                                '${gs.orders.where((o) => o.status == 'active').length}',
                                mt('в работе', 'active', 'у роботі'),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _metric(
                                Icons.star_outline,
                                gs.reputation.toStringAsFixed(1),
                                'reputation'.tr,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        GestureDetector(
                          onTap: () => context.read<Shell>().open('work'),
                          child: Glass(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF168AFE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.build_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TECHLIFE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mt(
                                          'Твоя мастерская ждёт',
                                          'Your workshop is waiting',
                                          'Твоя майстерня чекає',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        mt(
                                          'Покупай. Восстанавливай. Зарабатывай.',
                                          'Buy. Restore. Make a profit.',
                                          'Купуй. Відновлюй. Заробляй.',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 26),
                        Text(
                          gs.city.name(gs.lang),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _shortcut(Icons.flashlight_on_outlined, 'repair'),
                            Flexible(
                              child: Text(
                                unlocking
                                    ? mt(
                                      'Открываем…',
                                      'Opening…',
                                      'Відкриваємо…',
                                    )
                                    : 'swipe'.tr,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            _shortcut(Icons.storefront_outlined, 'market'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) => Glass(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
    color: const Color(0x16FFFFFF),
    child: Column(
      children: [
        Icon(icon, size: 22, color: Colors.white70),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 9),
        ),
      ],
    ),
  );
  Widget _shortcut(IconData icon, String app) => IconButton.filledTonal(
    onPressed: () => context.read<Shell>().open(app),
    style: IconButton.styleFrom(
      backgroundColor: Colors.black26,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(14),
    ),
    icon: Icon(icon, size: 24),
  );
}

class AppDef {
  final String id;
  final IconData icon;
  final Color color;
  const AppDef(this.id, this.icon, this.color);
}

const homeApps = [
  AppDef('market', Icons.shopping_bag_rounded, Color(0xFF008E95)),
  AppDef('mail', Icons.mail, Color(0xFF3B82F6)),
  AppDef('messages', Icons.chat_bubble, Color(0xFF22C55E)),
  AppDef('map', Icons.map, Color(0xFF14B8A6)),
  AppDef('bank', Icons.account_balance, Color(0xFF16A34A)),
  AppDef('shop', Icons.shopping_cart, Color(0xFFEF4444)),
  AppDef('repair', Icons.build, Color(0xFFF59E0B)),
  AppDef('work', Icons.work, Color(0xFF2563EB)),
  AppDef('storage', Icons.inventory_2, Color(0xFFEA580C)),
  AppDef('staff', Icons.groups, Color(0xFF3B82F6)),
  AppDef('stats', Icons.bar_chart, Color(0xFF16A34A)),
  AppDef('learning', Icons.school, Color(0xFFF97316)),
  AppDef('achievements', Icons.emoji_events, Color(0xFF2563EB)),
  AppDef('calendar', Icons.calendar_today, Color(0xFFE5E7EB)),
  AppDef('settings', Icons.settings, Color(0xFF6B7280)),
];

const dockApps = [
  AppDef('market', Icons.shopping_bag_rounded, Color(0xFF008E95)),
  AppDef('repair', Icons.build, Color(0xFFF59E0B)),
  AppDef('messages', Icons.chat_bubble, Color(0xFF22C55E)),
  AppDef('settings', Icons.settings, Color(0xFF6B7280)),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 700;
        final cols = wide ? 6 : 4;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 17),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.read<Shell>().open('map'),
                      child: Glass(
                        color: const Color(0xD01C5681),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gs.city.name(gs.lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              gs.city.temp,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.1,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.cloud_outlined,
                                  color: Colors.white60,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    mt(
                                      'Климат города',
                                      'City climate',
                                      'Клімат міста',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.read<Shell>().open('bank'),
                      child: Glass(
                        color: const Color(0xD022302D),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TECHLIFE WALLET',
                              style: TextStyle(
                                color: Color(0xFF97CAA7),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: .8,
                              ),
                            ),
                            const SizedBox(height: 7),
                            FittedBox(
                              child: Text(
                                money(gs.balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.bold,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${gs.reputation.toStringAsFixed(1)} / 5  ·  ${gs.stock.length} ${mt("устройств", "devices", "пристроїв")}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  itemCount: wide ? 1 : 2,
                  onPageChanged: (i) => setState(() => page = i),
                  itemBuilder: (c, p) {
                    final apps =
                        wide
                            ? homeApps
                            : homeApps.skip(p * 12).take(12).toList();
                    return GridView.count(
                      crossAxisCount: cols,
                      childAspectRatio: .83,
                      mainAxisSpacing: 8,
                      children: [for (final a in apps) AppIcon(a)],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < (wide ? 1 : 2); i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(3),
                        width: page == i ? 15 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: page == i ? Colors.white : Colors.white30,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _search(context),
                child: Glass(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  color: Colors.black26,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        mt('Поиск', 'Search', 'Пошук'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Glass(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final a in dockApps) AppIcon(a, label: false),
                  ],
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }

  Future<void> _search(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF152033),
    builder: (c) {
      String query = '';
      return StatefulBuilder(
        builder:
            (c, update) => SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  MediaQuery.viewInsetsOf(c).bottom + 18,
                ),
                child: SizedBox(
                  height: math.min(400, MediaQuery.sizeOf(c).height * .6),
                  child: Column(
                    children: [
                      TextField(
                        autofocus: true,
                        onChanged: (s) => update(() => query = s),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: mt(
                            'Найти приложение',
                            'Find an app',
                            'Знайти застосунок',
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            for (final a in homeApps.where(
                              (a) => appLabel(
                                a.id,
                              ).toLowerCase().contains(query.toLowerCase()),
                            ))
                              ListTile(
                                leading: Icon(a.icon, color: a.color),
                                title: Text(appLabel(a.id)),
                                onTap: () {
                                  Navigator.pop(c);
                                  context.read<Shell>().open(a.id);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    },
  );
}

String appLabel(String id) =>
    id == 'market' ? mt('ТехМаркет', 'TechMarket', 'ТехМаркет') : id.tr;

class AppIcon extends StatelessWidget {
  final AppDef app;
  final bool label;
  const AppIcon(this.app, {super.key, this.label = true});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    var badge = 0;
    if (app.id == 'messages') badge = gs.openDeals;
    return GestureDetector(
      onTap: () => context.read<Shell>().open(app.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      app.color,
                      Color.lerp(app.color, Colors.black, 0.35)!,
                    ],
                  ),
                ),
                child:
                    app.id == 'market'
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/icon/techmarket.png',
                            fit: BoxFit.cover,
                          ),
                        )
                        : Icon(app.icon, color: Colors.white, size: 28),
              ),
              if (badge > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: C.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (label) ...[
            const SizedBox(height: 6),
            Text(
              appLabel(app.id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppHost extends StatelessWidget {
  final String id;
  final Object? arg;
  const AppHost({super.key, required this.id, this.arg});

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'market':
        return MarketplaceApp(initialTab: arg is int ? arg as int : 0);
      case 'work':
        return const OrdersApp();
      case 'shop':
        return const ShopApp();
      case 'repair':
        return RepairApp(orderId: arg as String?);
      case 'storage':
        return const StorageApp();
      case 'messages':
        return MessagesApp(initialDealId: arg as String?);
      case 'map':
        return const MapApp();
      case 'bank':
        return const BankApp();
      case 'learning':
        return const LearningApp();
      case 'stats':
        return const StatsApp();
      case 'achievements':
        return const AchievementsApp();
      case 'settings':
        return const SettingsApp();
      case 'notifications':
        return const NotificationsApp();
      default:
        return PlaceholderApp(titleKey: id);
    }
  }
}
