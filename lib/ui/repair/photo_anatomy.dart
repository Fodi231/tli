import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/repair/device_profile.dart';
import '../../core/market/device_catalog.dart';

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
  ui.Image? chassisImage;
  Rect? chassisCrop;
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
  static final Map<String, PhotoAnatomy> _cache = {};
  static Future<PhotoAnatomy> load(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final json =
        jsonDecode(
              await rootBundle.loadString(
                'assets/repair/generated/atlas.json',
                cache: false,
              ),
            )
            as Map<String, dynamic>;
    final m = Map<String, dynamic>.from(json[id]);
    final raw = await rootBundle.load('assets/repair/generated/$id.png');
    final codec = await ui.instantiateImageCodec(raw.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    Rect rect(dynamic a) => Rect.fromLTWH(
      (a[0] as num).toDouble(),
      (a[1] as num).toDouble(),
      (a[2] as num).toDouble(),
      (a[3] as num).toDouble(),
    );
    final sprites = (m['sprites'] as Map).map(
      (k, v) => MapEntry(k as String, rect(v)),
    );
    final base = sprites['chassis']!;
    final photo = PhotoAnatomy(
      frame.image,
      AnatomySpec(
        [base.topLeft, base.topRight, base.bottomRight, base.bottomLeft],
        sprites: sprites,
        separateParts: true,
        asset: 'assets/repair/generated/$id.png',
      ),
    );
    if (m['chassisAsset'] != null) {
      final bytes = await rootBundle.load(
        'assets/repair/generated/${m['chassisAsset']}',
      );
      final decoder = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
      );
      photo.chassisImage = (await decoder.getNextFrame()).image;
      decoder.dispose();
      photo.chassisCrop = rect(m['chassisCrop']);
    }
    _cache[id] = photo;
    return photo;
  }

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

  void _bareChassis(Canvas c, Rect r) {
    final img = chassisImage, crop = chassisCrop;
    if (img != null && crop != null) {
      c.drawImageRect(
        img,
        Rect.fromLTWH(
          crop.left * img.width,
          crop.top * img.height,
          crop.width * img.width,
          crop.height * img.height,
        ),
        r,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      region(c, r, const Rect.fromLTWH(0, 0, 1, 1));
    }
  }

  void body(Canvas c, Rect r, DeviceProfile profile) {
    if (spec.separateParts) {
      c.save();
      final holes = Path();
      for (final b in [profile.camera, profile.port]) {
        final bay = Rect.fromLTWH(
          r.left + b.x / (224 * profile.segments) * r.width,
          r.top + b.y / 438 * r.height,
          b.w / (224 * profile.segments) * r.width,
          b.h / 438 * r.height,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(bay, const Radius.circular(5)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF343838), Color(0xFF141A1D)],
            ).createShader(bay),
        );
        holes.addRRect(RRect.fromRectAndRadius(bay, const Radius.circular(5)));
      }
      c.clipPath(
        Path.combine(PathOperation.difference, Path()..addRect(r), holes),
      );
      _bareChassis(c, r);
      c.restore();
      return;
    }

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
      if (type == 'cover_inside' && deviceFor(profile.id)!.magSafe) {
        final panelWidth = dest.width / profile.segments;
        final center = Offset(
          dest.left + panelWidth * .5,
          dest.top + dest.height * .56,
        );
        final radius = panelWidth * .33;
        for (var i = 0; i < 20; i++) {
          final angle = i * 3.141592653589793 * .1;
          c.save();
          c.translate(center.dx, center.dy);
          c.rotate(angle);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                radius,
                -panelWidth * .025,
                panelWidth * .065,
                panelWidth * .05,
              ),
              Radius.circular(panelWidth * .01),
            ),
            Paint()..color = const Color(0xFF9BA0A2),
          );
          c.restore();
        }
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center + Offset(0, radius * 1.35),
              width: panelWidth * .08,
              height: panelWidth * .16,
            ),
            const Radius.circular(1),
          ),
          Paint()..color = const Color(0xFF9BA0A2),
        );
      }
      if (type == 'battery' || type.startsWith('aux_battery_')) {
        final cell =
            type == 'battery' ? 1 : (int.parse(type.split('_').last) + 2);
        final lines = [
          profile.manufacturer.toUpperCase(),
          profile.modelName,
          profile.segments > 1
              ? 'Cell $cell / ${profile.segments}'
              : '${profile.batteryMah} mAh',
          if (profile.segments > 1 && profile.batteryMah > 0)
            '${profile.batteryMah} mAh total',
          'Li-ion',
        ];
        final font = (dest.width * .052).clamp(3.0, 10.0);
        final tp = TextPainter(
          text: TextSpan(
            text: lines.join('\n'),
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: font,
              height: 1.6,
              color:
                  profile.id == 'galaxys22' || profile.id == 'galaxyfold7'
                      ? const Color(0xFF293138)
                      : const Color(0xFFBDC5CC),
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: dest.width * .82);
        tp.paint(
          c,
          Offset(dest.center.dx - tp.width / 2, dest.center.dy - tp.height / 2),
        );
      }
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
