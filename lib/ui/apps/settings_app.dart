import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});
  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  late final TextEditingController keyCtrl;

  @override
  void initState() {
    super.initState();
    keyCtrl = TextEditingController(text: context.read<GameState>().geminiKey);
  }

  @override
  void dispose() {
    keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    const names = {'ru': 'Русский', 'en': 'English', 'uk': 'Українська'};
    return AppPage(
      title: 'settings'.tr,
      child: ListView(
        children: [
          Text('language'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final l in I18n.langs)
                  ListTile(
                    dense: true,
                    title: Text(names[l]!),
                    trailing: gs.lang == l ? const Icon(Icons.check, color: C.green) : null,
                    onTap: () => context.read<GameState>().setLang(l),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          Text('key_hint'.tr, style: const TextStyle(color: C.sub, fontSize: 12)),
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 20),
          Text('about'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('about_text'.tr, style: const TextStyle(color: C.sub, fontSize: 12)),
        ],
      ),
    );
  }
}
