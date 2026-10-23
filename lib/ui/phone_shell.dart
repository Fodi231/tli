import 'dart:async';

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
import 'wallpaper.dart';
import 'widgets.dart';

/// Layout modes (Settings -> Display): automatic, phone or tablet / PC.
/// Tablet / PC fills the whole window; "phone" on a wide screen shows a
/// phone-shaped frame in the middle.
bool useTabletLayout(GameState gs, double width) =>
    gs.layoutMode == 2 || (gs.layoutMode == 0 && width >= 700);

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
        final framed = !tablet && c.maxWidth > 600;
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
        light: light,
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
                const StatusBar(),
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
              ],
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
  const StatusBar({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final sh = context.watch<Shell>();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        16,
        4,
      ),
      child: Row(
        children: [
          const ClockText(
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const Spacer(),
          if (sh.unlocked)
            GestureDetector(
              onTap: () => context.read<Shell>().open('notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, size: 20),
                  if (gs.unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: C.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${gs.unreadCount}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          Icon(
            gs.online ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: gs.online ? null : C.red,
          ),
          const SizedBox(width: 6),
          const Icon(Icons.battery_full, size: 18),
        ],
      ),
    );
  }
}

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final n = DateTime.now();
    final wd = I18n.weekdays[gs.lang]![n.weekday - 1];
    final mo = I18n.months[gs.lang]![n.month - 1];
    final date = gs.lang == 'en' ? '$wd, $mo ${n.day}' : '$wd, ${n.day} $mo';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<Shell>().unlock(),
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -150) context.read<Shell>().unlock();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).width >= 700 ? 80 : 40),
            const ClockText(
              style: TextStyle(fontSize: 76, fontWeight: FontWeight.w300),
            ),
            Text(date, style: const TextStyle(fontSize: 18, color: C.sub)),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Panel(
                child: Row(
                  children: [
                    const Icon(Icons.cloud, size: 36, color: C.sub),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        gs.city.name(gs.lang),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      gs.city.temp,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              'tagline'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.sub, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text('swipe'.tr, style: const TextStyle(color: C.text)),
            const Icon(Icons.keyboard_arrow_up, color: C.text),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class AppDef {
  final String id;
  final IconData icon;
  final Color color;
  const AppDef(this.id, this.icon, this.color);
}

const homeApps = [
  AppDef('mail', Icons.mail, Color(0xFF3B82F6)),
  AppDef('messages', Icons.chat_bubble, Color(0xFF22C55E)),
  AppDef('map', Icons.map, Color(0xFF14B8A6)),
  AppDef('bank', Icons.account_balance, Color(0xFF16A34A)),
  AppDef('shop', Icons.shopping_cart, Color(0xFFEF4444)),
  AppDef('repair', Icons.build, Color(0xFFF59E0B)),
  AppDef('auctions', Icons.gavel, Color(0xFF8B5CF6)),
  AppDef('transport', Icons.directions_car, Color(0xFF0EA5E9)),
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
  AppDef('work', Icons.work, Color(0xFF2563EB)),
  AppDef('map', Icons.map, Color(0xFF14B8A6)),
  AppDef('messages', Icons.chat_bubble, Color(0xFF22C55E)),
  AppDef('settings', Icons.settings, Color(0xFF6B7280)),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final wide = w >= 700;
        // 4 columns on a phone, more on a tablet / PC window.
        final cols = wide ? (w / 150).floor().clamp(5, 8).toInt() : 4;
        final content = Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Panel(
                    onTap: () => context.read<Shell>().open('bank'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'balance'.tr,
                          style: const TextStyle(color: C.sub, fontSize: 12),
                        ),
                        Text(
                          money(gs.balance),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Panel(
                    onTap: () => context.read<Shell>().open('stats'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'reputation'.tr,
                          style: const TextStyle(color: C.sub, fontSize: 12),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: C.orange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              gs.reputation.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: gs.reputation / 5,
                          color: C.green,
                          backgroundColor: Colors.white12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.count(
                crossAxisCount: cols,
                childAspectRatio: wide ? 1.0 : 0.78,
                physics: const BouncingScrollPhysics(),
                children: [for (final a in homeApps) AppIcon(a)],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [for (final a in dockApps) AppIcon(a, label: false)],
              ),
            ),
          ],
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 14),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

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
                child: Icon(app.icon, color: Colors.white, size: 28),
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
              app.id.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
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
