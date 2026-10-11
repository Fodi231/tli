import 'dart:math';

import 'package:flutter/material.dart';

import '../core/wallpaper_cfg.dart';
import '../core/wallpapers.dart';

/// Renders a gradient preset or a user photo (with its crop) plus dimming.
/// Offsets are fractions of the widget size, so the same crop looks the same
/// on any screen size.
class WallpaperView extends StatelessWidget {
  final WallpaperCfg cfg;
  final double dim;
  const WallpaperView({super.key, required this.cfg, this.dim = 0});

  @override
  Widget build(BuildContext context) {
    final i = cfg.preset.clamp(0, wallpaperPresets.length - 1).toInt();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (cfg.hasImage)
          LayoutBuilder(builder: (context, c) {
            final cw = c.maxWidth, ch = c.maxHeight;
            final cover = max(cw / cfg.iw, ch / cfg.ih);
            final s = cfg.scale.clamp(1.0, 6.0).toDouble();
            final dw = cfg.iw * cover * s, dh = cfg.ih * cover * s;
            final mx = max(0.0, (dw - cw) / 2), my = max(0.0, (dh - ch) / 2);
            final dx = (cfg.ox * cw).clamp(-mx, mx).toDouble();
            final dy = (cfg.oy * ch).clamp(-my, my).toDouble();
            return ClipRect(
              child: OverflowBox(
                minWidth: dw,
                maxWidth: dw,
                minHeight: dh,
                maxHeight: dh,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Image.memory(cfg.bytes!, width: dw, height: dh, fit: BoxFit.fill, gaplessPlayback: true),
                ),
              ),
            );
          })
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: wallpaperPresets[i],
                stops: const [0, 0.35, 0.7, 1],
              ),
            ),
          ),
        if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
      ],
    );
  }
}
