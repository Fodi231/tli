import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/market/device_catalog.dart';
import '../../core/market/market_strings.dart';
import '../widgets.dart' show money;

const marketBlue = Color(0xFF008E95);
const marketGray = Color(0xFFF0F3F5);
const marketText = Color(0xFF101521);
const marketMuted = Color(0xFF7D8794);
const marketMint = Color(0xFFE3F6F2);
const marketDeep = Color(0xFF00424A);

ThemeData marketTheme() => ThemeData.light(useMaterial3: true).copyWith(
  scaffoldBackgroundColor: Colors.transparent,
  colorScheme: const ColorScheme.light(
    primary: marketBlue,
    secondary: marketDeep,
    surface: Color(0xFFFDFEFE),
    onSurface: marketText,
  ),
  textTheme: ThemeData.light(useMaterial3: true).textTheme.apply(
    fontFamily: 'Roboto',
    bodyColor: marketText,
    displayColor: marketText,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF5F8F9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    hintStyle: const TextStyle(color: marketMuted, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE4EAED)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE4EAED)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: marketBlue, width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: marketBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: marketDeep,
      side: const BorderSide(color: Color(0xFFADD8D7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE9EFF0), thickness: 1),
);

class MarketBackground extends StatelessWidget {
  final Widget child;
  const MarketBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF2FAF9), Colors.white, Color(0xFFF0F8F8)],
        stops: [0, .46, 1],
      ),
    ),
    child: child,
  );
}

class MarketSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool shadow;
  const MarketSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.shadow = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xEEFFFFFF), Color(0xBBF4FAFA)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE5ECEE)),
      boxShadow:
          shadow
              ? const [
                BoxShadow(
                  color: Color(0x0C336D73),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ]
              : null,
    ),
    child: child,
  );
}

class MarketPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const MarketPill(
    this.label, {
    super.key,
    this.selected = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient:
            selected
                ? const LinearGradient(
                  colors: [Color(0xFF00A6AC), Color(0xFF007F88)],
                )
                : null,
        color: selected ? null : const Color(0xCCF6FAFA),
        border: Border.all(
          color: selected ? const Color(0xFF1BAEB1) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: selected ? const Color(0x18008E95) : const Color(0x083C6770),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : marketText,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class MarketPills extends StatelessWidget {
  final List<Widget> children;
  const MarketPills({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    ),
  );
}

class MarketHeading extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const MarketHeading(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: marketMuted,
              height: 1.35,
            ),
          ),
        ],
      ],
    ),
  );
}

class MarketTag extends StatelessWidget {
  final String text;
  final bool repair;
  const MarketTag(this.text, {super.key, this.repair = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: repair ? const Color(0xFFFFD8B8) : const Color(0xFFCEF6E5),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, color: marketText),
    ),
  );
}

class DevicePhoto extends StatelessWidget {
  final String device;
  final BoxFit fit;
  const DevicePhoto(this.device, {super.key, this.fit = BoxFit.contain});
  @override
  Widget build(BuildContext context) {
    final d = deviceFor(device);
    return ColoredBox(
      color: marketGray,
      child:
          d == null
              ? const Center(
                child: Icon(
                  Icons.devices_rounded,
                  color: marketMuted,
                  size: 40,
                ),
              )
              : Image.asset(
                d.photo,
                fit: fit,
                errorBuilder:
                    (_, error, stack) => const Center(
                      child: Icon(
                        Icons.smartphone,
                        color: marketMuted,
                        size: 40,
                      ),
                    ),
              ),
    );
  }
}

class ListingPhoto extends StatelessWidget {
  final String source, device;
  final BoxFit fit;
  const ListingPhoto(
    this.source, {
    super.key,
    required this.device,
    this.fit = BoxFit.cover,
  });
  @override
  Widget build(BuildContext context) {
    if (source.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(source.substring(source.indexOf(',') + 1)),
          fit: fit,
          errorBuilder: (_, error, stack) => DevicePhoto(device),
        );
      } catch (_) {
        return DevicePhoto(device);
      }
    }
    return DevicePhoto(device, fit: BoxFit.contain);
  }
}

class MarketAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool master;
  const MarketAvatar(
    this.name, {
    super.key,
    this.size = 44,
    this.master = false,
  });
  @override
  Widget build(BuildContext context) {
    final photo =
        master
            ? null
            : switch (name) {
              'Алексей' => 'alex',
              'Мария' => 'maria',
              'Денис' => 'denis',
              _ => null,
            };
    if (photo != null) {
      return ClipOval(
        child: Image.asset(
          'assets/market/avatar_$photo.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final letters =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s[0])
            .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              master
                  ? [const Color(0xFF80E9D9), marketBlue, marketDeep]
                  : [const Color(0xFFE3F5EF), const Color(0xFFC7E9E5)],
        ),
      ),
      alignment: Alignment.center,
      child:
          master
              ? Icon(
                Icons.handyman_outlined,
                color: Colors.white,
                size: size * .4,
              )
              : Text(
                letters.isEmpty ? '?' : letters,
                style: TextStyle(
                  fontSize: size * .31,
                  fontWeight: FontWeight.w600,
                  color: marketDeep,
                ),
              ),
    );
  }
}

class MarketEmpty extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? action;
  final VoidCallback? onAction;
  const MarketEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: marketMint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: marketBlue, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: marketMuted, height: 1.4),
        ),
        if (action != null) ...[
          const SizedBox(height: 18),
          OutlinedButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

class MarketBrandMark extends StatelessWidget {
  final double size;
  const MarketBrandMark({super.key, this.size = 35});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size * 1.1), painter: _BagPainter());
}

class _BagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 36, size.height / 40);
    final teal = Paint()..color = marketBlue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 10, 32, 29),
        const Radius.circular(6),
      ),
      teal,
    );
    final line =
        Paint()
          ..color = marketBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(10, 1, 16, 20), 3.14, 3.14, false, line);
    line
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawPath(
      Path()
        ..moveTo(12, 39)
        ..lineTo(12, 29)
        ..lineTo(8, 25)
        ..lineTo(8, 22),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(19, 39)
        ..lineTo(19, 22)
        ..lineTo(23, 18),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(19, 30)
        ..lineTo(27, 30),
      line,
    );
    for (final o in [
      const Offset(8, 20),
      const Offset(24, 17),
      const Offset(29, 30),
    ]) {
      canvas.drawCircle(o, 2, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MarketHeader extends StatelessWidget {
  final double balance;
  final VoidCallback onHome, onWallet;
  const MarketHeader({
    super.key,
    required this.balance,
    required this.onHome,
    required this.onWallet,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 355;
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        child: Row(
          children: [
            Tooltip(
              message: mt(
                'На главный экран',
                'Home screen',
                'На головний екран',
              ),
              child: InkWell(
                onTap: onHome,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 6, 4),
                  child: MarketBrandMark(size: compact ? 28 : 33),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mt('ТехМаркет', 'TechMarket', 'ТехМаркет'),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: compact ? 19 : 22,
                      letterSpacing: -.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!compact &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.25)
                    Text(
                      mt(
                        'Покупай. Ремонтируй. Продавай.',
                        'Buy. Repair. Resell.',
                        'Купуй. Ремонтуй. Продавай.',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: marketMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Material(
              color: marketMint.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: const ValueKey('market_wallet'),
                onTap: onWallet,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 12,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: compact ? 18 : 21,
                        color: marketDeep,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        money(balance),
                        style: TextStyle(
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class MarketBottomBar extends StatelessWidget {
  final int index, unread;
  final ValueChanged<int> onChanged;
  const MarketBottomBar({
    super.key,
    required this.index,
    required this.unread,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final labels = [
      mt('Каталог', 'Catalog', 'Каталог'),
      mt('Избранное', 'Saved', 'Обране'),
      mt('Продать', 'Sell', 'Продати'),
      mt('Сообщения', 'Messages', 'Повідомлення'),
      mt('Профиль', 'Profile', 'Профіль'),
    ];
    const icons = [
      Icons.home_outlined,
      Icons.favorite_border,
      Icons.add,
      Icons.chat_bubble_outline,
      Icons.person_outline,
    ];
    const active = [
      Icons.home_rounded,
      Icons.favorite,
      Icons.add,
      Icons.chat_bubble_rounded,
      Icons.person,
    ];
    final scaled = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(31),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xDDF3FAF9),
                    borderRadius: BorderRadius.circular(31),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Expanded(
                          child: Semantics(
                            selected: index == i,
                            button: true,
                            excludeSemantics: i == 2,
                            child: InkWell(
                              key: ValueKey(
                                i == 2 ? 'market_tab_2_label' : 'market_tab_$i',
                              ),
                              onTap: () => onChanged(i),
                              borderRadius: BorderRadius.circular(24),
                              child: SizedBox(
                                height: scaled ? 75 : 65,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (i == 2)
                                      const SizedBox(width: 44, height: 37)
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Badge(
                                          isLabelVisible: i == 3 && unread > 0,
                                          backgroundColor: const Color(
                                            0xFFFF7168,
                                          ),
                                          child: Icon(
                                            index == i ? active[i] : icons[i],
                                            color:
                                                index == i
                                                    ? marketBlue
                                                    : marketMuted,
                                            size: 27,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 3),
                                    Text(
                                      labels[i],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            index == i
                                                ? marketDeep
                                                : marketMuted,
                                        fontWeight:
                                            index == i
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                label: labels[2],
                selected: index == 2,
                button: true,
                child: Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF1FAF8),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22008790),
                        blurRadius: 13,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF04B7B7), Color(0xFF007B85)],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const ValueKey('market_tab_2'),
                        customBorder: const CircleBorder(),
                        onTap: () => onChanged(2),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
