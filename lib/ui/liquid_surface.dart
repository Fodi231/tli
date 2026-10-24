import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';

class LiquidSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool light;
  const LiquidSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 24,
    this.light = true,
  });
  @override
  Widget build(BuildContext context) {
    final enabled = context.select<GameState, bool>((g) => g.liquidGlass);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color:
            enabled
                ? null
                : light
                ? const Color(0xFFF4F8FC)
                : const Color(0xFF26374D),
        gradient:
            enabled
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      light
                          ? [const Color(0xF5FFFFFF), const Color(0xE0E7F1FA)]
                          : [const Color(0xF0334962), const Color(0xE025344B)],
                )
                : null,
        border: Border.all(
          color: light ? Colors.white.withValues(alpha: .92) : Colors.white24,
          width: 1.2,
        ),
      ),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22314860),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child:
            enabled
                ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: box,
                )
                : box,
      ),
    );
  }
}
