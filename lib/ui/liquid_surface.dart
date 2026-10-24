import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';
import '../core/theme.dart';

/// All translucent surfaces observe the same persisted accessibility setting.
/// In solid mode no blur layer is created.
class LiquidSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool? light;
  final Color? tint;
  final bool highContrast;
  const LiquidSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 24,
    this.light,
    this.tint,
    this.highContrast = false,
  });
  @override
  Widget build(BuildContext context) {
    final enabled = context.select<GameState, bool>((g) => g.liquidGlass);
    final isLight = light ?? !IosColors.of(context).dark;
    final base = tint ?? (isLight ? Colors.white : const Color(0xFF24262C));
    final border = BorderRadius.circular(radius);
    final box = Container(
      key: ValueKey(enabled ? 'glass_material' : 'solid_material'),
      padding: padding,
      decoration: BoxDecoration(
        color: enabled ? null : base.withValues(alpha: 1),
        gradient:
            enabled
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    base.withValues(
                      alpha:
                          highContrast
                              ? .98
                              : isLight
                              ? .80
                              : .82,
                    ),
                    base.withValues(
                      alpha:
                          highContrast
                              ? .94
                              : isLight
                              ? .57
                              : .73,
                    ),
                  ],
                )
                : null,
        borderRadius: border,
        border: Border.all(
          color:
              enabled
                  ? Colors.white.withValues(alpha: isLight ? .9 : .21)
                  : (isLight
                      ? const Color(0xFFE1E3EA)
                      : const Color(0xFF35373D)),
          width: enabled ? 1.2 : .7,
        ),
      ),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: enabled ? .09 : .025),
            blurRadius: enabled ? 22 : 7,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: border,
        child:
            enabled
                ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: box,
                )
                : box,
      ),
    );
  }
}
