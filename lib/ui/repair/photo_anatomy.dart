import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/repair/device_profile.dart';

class AnatomySpec {
  final List<Offset> quad;
  final Map<String, Rect> sprites;
  final bool separateParts;
  final String? asset;
  const AnatomySpec(
    this.quad, {
    this.sprites = const {},
    this.separateParts = false,
    this.asset,
  });
}

/// Coordinates are normalized into original, attributed photographs.
/// Perspective correction happens on a triangle mesh at draw time.
const anatomySpecs = <String, AnatomySpec>{
  'iphone11': AnatomySpec([
    Offset(.028, .82),
    Offset(.028, .22),
    Offset(.968, .22),
    Offset(.968, .82),
  ]),
  'iphone12': AnatomySpec([
    Offset(.966, .22),
    Offset(.966, .82),
    Offset(.025, .82),
    Offset(.025, .22),
  ]),
  'iphone13': AnatomySpec([
    Offset(.025, .82),
    Offset(.025, .22),
    Offset(.975, .22),
    Offset(.975, .82),
  ]),
  'iphone15pro': AnatomySpec([
    Offset(.78, .493),
    Offset(.96, .633),
    Offset(.3075, .92),
    Offset(.216, .70),
  ]),
  'galaxys22': AnatomySpec([
    Offset(.046, .298),
    Offset(.2975, .088),
    Offset(.821, .663),
    Offset(.5575, .945),
  ]),
  'galaxys23': AnatomySpec([
    Offset(.295, .008),
    Offset(.653, .008),
    Offset(.653, .993),
    Offset(.295, .993),
  ]),
  'pixel7': AnatomySpec([
    Offset(.625, .142),
    Offset(.906, .275),
    Offset(.585, .965),
    Offset(.2325, .73),
  ]),
  'iphoneduo': AnatomySpec([
    Offset(.34375, .2569),
    Offset(.83, .2569),
    Offset(.833, .9),
    Offset(.34, .9097),
  ]),
  'galaxyfold7': AnatomySpec([
    Offset(.202, .04),
    Offset(.798, .04),
    Offset(.798, .331),
    Offset(.202, .331),
  ], asset: 'assets/repair/anatomy/clean_fold_chassis.png'),
  'matext': AnatomySpec([
    Offset(.028, .646),
    Offset(.973, .646),
    Offset(.973, .931),
    Offset(.028, .931),
  ], asset: 'assets/repair/anatomy/clean_fold_chassis.png'),
};

class PhotoAnatomy {
  final ui.Image image;
  final AnatomySpec spec;
  PhotoAnatomy(this.image, this.spec);
  ui.Image? batteryImage;
  Rect? batteryCrop;
  PhotoAnatomy? exposed;
  PhotoAnatomy? display;
  static const displaySpecs = <String, AnatomySpec>{
    'iphone11': AnatomySpec([
      Offset(.1343, .337),
      Offset(.295, .362),
      Offset(.269, .817),
      Offset(.0817, .795),
    ]),
    'iphone12': AnatomySpec([
      Offset(.932, .03),
      Offset(.932, .58),
      Offset(.075, .58),
      Offset(.075, .03),
    ]),
    'iphone13': AnatomySpec([
      Offset(.85, .30),
      Offset(.85, .745),
      Offset(.13, .745),
      Offset(.13, .30),
    ]),
    'iphone15pro': AnatomySpec([
      Offset(.74, .12),
      Offset(.78, .48),
      Offset(.21, .674),
      Offset(.109, .29),
    ]),
    'pixel7': AnatomySpec([
      Offset(.175, .092),
      Offset(.465, .092),
      Offset(.465, .93),
      Offset(.175, .93),
    ]),
  };
  static const batteryCrops = <String, Rect>{
    'iphone11': Rect.fromLTWH(.032, .432, .216, .44),
    'iphone12': Rect.fromLTWH(.428, .408, .208, .38),
    'iphone13': Rect.fromLTWH(.444, .412, .20, .316),
    'iphone15pro': Rect.fromLTWH(.30, .612, .196, .312),
    'galaxys22': Rect.fromLTWH(.488, .392, .224, .276),
    'galaxys23': Rect.fromLTWH(.50, .464, .212, .28),
    'pixel7': Rect.fromLTWH(.06, .316, .212, .348),
  };
  static Future<ui.Image> _decode(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
      targetWidth: 1000,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static final Map<String, Future<PhotoAnatomy>> _cache = {};
  static Future<PhotoAnatomy> load(String id) =>
      _cache.putIfAbsent(id, () async {
        final bytes = await rootBundle.load(
          anatomySpecs[id]?.asset ?? 'assets/repair/anatomy/$id.jpg',
        );
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
          targetWidth: 1200,
          allowUpscaling: false,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        final photo = PhotoAnatomy(frame.image, anatomySpecs[id]!);
        if (displaySpecs.containsKey(id)) {
          photo.display = PhotoAnatomy(
            await _decode('assets/repair/anatomy/${id}_display.jpg'),
            displaySpecs[id]!,
          );
        }
        if (batteryCrops.containsKey(id)) {
          photo.batteryImage = await _decode(
            'assets/repair/anatomy/${id}_battery.jpg',
          );
          photo.batteryCrop = batteryCrops[id];
        }
        if (id == 'galaxys23') {
          photo.exposed = PhotoAnatomy(
            await _decode('assets/repair/anatomy/galaxys23_detail.jpg'),
            const AnatomySpec([
              Offset(-.075, .313),
              Offset(.28, .133),
              Offset(.9125, .778),
              Offset(.58, .993),
            ]),
          );
        }
        return photo;
      });

  Offset uv(double x, double y) {
    final a = Offset.lerp(spec.quad[0], spec.quad[1], x)!;
    final b = Offset.lerp(spec.quad[3], spec.quad[2], x)!;
    final p = Offset.lerp(a, b, y)!;
    return Offset(p.dx * image.width, p.dy * image.height);
  }

  void region(
    Canvas c,
    Rect dest,
    Rect normalized, {
    BlendMode blend = BlendMode.srcOver,
  }) {
    const cols = 10, rows = 18;
    final points = <Offset>[], tex = <Offset>[], indices = <int>[];
    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= cols; x++) {
        points.add(
          Offset(
            dest.left + dest.width * x / cols,
            dest.top + dest.height * y / rows,
          ),
        );
        tex.add(
          uv(
            normalized.left + normalized.width * x / cols,
            normalized.top + normalized.height * y / rows,
          ),
        );
      }
    }
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final a = y * (cols + 1) + x, b = a + 1, d = a + cols + 1, e = d + 1;
        indices.addAll([a, b, e, a, e, d]);
      }
    }
    c.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        points,
        textureCoordinates: tex,
        indices: indices,
      ),
      BlendMode.srcOver,
      Paint()
        ..blendMode = blend
        ..shader = ui.ImageShader(
          image,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
        )
        ..filterQuality = FilterQuality.high,
    );
  }

  void body(Canvas c, Rect r, DeviceProfile profile) {
    c.save();
    final shell =
        Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(18)));
    var holes = Path();
    final fullWidth = 224.0 * profile.segments;
    for (final b in [
      profile.battery,
      ...profile.auxiliaryBatteries,
      profile.camera,
      profile.port,
      profile.shield,
    ]) {
      final rect = Rect.fromLTWH(
        r.left + b.x / fullWidth * r.width,
        r.top + b.y / 438 * r.height,
        b.w / fullWidth * r.width,
        b.h / 438 * r.height,
      ).inflate(
        identical(b, profile.battery) && profile.segments == 1 ? 12 : 3,
      );
      holes = Path.combine(PathOperation.union, holes, Path()..addRect(rect));
    }
    c.clipPath(Path.combine(PathOperation.difference, shell, holes));
    region(c, r, const Rect.fromLTWH(0, 0, 1, 1));
    c.restore();
  }

  void part(Canvas c, DeviceProfile profile, String type, Rect dest) {
    if (type == 'port' && exposed != null) {
      exposed!.part(c, profile, type, dest);
      return;
    }
    if (type == 'battery' && batteryImage != null && batteryCrop != null) {
      final b = batteryCrop!, img = batteryImage!;
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(dest, const Radius.circular(6)));
      c.drawRect(dest, Paint()..color = const Color(0xFFB4B7B9));
      c.drawImageRect(
        img,
        Rect.fromLTWH(
          b.left * img.width,
          b.top * img.height,
          b.width * img.width,
          b.height * img.height,
        ),
        dest,
        Paint()
          ..blendMode = BlendMode.multiply
          ..filterQuality = FilterQuality.high,
      );
      c.restore();
      return;
    }
    final sprite = spec.sprites[type];
    if (sprite != null) {
      c.drawImageRect(
        image,
        Rect.fromLTWH(
          sprite.left * image.width,
          sprite.top * image.height,
          sprite.width * image.width,
          sprite.height * image.height,
        ),
        dest,
        Paint()..filterQuality = FilterQuality.high,
      );
      return;
    }
    final b =
        type == 'battery'
            ? profile.battery
            : type == 'camera'
            ? profile.camera
            : type == 'shield'
            ? profile.shield
            : type.startsWith('aux_battery_')
            ? profile.auxiliaryBatteries[int.parse(type.split('_').last)]
            : profile.port;
    final fullWidth = 224.0 * profile.segments;
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(dest, const Radius.circular(5)));
    region(
      c,
      dest,
      Rect.fromLTWH(b.x / fullWidth, b.y / 438, b.w / fullWidth, b.h / 438),
    );
    c.restore();
  }
}
