import 'dart:math';
import 'dart:typed_data';
import 'wallpapers.dart';

/// One wallpaper: either a gradient preset or a user photo with a crop
/// (scale + offset, offsets are fractions of the screen size).
class WallpaperCfg {
  int preset = 0;
  String? asset;
  Uint8List? bytes;
  int iw = 0, ih = 0;
  double scale = 1, ox = 0, oy = 0;

  bool get hasImage => bytes != null && iw > 0 && ih > 0;

  /// Keeps the photo covering the whole screen (no empty edges) for a
  /// screen of [cw] x [ch] logical pixels.
  void clampTo(double cw, double ch) {
    if (!hasImage || cw <= 0 || ch <= 0) return;
    scale = scale.clamp(1.0, 6.0).toDouble();
    final cover = max(cw / iw, ch / ih);
    final mx = max(0.0, (iw * cover * scale - cw) / 2) / cw;
    final my = max(0.0, (ih * cover * scale - ch) / 2) / ch;
    ox = ox.clamp(-mx, mx).toDouble();
    oy = oy.clamp(-my, my).toDouble();
  }

  Map<String, dynamic> toJson() => {
    'p': preset,
    'asset': asset,
    'iw': iw,
    'ih': ih,
    's': scale,
    'ox': ox,
    'oy': oy,
  };

  void loadJson(Map<String, dynamic>? j) {
    if (j == null) return;
    preset = (j['p'] as int?) ?? 0;
    asset =
        bundledWallpapers.containsKey(j['asset']) ? j['asset'] as String : null;
    iw = (j['iw'] as int?) ?? 0;
    ih = (j['ih'] as int?) ?? 0;
    scale = (j['s'] as num? ?? 1).toDouble();
    ox = (j['ox'] as num? ?? 0).toDouble();
    oy = (j['oy'] as num? ?? 0).toDouble();
  }

  void copyFrom(WallpaperCfg o) {
    preset = o.preset;
    asset = o.asset;
    bytes = o.bytes;
    iw = o.iw;
    ih = o.ih;
    scale = o.scale;
    ox = o.ox;
    oy = o.oy;
  }
}
