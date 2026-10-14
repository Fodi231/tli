import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import 'shell.dart';

String money(num v) {
  final s = v.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}\$$b';
}

void toast(BuildContext c, String msg) {
  final m = ScaffoldMessenger.of(c);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
  ));
}

IconData serviceIcon(String s) {
  switch (s) {
    case 'display':
      return Icons.smartphone;
    case 'battery':
      return Icons.battery_charging_full;
    case 'port':
      return Icons.usb;
    case 'camera':
      return Icons.photo_camera;
    default:
      return Icons.search;
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.onTap});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

class AppPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;

  /// true = use the whole width on tablets / PC (map, messages); otherwise the
  /// content is centred in a readable column.
  final bool wide;
  const AppPage({super.key, required this.title, required this.child, this.actions = const [], this.onBack, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.bg.withValues(alpha: 0.96),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: onBack ?? () => context.read<Shell>().close(),
                ),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: wide
                  ? child
                  : Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: child),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  final List<String> ids;
  final String selected;
  final String Function(String) label;
  final ValueChanged<String> onSelect;
  const ChipRow({super.key, required this.ids, required this.selected, required this.label, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(id)),
                selected: id == selected,
                onSelected: (_) => onSelect(id),
              ),
            ),
        ],
      ),
    );
  }
}

class Empty extends StatelessWidget {
  final String text;
  const Empty(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(text, style: const TextStyle(color: C.sub)));
}
