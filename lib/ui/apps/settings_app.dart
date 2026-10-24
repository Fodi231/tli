import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/admin_auth.dart';
import '../../core/ai_service.dart';
import '../../core/app_info.dart';
import '../../core/app_log.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/window_service.dart';
import '../../core/wallpaper_cfg.dart';
import '../../core/wallpapers.dart';
import '../shell.dart';
import '../wallpaper.dart';
import '../widgets.dart';
import '../liquid_surface.dart';
import '../ios_components.dart';
import '../onboarding.dart' show GameOverview, profileNameError;
import 'admin_app.dart';
import '../market/marketplace_app.dart';
import '../../core/market/market_strings.dart';

class _Item {
  final String page, titleKey;
  final IconData icon;
  final Color color;
  const _Item(this.page, this.titleKey, this.icon, this.color);
}

/// iPhone-style settings with sub-pages.
class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});
  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  String page = 'main';
  String query = '';
  late final TextEditingController keyCtrl;
  late final TextEditingController nameCtrl;

  double? _uiTmp; // slider value while dragging

  // wallpaper editing
  String _target = 'home'; // which wallpaper the appearance page edits
  WallpaperCfg? _draft; // photo being cropped
  bool _cropLock = false;
  Size _box = const Size(1, 1);
  double _s0 = 1;

  static final names = {'ru': 'Русский', 'en': 'English', 'uk': 'Українська'};

  static final _groups = <List<_Item>>[
    [
      const _Item('appearance', 'appearance', Icons.palette, Color(0xFF3B82F6)),
      const _Item(
        'display',
        'display',
        Icons.desktop_windows,
        Color(0xFF0EA5E9),
      ),
      const _Item(
        'notifications',
        'notifications',
        Icons.notifications,
        Color(0xFFEF4444),
      ),
      const _Item('sound', 'sound_vibe', Icons.volume_up, Color(0xFFEC4899)),
    ],
    [
      const _Item('language', 'language', Icons.language, Color(0xFF0EA5E9)),
      const _Item('ai', 'ai_network', Icons.cloud, Color(0xFF8B5CF6)),
      const _Item('data', 'data_saves', Icons.storage, Color(0xFF6B7280)),
    ],
    [
      const _Item('about', 'about', Icons.info, Color(0xFF6B7280)),
      const _Item(
        'admin',
        'admin_panel',
        Icons.admin_panel_settings,
        Color(0xFFDC2626),
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    keyCtrl = TextEditingController(text: gs.geminiKey);
    nameCtrl = TextEditingController(text: gs.playerName);
  }

  @override
  void dispose() {
    keyCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- helpers
  Widget _group(List<Widget> items, {String? footer}) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      rows.add(items[i]);
      if (i < items.length - 1) {
        rows.add(
          Divider(
            height: 1,
            indent: 58,
            color: IosColors.of(context).separator.withValues(alpha: .65),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(padding: EdgeInsets.zero, child: Column(children: rows)),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                footer,
                style: TextStyle(
                  color: IosColors.of(context).secondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, Color color) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );

  Widget _row(
    IconData icon,
    Color color,
    String title, {
    String? value,
    VoidCallback? onTap,
    bool chevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            _icon(icon, color),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(title, style: const TextStyle(fontSize: 15)),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: IosColors.of(context).secondary,
                    fontSize: 14,
                  ),
                ),
              ),
            if (chevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: IosColors.of(context).secondary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switch(
    IconData icon,
    Color color,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _icon(icon, color),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontSize: 15)),
          ),
          Switch.adaptive(
            key:
                title == 'Liquid Glass'
                    ? const ValueKey('liquid_glass_switch')
                    : null,
            value: value,
            onChanged: onChanged,
            activeTrackColor: IosColors.of(context).green,
          ),
        ],
      ),
    );
  }

  void _open(String p) => setState(() => page = p);
  void _toMain() => setState(() => page = 'main');
  void _toAppearance() => setState(() => page = 'appearance');

  // --------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final VoidCallback? onBack = page == 'main' ? null : _toMain;
    switch (page) {
      case 'profile':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'profile'.tr,
          onBack: onBack,
          child: _profile(gs),
        );
      case 'appearance':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'appearance'.tr,
          onBack: onBack,
          child: _appearance(gs),
        );
      case 'crop':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'wp_crop'.tr,
          onBack: _toAppearance,
          child: _crop(gs),
        );
      case 'display':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'display'.tr,
          onBack: onBack,
          child: _display(gs),
        );
      case 'notifications':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'notifications'.tr,
          onBack: onBack,
          child: _notifications(gs),
        );
      case 'sound':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'sound_vibe'.tr,
          onBack: onBack,
          child: _sound(gs),
        );
      case 'language':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'language'.tr,
          onBack: onBack,
          child: _language(gs),
        );
      case 'ai':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'ai_network'.tr,
          onBack: onBack,
          child: _ai(gs),
        );
      case 'data':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'data_saves'.tr,
          onBack: onBack,
          child: _data(gs),
        );
      case 'about':
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'about'.tr,
          onBack: onBack,
          child: _about(gs),
        );
      case 'admin':
        return AdminAuth.unlocked
            ? AdminPanel(onBack: _toMain)
            : AdminLogin(onBack: _toMain, onDone: () => setState(() {}));
      default:
        return AppPage(
          key: PageStorageKey('settings_$page'),
          title: 'settings'.tr,
          child: _main(gs),
        );
    }
  }

  Widget _main(GameState gs) {
    final q = query.trim().toLowerCase();
    final name = gs.playerName.isEmpty ? 'player'.tr : gs.playerName;
    return ListView(
      children: [
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'search'.tr,
            filled: true,
            fillColor: IosColors.of(context).surface,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (q.isEmpty)
          _group([
            InkWell(
              key: const ValueKey('settings_page_profile'),
              onTap: () => _open('profile'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ProfileAvatar(name: name, index: gs.avatarIndex),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            mt(
                              'Персонаж и личные данные',
                              'Character and profile',
                              'Персонаж і особисті дані',
                            ),
                            style: TextStyle(
                              color: IosColors.of(context).secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: IosColors.of(context).secondary,
                    ),
                  ],
                ),
              ),
            ),
          ]),
        for (final g in _groups)
          () {
            final shown =
                g
                    .where(
                      (i) =>
                          q.isEmpty || i.titleKey.tr.toLowerCase().contains(q),
                    )
                    .toList();
            if (shown.isEmpty) return const SizedBox.shrink();
            return _group([
              for (final i in shown)
                KeyedSubtree(
                  key: ValueKey('settings_page_${i.page}'),
                  child: _row(
                    i.icon,
                    i.color,
                    i.titleKey.tr,
                    value:
                        i.page == 'language'
                            ? names[gs.lang]
                            : (i.page == 'ai'
                                ? (gs.online ? 'online'.tr : 'offline'.tr)
                                : null),
                    onTap: () => _open(i.page),
                  ),
                ),
            ]);
          }(),
      ],
    );
  }

  Widget _profile(GameState gs) => ListView(
    children: [
      const SizedBox(height: 6),
      Center(
        child: ProfileAvatar(
          name: nameCtrl.text,
          index: gs.avatarIndex,
          size: 96,
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < profileColors.length; i++)
              Semantics(
                label: mt(
                  'Цвет аватара ${i + 1}',
                  'Avatar colour ${i + 1}',
                  'Колір аватара ${i + 1}',
                ),
                selected: gs.avatarIndex == i,
                child: GestureDetector(
                  onTap: () => gs.setAvatar(i),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: profileColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            gs.avatarIndex == i
                                ? IosColors.of(context).label
                                : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child:
                        gs.avatarIndex == i
                            ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                            : null,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      _group(
        [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'player_name'.tr,
                  style: TextStyle(
                    color: IosColors.of(context).secondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: mt(
                      'Имя персонажа',
                      'Character name',
                      'Ім’я персонажа',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        footer: mt(
          'Профиль хранится на этом устройстве вместе с прогрессом игры.',
          'Your profile is stored on this device with your game progress.',
          'Профіль зберігається на цьому пристрої разом із прогресом гри.',
        ),
      ),
      FilledButton(
        onPressed: () {
          final error = profileNameError(nameCtrl.text);
          if (error != null) {
            toast(context, error);
            return;
          }
          gs.setPlayerName(nameCtrl.text);
          toast(context, 'saved'.tr);
        },
        child: Text('save'.tr),
      ),
    ],
  );

  // ----------------------------------------------------------- appearance
  Future<void> _pickPhoto(bool lock) async {
    try {
      final f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 85,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width, h = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      if (!mounted) return;
      final d = WallpaperCfg();
      d.bytes = bytes;
      d.iw = w;
      d.ih = h;
      setState(() {
        _draft = d;
        _cropLock = lock;
        page = 'crop';
      });
    } catch (e) {
      AppLog.I.error('app', 'не удалось загрузить фото для обоев: $e');
      if (mounted) toast(context, 'photo_failed'.tr);
    }
  }

  void _adjust(WallpaperCfg cur, bool lock) {
    final d = WallpaperCfg();
    d.copyFrom(cur);
    setState(() {
      _draft = d;
      _cropLock = lock;
      page = 'crop';
    });
  }

  Widget _glassPreview(GameState gs) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        key: const ValueKey('glass_live_preview'),
        height: 170,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF508BFF), Color(0xFFB095FF), Color(0xFF64DBC7)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -10,
              top: 20,
              child: Transform.rotate(
                angle: -.6,
                child: Container(
                  width: 260,
                  height: 38,
                  color: Colors.white.withValues(alpha: .55),
                ),
              ),
            ),
            Positioned(
              right: -25,
              bottom: -35,
              child: Container(
                width: 165,
                height: 165,
                decoration: const BoxDecoration(
                  color: Color(0xFF6651D8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: LiquidSurface(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        gs.liquidGlass
                            ? Icons.blur_on_rounded
                            : Icons.layers_rounded,
                        size: 29,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Liquid Glass',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              gs.liquidGlass
                                  ? mt('Включён', 'On', 'Увімкнено')
                                  : mt('Выключен', 'Off', 'Вимкнено'),
                              style: TextStyle(
                                color: IosColors.of(context).secondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _appearance(GameState gs) {
    final g = context.read<GameState>();
    final lockFlag = _target == 'lock' && gs.lockSeparate;
    final cfg = lockFlag ? gs.lockWp : gs.homeWp;
    final ratio = Shell.phoneSize.width / Shell.phoneSize.height;
    return ListView(
      children: [
        Text(
          'theme'.tr,
          style: TextStyle(
            color: IosColors.of(context).secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: Semantics(
                    selected: gs.themeMode == i,
                    button: true,
                    child: InkWell(
                      onTap: () => g.setThemeMode(i),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: IosColors.of(context).surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                gs.themeMode == i
                                    ? IosColors.of(context).blue
                                    : IosColors.of(context).separator,
                            width: gs.themeMode == i ? 2 : .7,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              [
                                Icons.brightness_auto_rounded,
                                Icons.light_mode_rounded,
                                Icons.dark_mode_rounded,
                              ][i],
                              size: 25,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              [
                                'theme_system'.tr,
                                'theme_light'.tr,
                                'theme_dark'.tr,
                              ][i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _group(
          [
            _switch(
              Icons.blur_on_rounded,
              const Color(0xFF8052E9),
              'Liquid Glass',
              gs.liquidGlass,
              g.setLiquidGlass,
            ),
          ],
          footer: mt(
            'Меняет панели приложений, док и уведомления. Без эффекта панели непрозрачные, размытие отключено.',
            'Changes app panels, the dock and notifications. When off, surfaces are opaque and blur is disabled.',
            'Змінює панелі застосунків, док і сповіщення. Без ефекту панелі непрозорі, розмиття вимкнене.',
          ),
        ),
        _glassPreview(gs),
        const SizedBox(height: 18),
        Text(
          'wallpaper'.tr,
          style: TextStyle(
            color: IosColors.of(context).secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        _group([
          _switch(
            Icons.lock,
            const Color(0xFF6B7280),
            'wp_lock_sep'.tr,
            gs.lockSeparate,
            (v) {
              g.setLockSeparate(v);
              if (!v) setState(() => _target = 'home');
            },
          ),
        ]),
        if (gs.lockSeparate)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'home', label: Text('wp_home'.tr)),
                  ButtonSegment(value: 'lock', label: Text('wp_lock'.tr)),
                ],
                selected: {_target},
                onSelectionChanged: (s) => setState(() => _target = s.first),
              ),
            ),
          ),
        ThemeFilter(
          light: false,
          child: Center(
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: AspectRatio(
                aspectRatio: ratio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: WallpaperView(cfg: cfg, dim: gs.wallpaperDim),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ThemeFilter(
          light: false,
          child: SizedBox(
            height: 144,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bundledWallpapers.length,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final asset = bundledWallpapers.keys.elementAt(index);
                final selected = cfg.asset == asset && !cfg.hasImage;
                return GestureDetector(
                  key: ValueKey('wallpaper_asset_$index'),
                  onTap: () => g.setWallpaperAsset(asset, lock: lockFlag),
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 112,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: selected ? C.accent : Colors.white24,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(asset, fit: BoxFit.cover),
                                if (selected)
                                  const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          bundledWallpapers[asset]!.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        ThemeFilter(
          light: false,
          child: SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wallpaperPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final sel =
                    !cfg.hasImage && cfg.asset == null && cfg.preset == i;
                return GestureDetector(
                  onTap: () => g.setWallpaperPreset(i, lock: lockFlag),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: wallpaperPresets[i],
                          ),
                          border: Border.all(
                            color: sel ? C.accent : Colors.white24,
                            width: sel ? 3 : 1,
                          ),
                        ),
                        child:
                            sel
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 66,
                        child: Text(
                          wallpaperKeys[i].tr,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _pickPhoto(lockFlag),
              icon: const Icon(Icons.photo_library),
              label: Text('wp_choose_photo'.tr),
            ),
            if (cfg.hasImage)
              OutlinedButton.icon(
                onPressed: () => _adjust(cfg, lockFlag),
                icon: const Icon(Icons.crop),
                label: Text('wp_adjust'.tr),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _group([
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('wp_dim'.tr),
                Slider(
                  value: gs.wallpaperDim,
                  min: 0,
                  max: 0.6,
                  onChanged: (v) => g.setWallpaperDim(v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('text_size'.tr),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<double>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 0.9, label: Text('size_small'.tr)),
                      ButtonSegment(value: 1.0, label: Text('size_normal'.tr)),
                      ButtonSegment(value: 1.15, label: Text('size_large'.tr)),
                    ],
                    selected: {gs.textScale},
                    onSelectionChanged: (s) => g.setTextScale(s.first),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  // ------------------------------------------------------------- crop editor
  Widget _crop(GameState gs) {
    final d = _draft;
    if (d == null) return Empty('empty'.tr);
    final ratio = Shell.phoneSize.width / Shell.phoneSize.height;
    void zoomBy(double f) {
      setState(() {
        d.scale = (d.scale * f).clamp(1.0, 5.0).toDouble();
        d.clampTo(_box.width, _box.height);
      });
    }

    return Column(
      children: [
        Text(
          'wp_drag_hint'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: IosColors.of(context).secondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: ratio,
              child: LayoutBuilder(
                builder: (context, c) {
                  _box = Size(c.maxWidth, c.maxHeight);
                  return Listener(
                    onPointerSignal: (e) {
                      if (e is PointerScrollEvent) {
                        zoomBy(e.scrollDelta.dy > 0 ? 0.93 : 1.07);
                      }
                    },
                    child: GestureDetector(
                      onScaleStart: (_) => _s0 = d.scale,
                      onScaleUpdate: (u) {
                        setState(() {
                          d.scale = (_s0 * u.scale).clamp(1.0, 5.0).toDouble();
                          d.ox += u.focalPointDelta.dx / _box.width;
                          d.oy += u.focalPointDelta.dy / _box.height;
                          d.clampTo(_box.width, _box.height);
                        });
                      },
                      child: ThemeFilter(
                        light: false,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white54, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: WallpaperView(cfg: d, dim: gs.wallpaperDim),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Row(
          children: [
            Icon(Icons.zoom_out, color: IosColors.of(context).secondary),
            Expanded(
              child: Slider(
                value: d.scale.clamp(1.0, 5.0).toDouble(),
                min: 1,
                max: 5,
                onChanged:
                    (v) => setState(() {
                      d.scale = v;
                      d.clampTo(_box.width, _box.height);
                    }),
              ),
            ),
            Icon(Icons.zoom_in, color: IosColors.of(context).secondary),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    () => setState(() {
                      d.scale = 1;
                      d.ox = 0;
                      d.oy = 0;
                    }),
                child: Text('wp_reset'.tr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  d.clampTo(_box.width, _box.height);
                  context.read<GameState>().setWallpaperImage(
                    d.bytes!,
                    d.iw,
                    d.ih,
                    d.scale,
                    d.ox,
                    d.oy,
                    lock: _cropLock,
                  );
                  toast(context, 'saved'.tr);
                  _toAppearance();
                },
                child: Text('wp_apply'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------- the rest
  Widget _choice(List<String> labels, int selected, ValueChanged<int> onSel) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: selected == i,
            onSelected: (_) => onSel(i),
          ),
      ],
    );
  }

  Widget _display(GameState gs) {
    const sizes = [
      [1024, 768],
      [1280, 720],
      [1366, 768],
      [1600, 900],
      [1920, 1080],
    ];
    final g = context.read<GameState>();
    final ui = _uiTmp ?? gs.uiScalePct.toDouble();
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: TextStyle(
          color: IosColors.of(context).secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return ListView(
      children: [
        title('layout_mode'.tr),
        _choice(
          ['layout_auto'.tr, 'layout_phone'.tr, 'layout_tablet'.tr],
          gs.layoutMode,
          g.setLayoutMode,
        ),
        const SizedBox(height: 6),
        Text(
          'layout_hint'.tr,
          style: TextStyle(
            color: IosColors.of(context).secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 18),
        title('${'ui_scale'.tr}: ${ui.round()}%'),
        Slider(
          value: ui.clamp(70.0, 160.0).toDouble(),
          min: 70,
          max: 160,
          divisions: 18,
          label: '${ui.round()}%',
          onChanged: (v) => setState(() => _uiTmp = v),
          onChangeEnd: (v) {
            g.setUiScale(v.round());
            setState(() => _uiTmp = null);
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => g.setUiScale(100),
            child: Text('reset_100'.tr),
          ),
        ),
        const SizedBox(height: 12),
        if (WinService.isDesktop) ...[
          _group([
            _switch(
              Icons.fullscreen,
              const Color(0xFF8B5CF6),
              'fullscreen'.tr,
              gs.fullscreen,
              (v) => g.setFullscreen(v),
            ),
          ], footer: 'fullscreen_hint'.tr),
          title('window_size'.tr),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final z in sizes)
                ChoiceChip(
                  label: Text('${z[0]} × ${z[1]}'),
                  selected:
                      !gs.fullscreen && gs.winW == z[0] && gs.winH == z[1],
                  onSelected: (_) => g.setWindowSize(z[0], z[1]),
                ),
              ActionChip(
                avatar: const Icon(Icons.open_in_full, size: 16),
                label: Text('maximize'.tr),
                onPressed: () => WinService.maximize(),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              'desktop_only_hint'.tr,
              style: TextStyle(
                color: IosColors.of(context).secondary,
                fontSize: 12,
              ),
            ),
          ),
        title('map_style'.tr),
        _choice(
          [
            'style_auto'.tr,
            'style_streets'.tr,
            'style_sat'.tr,
            'style_offline'.tr,
          ],
          gs.mapStyle,
          g.setMapStyle,
        ),
        const SizedBox(height: 6),
        Text(
          'map_style_hint'.tr,
          style: TextStyle(
            color: IosColors.of(context).secondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _notifications(GameState gs) {
    final g = context.read<GameState>();
    return ListView(
      children: [
        _group([
          _switch(
            Icons.build,
            C.orange,
            'notif_orders'.tr,
            gs.notifOrders,
            g.setNotifOrders,
          ),
          _switch(
            Icons.chat_bubble,
            IosColors.of(context).green,
            'notif_deals'.tr,
            gs.notifDeals,
            g.setNotifDeals,
          ),
        ]),
        OutlinedButton.icon(
          onPressed:
              () => toast(
                context,
                mt(
                  'Так выглядят системные сообщения TechLife.',
                  'This is a TechLife system notification.',
                  'Такий вигляд мають системні сповіщення TechLife.',
                ),
              ),
          icon: const Icon(Icons.notifications_none_rounded),
          label: Text(
            mt('Показать пример', 'Show preview', 'Показати приклад'),
          ),
        ),
      ],
    );
  }

  Widget _sound(GameState gs) {
    final g = context.read<GameState>();
    return ListView(
      children: [
        _group([
          _switch(
            Icons.vibration,
            const Color(0xFFEC4899),
            'haptics'.tr,
            gs.haptics,
            g.setHaptics,
          ),
        ]),
      ],
    );
  }

  Widget _language(GameState gs) {
    return ListView(
      children: [
        _group([
          for (final l in I18n.langs)
            InkWell(
              onTap: () => context.read<GameState>().setLang(l),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        names[l]!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    if (gs.lang == l) const Icon(Icons.check, color: C.accent),
                  ],
                ),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _ai(GameState gs) {
    if (!AdminAuth.unlocked) {
      return ListView(
        children: [
          const Icon(Icons.auto_awesome, color: C.accent, size: 42),
          const SizedBox(height: 16),
          Text(
            mt(
              'Игровой ИИ подключён автоматически. Настройка ключей и модели не требуется.',
              'Game AI connects automatically. No API key or model setup is needed.',
              'Ігровий ШІ підключається автоматично. Налаштування ключа й моделі не потрібне.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final r = await gs.adminTestAi();
              if (mounted) {
                toast(
                  context,
                  r.ok
                      ? mt(
                        'Подключение работает',
                        'Connection successful',
                        'Підключення працює',
                      )
                      : mt(
                        'Сервис временно недоступен',
                        'Service temporarily unavailable',
                        'Сервіс тимчасово недоступний',
                      ),
                );
              }
            },
            child: Text(mt('Проверить ИИ', 'Check AI', 'Перевірити ШІ')),
          ),
        ],
      );
    }
    return ListView(
      children: [
        _group([
          _row(
            gs.online ? Icons.wifi : Icons.wifi_off,
            gs.online ? IosColors.of(context).green : C.red,
            gs.online ? 'online'.tr : 'no_internet'.tr,
            chevron: false,
          ),
          _row(
            Icons.vpn_key,
            const Color(0xFF8B5CF6),
            'builtin_key'.tr,
            value: gs.hasBuiltInKey ? 'has'.tr : 'hasnt'.tr,
            chevron: false,
          ),
          _row(
            Icons.key,
            const Color(0xFF6366F1),
            'key_type'.tr,
            value: AiService.keyKind(gs.aiKey),
            chevron: false,
          ),
        ], footer: gs.online ? null : 'ai_needs_net'.tr),
        OutlinedButton.icon(
          onPressed:
              () => showDialog<void>(
                context: context,
                builder: (c) => GeminiSetupDialog(gs: gs),
              ),
          icon: const Icon(Icons.auto_awesome),
          label: Text(
            mt(
              'Модель Gemini и проверка подключения',
              'Gemini model and connection test',
              'Модель Gemini й перевірка підключення',
            ),
          ),
        ),
        Text(
          'gemini_key'.tr,
          style: TextStyle(
            color: IosColors.of(context).secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: keyCtrl,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'AIza… / AQ.…',
            filled: true,
            fillColor: IosColors.of(context).surface,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${'key_hint'.tr} ${'ai_hint_own'.tr}',
          style: TextStyle(
            color: IosColors.of(context).secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () {
              context.read<GameState>().setKey(keyCtrl.text);
              toast(context, 'saved'.tr);
            },
            child: Text('save'.tr),
          ),
        ),
      ],
    );
  }

  Widget _data(GameState gs) {
    return ListView(
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: C.red),
          icon: const Icon(Icons.delete_outline),
          label: Text('reset'.tr),
          onPressed: () async {
            final g = context.read<GameState>();
            final ok = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: Text('reset_q'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('ok'.tr),
                      ),
                    ],
                  ),
            );
            if (ok == true) await g.resetAll();
          },
        ),
      ],
    );
  }

  Widget _about(GameState gs) {
    return ListView(
      children: [
        const GameOverview(),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            children: [
              ThemeFilter(
                light: false,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 96,
                    height: 96,
                    errorBuilder:
                        (_, __, ___) => const SizedBox(width: 96, height: 96),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                kAppName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'about_text'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: IosColors.of(context).secondary),
              ),
              const SizedBox(height: 6),
              Text(
                'v$kAppVersion',
                style: TextStyle(
                  color: IosColors.of(context).secondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed:
                    () => showDialog<void>(
                      context: context,
                      builder:
                          (c) => AlertDialog(
                            title: Text(
                              mt(
                                'Источники изображений',
                                'Image credits',
                                'Джерела зображень',
                              ),
                            ),
                            content: SizedBox(
                              width: 600,
                              child: SingleChildScrollView(
                                child: FutureBuilder<String>(
                                  future: rootBundle.loadString(
                                    'assets/repair/SOURCES.txt',
                                  ),
                                  builder:
                                      (_, s) => SelectableText(
                                        s.data ?? '…',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    ),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(
                  mt(
                    'Источники изображений',
                    'Image credits',
                    'Джерела зображень',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
