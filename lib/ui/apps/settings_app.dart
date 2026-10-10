import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/wallpapers.dart';
import '../wallpaper.dart';
import '../widgets.dart';

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

  static const names = {'ru': 'Русский', 'en': 'English', 'uk': 'Українська'};

  static const _groups = <List<_Item>>[
    [
      _Item('appearance', 'appearance', Icons.palette, Color(0xFF3B82F6)),
      _Item('notifications', 'notifications', Icons.notifications, Color(0xFFEF4444)),
      _Item('sound', 'sound_vibe', Icons.volume_up, Color(0xFFEC4899)),
    ],
    [
      _Item('language', 'language', Icons.language, Color(0xFF0EA5E9)),
      _Item('ai', 'ai_network', Icons.cloud, Color(0xFF8B5CF6)),
      _Item('data', 'data_saves', Icons.storage, Color(0xFF6B7280)),
    ],
    [
      _Item('about', 'about', Icons.info, Color(0xFF6B7280)),
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
      if (i < items.length - 1) rows.add(const Divider(height: 1, indent: 52, color: Colors.white12));
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
              child: Text(footer, style: const TextStyle(color: C.sub, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, Color color) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 18),
      );

  Widget _row(IconData icon, Color color, String title, {String? value, VoidCallback? onTap, bool chevron = true}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            _icon(icon, color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
            if (value != null) Text(value, style: const TextStyle(color: C.sub, fontSize: 14)),
            if (chevron) ...[const SizedBox(width: 4), const Icon(Icons.chevron_right, color: C.sub, size: 20)],
          ],
        ),
      ),
    );
  }

  Widget _switch(IconData icon, Color color, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _icon(icon, color),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: C.green),
        ],
      ),
    );
  }

  void _open(String p) => setState(() => page = p);

  // --------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final onBack = page == 'main' ? null : () => setState(() => page = 'main');
    switch (page) {
      case 'profile':
        return AppPage(title: 'profile'.tr, onBack: onBack, child: _profile(gs));
      case 'appearance':
        return AppPage(title: 'appearance'.tr, onBack: onBack, child: _appearance(gs));
      case 'notifications':
        return AppPage(title: 'notifications'.tr, onBack: onBack, child: _notifications(gs));
      case 'sound':
        return AppPage(title: 'sound_vibe'.tr, onBack: onBack, child: _sound(gs));
      case 'language':
        return AppPage(title: 'language'.tr, onBack: onBack, child: _language(gs));
      case 'ai':
        return AppPage(title: 'ai_network'.tr, onBack: onBack, child: _ai(gs));
      case 'data':
        return AppPage(title: 'data_saves'.tr, onBack: onBack, child: _data(gs));
      case 'about':
        return AppPage(title: 'about'.tr, onBack: onBack, child: _about());
      default:
        return AppPage(title: 'settings'.tr, child: _main(gs));
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
            fillColor: C.card,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
        if (q.isEmpty)
          _group([
            InkWell(
              onTap: () => _open('profile'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(radius: 26, backgroundColor: C.accent, child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 22))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('profile'.tr, style: const TextStyle(color: C.sub, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: C.sub),
                  ],
                ),
              ),
            ),
          ]),
        for (final g in _groups)
          () {
            final shown = g.where((i) => q.isEmpty || i.titleKey.tr.toLowerCase().contains(q)).toList();
            if (shown.isEmpty) return const SizedBox.shrink();
            return _group([
              for (final i in shown)
                _row(
                  i.icon,
                  i.color,
                  i.titleKey.tr,
                  value: i.page == 'language'
                      ? names[gs.lang]
                      : (i.page == 'ai' ? (gs.online ? 'online'.tr : 'offline'.tr) : null),
                  onTap: () => _open(i.page),
                ),
            ]);
          }(),
      ],
    );
  }

  Widget _profile(GameState gs) {
    return ListView(
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: C.accent,
            child: Text((gs.playerName.isEmpty ? 'player'.tr : gs.playerName)[0].toUpperCase(), style: const TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: 20),
        Text('player_name'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: nameCtrl,
          maxLength: 20,
          decoration: InputDecoration(
            filled: true,
            fillColor: C.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () {
              context.read<GameState>().setPlayerName(nameCtrl.text);
              toast(context, 'saved'.tr);
            },
            child: Text('save'.tr),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final g = context.read<GameState>();
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, maxHeight: 1920, imageQuality: 75);
      if (f == null) return;
      g.setWallpaperImage(await f.readAsBytes());
    } catch (_) {
      if (mounted) toast(context, 'photo_failed'.tr);
    }
  }

  Widget _appearance(GameState gs) {
    final usingPhoto = gs.wallpaperBytes != null;
    return ListView(
      children: [
        Center(
          child: Container(
            width: 130,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: WallpaperView(index: gs.wallpaperIndex, bytes: gs.wallpaperBytes, dim: gs.wallpaperDim),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('wallpaper'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallpaperPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final sel = !usingPhoto && gs.wallpaperIndex == i;
              return GestureDetector(
                onTap: () => context.read<GameState>().setWallpaperPreset(i),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: wallpaperPresets[i]),
                        border: Border.all(color: sel ? C.accent : Colors.white24, width: sel ? 3 : 1),
                      ),
                      child: sel ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: Text(wallpaperKeys[i].tr, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: C.sub)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_library),
            label: Text('wp_choose_photo'.tr),
          ),
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
                  onChanged: (v) => context.read<GameState>().setWallpaperDim(v),
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
                    onSelectionChanged: (s) => context.read<GameState>().setTextScale(s.first),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _notifications(GameState gs) {
    final g = context.read<GameState>();
    return ListView(children: [
      _group([
        _switch(Icons.build, C.orange, 'notif_orders'.tr, gs.notifOrders, g.setNotifOrders),
        _switch(Icons.chat_bubble, C.green, 'notif_deals'.tr, gs.notifDeals, g.setNotifDeals),
      ]),
    ]);
  }

  Widget _sound(GameState gs) {
    final g = context.read<GameState>();
    return ListView(children: [
      _group([_switch(Icons.vibration, const Color(0xFFEC4899), 'haptics'.tr, gs.haptics, g.setHaptics)]),
    ]);
  }

  Widget _language(GameState gs) {
    return ListView(children: [
      _group([
        for (final l in I18n.langs)
          InkWell(
            onTap: () => context.read<GameState>().setLang(l),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Expanded(child: Text(names[l]!, style: const TextStyle(fontSize: 15))),
                if (gs.lang == l) const Icon(Icons.check, color: C.accent),
              ]),
            ),
          ),
      ]),
    ]);
  }

  Widget _ai(GameState gs) {
    return ListView(children: [
      _group([
        _row(gs.online ? Icons.wifi : Icons.wifi_off, gs.online ? C.green : C.red, gs.online ? 'online'.tr : 'no_internet'.tr, chevron: false),
        _row(Icons.vpn_key, const Color(0xFF8B5CF6), 'builtin_key'.tr, value: gs.hasBuiltInKey ? 'has'.tr : 'hasnt'.tr, chevron: false),
      ], footer: gs.online ? null : 'ai_needs_net'.tr),
      Text('gemini_key'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: keyCtrl,
        obscureText: true,
        decoration: InputDecoration(
          hintText: 'AIza…',
          filled: true,
          fillColor: C.card,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 6),
      Text('${'key_hint'.tr} ${'ai_hint_own'.tr}', style: const TextStyle(color: C.sub, fontSize: 12)),
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
    ]);
  }

  Widget _data(GameState gs) {
    return ListView(children: [
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: C.red),
        icon: const Icon(Icons.delete_outline),
        label: Text('reset'.tr),
        onPressed: () async {
          final g = context.read<GameState>();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('reset_q'.tr),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('ok'.tr)),
              ],
            ),
          );
          if (ok == true) await g.resetAll();
        },
      ),
    ]);
  }

  Widget _about() {
    return ListView(children: [
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TechLife', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('about_text'.tr, style: const TextStyle(color: C.sub)),
            const SizedBox(height: 6),
            const Text('v0.2.0', style: TextStyle(color: C.sub, fontSize: 12)),
          ],
        ),
      ),
    ]);
  }
}
