import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/wallpapers.dart';

/// Renders either a gradient preset or a user photo, with optional dimming.
class WallpaperView extends StatelessWidget {
  final int index;
  final Uint8List? bytes;
  final double dim;
  const WallpaperView({super.key, required this.index, this.bytes, this.dim = 0});

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, wallpaperPresets.length - 1).toInt();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (bytes != null)
          Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
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
