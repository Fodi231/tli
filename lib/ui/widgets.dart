import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import 'shell.dart';
import 'liquid_surface.dart';
import 'ios_components.dart';
import 'system_notice.dart';

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
  final host = SystemNoticeHost.maybeOf(c);
  if (host != null) {
    host.show(msg);
    return;
  }
  // Standalone embedded screens still get a readable, rounded fallback.
  final messenger = ScaffoldMessenger.maybeOf(c);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      key: const ValueKey('system_toast'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      content: SystemNoticeBanner(
        message: msg,
        onClose: () => messenger.hideCurrentSnackBar(),
      ),
      duration: const Duration(seconds: 5),
    ),
  );
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
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => LiquidSurface(
    radius: 24,
    padding: EdgeInsets.zero,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    ),
  );
}

class AppPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool wide;
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.wide = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = IosColors.of(context);
    return IosBackdrop(
      child: Material(
        type: MaterialType.transparency,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 5),
              child: Row(
                children: [
                  LiquidSurface(
                    radius: 24,
                    padding: EdgeInsets.zero,
                    child: IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: p.blue,
                        size: 27,
                      ),
                      onPressed: onBack ?? () => context.read<Shell>().close(),
                    ),
                  ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 3, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const ValueKey('ios_app_title'),
                    style: TextStyle(
                      color: p.label,
                      fontSize: 30,
                      height: 1.12,
                      letterSpacing: -.85,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: p.secondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child:
                    wide
                        ? child
                        : Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 850),
                            child: child,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  final List<String> ids;
  final String selected;
  final String Function(String) label;
  final ValueChanged<String> onSelect;
  const ChipRow({
    super.key,
    required this.ids,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(14) + 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(id)),
                selected: id == selected,
                showCheckmark: false,
                selectedColor: IosColors.of(
                  context,
                ).blue.withValues(alpha: .14),
                backgroundColor: IosColors.of(context).surface,
                side: BorderSide(
                  color: IosColors.of(context).separator.withValues(alpha: .6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 44,
            color: IosColors.of(context).secondary,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IosColors.of(context).secondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
