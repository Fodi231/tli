import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/repair/device_profile.dart';
import '../../core/repair/repair_session.dart';

/// Original vector art. No teardown photography is embedded in the game.
class ModelArtwork {
  final DeviceProfile profile;
  const ModelArtwork(this.profile);
  void label(
    Canvas c,
    String text,
    Offset p,
    double size,
    Color color, {
    bool center = false,
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: 'Roboto', fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, p - (center ? Offset(t.width / 2, t.height / 2) : Offset.zero));
  }

  void plate(Canvas c, Rect r, {Color? color, double radius = 4}) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(1, 2)),
        Radius.circular(radius),
      ),
      Paint()..color = Colors.black87,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              color == null
                  ? const [
                    Color(0xFFAEB2B3),
                    Color(0xFF4A5054),
                    Color(0xFF777D80),
                  ]
                  : [color, Color.lerp(color, Colors.black, .4)!],
        ).createShader(r),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(.6), Radius.circular(radius)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
  }

  void underlay(Canvas c, Rect phone) {
    Rect at(PartBox b) =>
        Rect.fromLTWH(phone.left + b.x, phone.top + b.y, b.w, b.h);
    final b = at(profile.board);
    // Substrate follows the service-side board shape, including a top bridge.
    final path =
        Path()..addRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)));
    if (profile.pixel) {
      path.addRect(Rect.fromLTWH(phone.left + 20, phone.top + 100, 177, 22));
    }
    if (profile.id == 'iphone15pro') {
      path.addRect(Rect.fromLTWH(phone.left + 23, phone.top + 22, 42, 45));
    }
    c.drawPath(
      path,
      Paint()
        ..color =
            profile.rearAccess
                ? const Color(0xFF245151)
                : const Color(0xFF222B26),
    );
    // Fine gold traces, vias, resistors and shielding cans stay anchored to PCB.
    final rng = math.Random(profile.id.codeUnits.fold<int>(0, (a, b) => a + b));
    for (var i = 0; i < 82; i++) {
      final x = b.left + 4 + rng.nextDouble() * (b.width - 12);
      final y = b.top + 4 + rng.nextDouble() * (b.height - 12);
      c.drawRect(
        Rect.fromLTWH(x, y, 2.3 + rng.nextInt(4), 1.8),
        Paint()
          ..color =
              i % 3 == 0 ? const Color(0xFFCFB67F) : const Color(0xFF858783),
      );
      if (i % 4 == 0) {
        c.drawLine(
          Offset(x, y),
          Offset(x + 8, y + 8),
          Paint()
            ..color = const Color(0xFFB59862)
            ..strokeWidth = .5,
        );
      }
    }
    final rows = profile.rearAccess ? 2 : 5;
    final cols = profile.rearAccess ? 3 : 1;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final r = Rect.fromLTWH(
          b.left + 7 + x * (b.width - 14) / cols,
          b.top + 10 + y * (b.height - 20) / rows,
          (b.width - 20) / cols,
          (b.height - 30) / rows - 7,
        );
        plate(c, r, radius: 2);
        label(
          c,
          y == 1 && x == 0
              ? (profile.pixel
                  ? 'TENSOR'
                  : profile.rearAccess
                  ? 'QUALCOMM'
                  : 'APL')
              : 'RF ${y + x + 1}',
          r.center,
          4.5,
          Colors.black54,
          center: true,
        );
      }
    }
    // Bottom speaker and haptic engine use separate metal enclosures.
    plate(
      c,
      Rect.fromLTWH(
        phone.left + 20,
        phone.top + 367,
        profile.rearAccess ? 184 : 94,
        18,
      ),
      color: const Color(0xFF303337),
    );
    label(
      c,
      profile.apple ? 'TAPTIC ENGINE' : 'LOUDSPEAKER',
      phone.topLeft + const Offset(27, 373),
      5,
      Colors.white54,
    );
    if (profile.apple) {
      plate(
        c,
        Rect.fromLTWH(phone.left + 126, phone.top + 367, 80, 18),
        color: const Color(0xFF303337),
      );
    }
    for (var i = 0; i < 11; i++) {
      c.drawCircle(
        phone.bottomCenter + Offset(-42 + i * 8, -6),
        1.5,
        Paint()..color = Colors.black87,
      );
    }
    // Thin perimeter gasket and antenna contacts.
    c.drawRRect(
      RRect.fromRectAndRadius(phone.deflate(7), const Radius.circular(24)),
      Paint()
        ..color = const Color(0xFF7D7062)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 8; i++) {
      c.drawRect(
        Rect.fromLTWH(
          phone.left + (i.isEven ? 9 : 210),
          phone.top + 42 + i * 43,
          4,
          8,
        ),
        Paint()..color = const Color(0xFFB7A777),
      );
    }
  }

  void part(Canvas c, String type, Rect r, {bool fresh = false}) {
    if (type == 'battery') {
      var path =
          Path()
            ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)));
      if (profile.lBattery && r.height > 150) {
        path =
            Path()
              ..moveTo(r.left, r.top)
              ..lineTo(r.right, r.top)
              ..lineTo(r.right, r.bottom)
              ..lineTo(r.left - 52, r.bottom)
              ..lineTo(r.left - 52, r.bottom - 45)
              ..lineTo(r.left, r.bottom - 45)
              ..close();
      }
      c.drawPath(
        path.shift(const Offset(2, 3)),
        Paint()..color = Colors.black87,
      );
      c.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF313132), Color(0xFF151617), Color(0xFF292A2B)],
          ).createShader(r),
      );
      c.drawPath(
        path,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
      // Foil pouch seams, soft creases and printed regulatory markings.
      for (var i = 0; i < 4; i++) {
        c.drawLine(
          r.topLeft + Offset(3 + i.toDouble(), 10),
          r.bottomLeft + Offset(3 + i.toDouble(), -9),
          Paint()
            ..color = Colors.white.withValues(alpha: .03)
            ..strokeWidth = .8,
        );
      }
      label(
        c,
        profile.apple
            ? 'Li-ion Battery'
            : profile.pixel
            ? 'Google · Li-ion'
            : 'SAMSUNG',
        r.center - const Offset(0, 41),
        r.height > 130 ? 10 : 8,
        Colors.white60,
        center: true,
      );
      label(
        c,
        profile.batteryMah == 0
            ? 'Dual-cell pack'
            : '${profile.segments > 1 ? "Pack " : ""}${profile.batteryMah} mAh',
        r.center - const Offset(0, 18),
        9,
        Colors.white54,
        center: true,
      );
      if (r.height > 130) {
        label(
          c,
          profile.batteryCode,
          r.center + const Offset(0, 2),
          5.7,
          Colors.white38,
          center: true,
        );
        label(
          c,
          'Rechargeable · Lithium-ion',
          r.center + const Offset(0, 15),
          5.5,
          Colors.white38,
          center: true,
        );
        label(
          c,
          'Do not disassemble / puncture',
          r.center + const Offset(0, 25),
          5.2,
          Colors.white30,
          center: true,
        );
        label(
          c,
          'CE   Li-ion',
          r.center + const Offset(0, 53),
          12,
          Colors.white54,
          center: true,
        );
        for (var i = 0; i < 24; i++) {
          c.drawRect(
            Rect.fromLTWH(
              r.left + r.width * .25 + i * 2.3,
              r.bottom - 31,
              i % 3 == 0 ? 1.5 : .6,
              11,
            ),
            Paint()..color = Colors.white38,
          );
        }
      }
      if (fresh) {
        label(
          c,
          'QC ✓',
          r.bottomRight - const Offset(26, 9),
          6,
          const Color(0xFF65E6AE),
          center: true,
        );
      }
    } else if (type == 'camera') {
      plate(c, r, color: const Color(0xFF45484B), radius: 7);
      for (final lens in profile.lenses) {
        final p = r.topLeft + Offset(r.width * lens.x, r.height * lens.y);
        final radius = math.min(r.width, r.height) * lens.r;
        c.drawCircle(
          p + const Offset(1, 2),
          radius + 3,
          Paint()..color = Colors.black,
        );
        c.drawCircle(
          p,
          radius + 2,
          Paint()
            ..shader = const SweepGradient(
              colors: [
                Color(0xFFB5B7B9),
                Color(0xFF353C41),
                Color(0xFF959C9E),
                Color(0xFFB5B7B9),
              ],
            ).createShader(Rect.fromCircle(center: p, radius: radius + 2)),
        );
        c.drawCircle(
          p,
          radius,
          Paint()
            ..shader = const RadialGradient(
              colors: [
                Color(0xFF0C1826),
                Color(0xFF264761),
                Color(0xFF061018),
                Color(0xFF354553),
              ],
            ).createShader(Rect.fromCircle(center: p, radius: radius)),
        );
        c.drawCircle(
          p - Offset(radius * .27, radius * .25),
          radius * .22,
          Paint()..color = const Color(0xFFB4C7E4).withValues(alpha: .55),
        );
      }
    } else if (type == 'port') {
      plate(
        c,
        r,
        color:
            profile.apple ? const Color(0xFF8E6645) : const Color(0xFF29574F),
        radius: 3,
      );
      for (var i = 0; i < 14; i++) {
        c.drawRect(
          Rect.fromLTWH(r.left + 5 + i * r.width / 15, r.top + 5, 3, 4),
          Paint()
            ..color =
                i % 2 == 0 ? const Color(0xFFBDAB80) : const Color(0xFF28292B),
        );
      }
      final port = Rect.fromCenter(
        center: r.center + const Offset(0, 5),
        width: r.width * .27,
        height: math.min(21, r.height - 4),
      );
      plate(c, port, radius: 4);
      c.drawRRect(
        RRect.fromRectAndRadius(port.deflate(3), const Radius.circular(3)),
        Paint()..color = Colors.black87,
      );
      c.drawLine(
        port.centerLeft + const Offset(6, 0),
        port.centerRight - const Offset(6, 0),
        Paint()
          ..color = const Color(0xFFA49D83)
          ..strokeWidth = profile.portType == 'USB-C' ? 2 : 1,
      );
    }
  }

  void cables(Canvas c, Rect phone, RepairSession s) {
    Offset at(double x, double y) => phone.topLeft + Offset(x, y);
    void ribbon(
      List<Offset> points,
      double width,
      String text, {
      bool off = false,
    }) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = width + 2
          ..color = Colors.black87,
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = width
          ..color = const Color(0xFF493527),
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = const Color(0xFFB78F58),
      );
      if (text.isNotEmpty) {
        label(
          c,
          text,
          points[points.length ~/ 2],
          5.5,
          Colors.white60,
          center: true,
        );
      }
      final end = points.last + Offset(off ? 7 : 0, off ? -7 : 0);
      plate(
        c,
        Rect.fromCenter(center: end, width: width + 5, height: 7),
        color: off ? const Color(0xFFB7833F) : const Color(0xFF575955),
        radius: 1,
      );
    }

    final off = s.done('part_off') && !s.done('part_on');
    if (profile.rearAccess) {
      // Samsung MAIN/SUB interconnects run above the pouch, not beside it.
      for (var i = 0; i < 2; i++) {
        ribbon(
          [
            at(87 + i * 49, 137),
            at(85 + i * 49, 250),
            at(88 + i * 49, 353),
            at(87 + i * 49, 382),
          ],
          16,
          i == 0 ? 'MAIN ↑' : 'SUB ↑',
          off: off,
        );
      }
      ribbon([at(186, 360), at(195, 267), at(194, 143)], 3, '', off: false);
    } else {
      final b = profile.battery;
      ribbon(
        [
          at(b.x + (profile.board.x < b.x ? 3 : b.w - 3), b.y + b.h * .65),
          at(profile.batterySocketX + 14, profile.batterySocketY + 7),
        ],
        12,
        '',
        off: s.batteryDisconnected,
      );
      ribbon(
        [
          at(
            profile.camera.x + profile.camera.w / 2,
            profile.camera.y + profile.camera.h,
          ),
          at(profile.board.x + 22, profile.board.y + 29),
        ],
        13,
        '',
        off: s.service == 'camera' && off,
      );
      ribbon(
        [
          at(110, 397),
          at(profile.board.x + 25, 350),
          at(profile.board.x + 25, profile.board.y + profile.board.h - 14),
        ],
        16,
        '',
        off: s.service == 'port' && off,
      );
    }
  }

  void shield(Canvas c, Rect r) {
    if (profile.rearAccess) {
      plate(c, r, color: const Color(0xFF26292D), radius: 8);
      final coil = Rect.fromCenter(
        center: r.center - const Offset(0, 17),
        width: r.width * .78,
        height: r.width * .78,
      );
      for (var i = 0; i < 11; i++) {
        c.drawOval(
          coil.deflate(i * 3.1),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFF746D5D),
        );
      }
      label(
        c,
        'NFC / WIRELESS CHARGING',
        r.bottomCenter - const Offset(0, 22),
        6,
        Colors.white38,
        center: true,
      );
    } else if (profile.pixel) {
      plate(c, r, color: const Color(0xFF9A9E9D), radius: 9);
      c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(17), const Radius.circular(6)),
        Paint()..color = const Color(0xFF373B3D),
      );
      label(
        c,
        'GRAPHITE · MIDFRAME',
        r.center,
        7,
        Colors.white30,
        center: true,
      );
    } else {
      plate(c, r, radius: 3);
    }
  }

  void rearCover(Canvas c, Rect r, {bool inside = false}) {
    plate(
      c,
      r,
      color: inside ? const Color(0xFF272A2C) : const Color(0xFF9CB8A9),
      radius: 25,
    );
    final cam = Rect.fromLTWH(
      r.left + 9,
      r.top + 16,
      r.width * .22,
      r.height * .26,
    );
    for (final l in profile.lenses) {
      c.drawCircle(
        cam.topLeft + Offset(cam.width * l.x, cam.height * l.y),
        math.min(cam.width, cam.height) * l.r,
        Paint()..color = Colors.black87,
      );
    }
    if (inside) {
      c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(12), const Radius.circular(16)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF665A44),
      );
    }
    label(
      c,
      inside ? 'REAR COVER' : 'SAMSUNG',
      r.center + Offset(0, r.height * .22),
      12,
      Colors.white30,
      center: true,
    );
  }
}
