import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/repair/repair_session.dart';
import '../../core/repair/repair_strings.dart';
import 'workbench_geometry.dart';
import 'model_artwork.dart';
import '../../core/repair/device_profile.dart';
import 'photo_anatomy.dart';

const benchBlue = Color(0xFF57C5FF);
const benchGreen = Color(0xFF65E6AE);
const benchInk = Color(0xFF101820);

class WorkbenchPainter extends CustomPainter {
  final WorkbenchGeometry geometry;
  final RepairSession session;
  final String device;
  final double zoom, pulse, hold;
  final Offset pan;
  final String? dragTarget, holdingTarget;
  final Offset? dragPosition;
  final PhotoAnatomy? photo;
  WorkbenchPainter({
    required this.geometry,
    required this.session,
    required this.device,
    required this.zoom,
    required this.pan,
    required this.pulse,
    this.hold = 0,
    this.holdingTarget,
    this.dragTarget,
    this.dragPosition,
    this.photo,
  });

  DeviceProfile get profile => profileFor(session.device);
  ModelArtwork get art => ModelArtwork(profile);

  double fit(Size size) => math.min(
    size.width / geometry.size.width,
    size.height / geometry.size.height,
  );
  Offset fromLocal(Offset p, Size viewport) =>
      (p - viewport.center(Offset.zero) - pan) / (fit(viewport) * zoom) +
      geometry.size.center(Offset.zero);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2 + pan.dx, size.height / 2 + pan.dy);
    canvas.scale(fit(size) * zoom);
    canvas.translate(-geometry.size.width / 2, -geometry.size.height / 2);
    final g = geometry;
    final s = session;
    final mat = Rect.fromLTWH(14, 66, g.size.width - 28, g.size.height - 84);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        mat.shift(const Offset(0, 10)),
        const Radius.circular(23),
      ),
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mat, const Radius.circular(23)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24556D), Color(0xFF173B50), Color(0xFF102C3D)],
        ).createShader(mat),
    );
    for (double x = 32; x < g.size.width - 45; x += 42) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 75, 34, 19),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF16384B),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 75, 34, 19),
          const Radius.circular(4),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: .10),
      );
    }
    // Thin technical grid makes the physical work area readable over the photo.
    final grid =
        Paint()
          ..color = Colors.white.withValues(alpha: .025)
          ..strokeWidth = .7;
    for (double x = 20; x < g.size.width; x += 32) {
      canvas.drawLine(Offset(x, 60), Offset(x, g.size.height - 25), grid);
    }
    for (double y = 60; y < g.size.height; y += 32) {
      canvas.drawLine(Offset(20, y), Offset(g.size.width - 20, y), grid);
    }
    _tray(canvas, g.newTray, rt('r_new'), benchGreen);
    _tray(canvas, g.oldTray, rt('r_old'), const Color(0xFFF1AC83));
    _tray(canvas, g.partsTray, rt('r_tray'), benchBlue);
    final rest = RRect.fromRectAndRadius(
      g.parkedDisplay.inflate(9),
      const Radius.circular(32),
    );
    canvas.drawRRect(
      rest,
      Paint()..color = Colors.black.withValues(alpha: .18),
    );
    canvas.drawRRect(
      rest,
      Paint()
        ..color = Colors.white.withValues(alpha: .10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _text(
      canvas,
      rt(profile.rearAccess ? 'r_cover_place' : 'r_display_place'),
      Offset(g.parkedDisplay.center.dx, g.parkedDisplay.bottom + 20),
      11,
      Colors.white54,
      centered: true,
      spacing: 1.5,
    );
    _body(canvas);
    final noScreen =
        !profile.rearAccess && s.service == 'display' && s.partRemoved;
    if (s.isOpen && !noScreen && dragTarget != 'screen') {
      _displayBack(
        canvas,
        g.parkedDisplay,
        fresh: s.newPartInstalled && s.service == 'display',
        cover: profile.rearAccess,
      );
    }
    if (s.isOpen &&
        !profile.rearAccess &&
        !((s.service == 'display' || s.service == 'battery') &&
            s.done('part_off') &&
            !s.done('part_on'))) {
      _flex(canvas);
    }
    if (!s.done('part_in') && s.service != 'diag' && dragTarget != 'new_part') {
      _component(
        canvas,
        s.service,
        g.rect('new_part', s).deflate(6),
        fresh: true,
      );
    } else if (s.service != 'diag' && s.newPartInstalled) {
      _text(
        canvas,
        '✓ ${rt('r_installed')}',
        g.newTray.center,
        14,
        benchGreen,
        centered: true,
      );
    }
    if (s.service == 'battery') {
      for (var i = 0; i < profile.auxiliaryBatteries.length; i++) {
        final id = 'new_aux_$i';
        if (!s.auxiliaryInstalled(i) && dragTarget != id) {
          final rect = g.rect(id, s).deflate(4);
          if (photo != null) {
            photo!.part(canvas, profile, 'aux_battery_$i', rect);
          } else {
            art.part(canvas, 'battery', rect, fresh: true);
          }
        }
      }
    }
    if (s.done('part_out') || s.current?.id == 'part_out') {
      if (s.service != 'battery' || profile.auxiliaryBatteries.isEmpty) {
        if (s.done('part_out')) {
          _component(canvas, s.service, g.oldTray.deflate(32), fresh: false);
        }
      } else {
        final count = profile.auxiliaryBatteries.length + 1;
        final tray = g.oldTray.deflate(22);
        for (var i = 0; i < count; i++) {
          final id = i == 0 ? 'battery' : 'aux_battery_${i - 1}';
          if (!s.done('part_out') && !s.targetDone(id)) continue;
          final rect = Rect.fromLTWH(
            tray.left + i * tray.width / count,
            tray.top + 12,
            tray.width / count - 5,
            tray.height - 20,
          );
          if (photo != null) {
            photo!.part(canvas, profile, id, rect);
          } else {
            art.part(canvas, 'battery', rect);
          }
        }
      }
    }
    if (s.shieldRemoved && dragTarget != 'stored_shield') {
      _shield(canvas, g.rect('stored_shield', s).deflate(6));
    }
    // Collected screws are physical marks in the tray, independent of the HUD.
    final count =
        (s.done('frame_out') && !s.done('frame_in') ? 2 : 0) +
        (s.done('shield_screws_out') && !s.done('shield_screws_in')
            ? profile.shieldScrews
            : 0);
    for (var i = 0; i < count; i++) {
      _screw(canvas, g.partsTray.topLeft + Offset(25 + i * 19, 44), .7);
    }
    if (s.hints && !s.finished) _highlights(canvas);
    if (dragTarget != null && dragPosition != null) {
      final source = g.rect(dragTarget!, s);
      final r = Rect.fromCenter(
        center: dragPosition!,
        width: source.width,
        height: source.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r.shift(const Offset(8, 10)),
          const Radius.circular(12),
        ),
        Paint()
          ..color = Colors.black38
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      if (dragTarget == 'front_display') {
        _displayBack(canvas, r, fresh: s.newPartInstalled);
      } else if (dragTarget == 'screen') {
        if (s.isOpen) {
          _displayBack(
            canvas,
            r,
            fresh: s.newPartInstalled,
            cover: profile.rearAccess,
          );
        } else {
          _screen(canvas, r, cracked: s.service == 'display');
        }
      } else if (dragTarget!.contains('shield')) {
        _shield(canvas, r);
      } else if (dragTarget!.startsWith('adhesive')) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(6)),
          Paint()..color = Colors.white70,
        );
      } else if (dragTarget!.startsWith('new_aux_')) {
        final id = 'aux_battery_${dragTarget!.split('_').last}';
        if (photo != null) {
          photo!.part(canvas, profile, id, r);
        } else {
          art.part(canvas, 'battery', r, fresh: true);
        }
      } else if (dragTarget!.startsWith('aux_battery_')) {
        if (photo != null) {
          photo!.part(canvas, profile, dragTarget!, r);
        } else {
          art.part(canvas, 'battery', r, fresh: s.newPartInstalled);
        }
      } else {
        _component(canvas, s.service, r, fresh: dragTarget == 'new_part');
      }
    }
    if (holdingTarget != null && hold > 0) {
      final c = g.rect(holdingTarget!, s).center;
      canvas.drawCircle(c, 30, Paint()..color = benchInk.withValues(alpha: .9));
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 27),
        -math.pi / 2,
        2 * math.pi * hold,
        false,
        Paint()
          ..color =
              s.heatingStep
                  ? (22 + hold * 96 > 105
                      ? Colors.redAccent
                      : 22 + hold * 96 >= 65
                      ? benchGreen
                      : Colors.orangeAccent)
                  : benchGreen
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5,
      );
      _text(
        canvas,
        s.heatingStep
            ? '${(22 + hold * 96).round()} °C'
            : '${(hold * 100).round()}%',
        c,
        13,
        Colors.white,
        centered: true,
      );
    }
    _text(
      canvas,
      device,
      Offset(g.phone.center.dx, g.phone.bottom + 32),
      15,
      Colors.white70,
      centered: true,
      spacing: 1,
    );
    canvas.restore();
  }

  void _tray(Canvas c, Rect r, String label, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(0, 5)),
        const Radius.circular(16),
      ),
      Paint()..color = Colors.black38,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(16)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF26323C).withValues(alpha: .97),
            benchInk.withValues(alpha: .97),
          ],
        ).createShader(r),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(16)),
      Paint()
        ..color = color.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _text(c, label, r.topLeft + const Offset(14, 15), 10, color, spacing: 1.2);
  }

  void _body(Canvas c) {
    final s = session;
    final g = geometry;
    final p = g.phone;
    final android = !device.toLowerCase().contains('iphone');
    final radius = android ? 24.0 : 36.0;
    c.drawRRect(
      RRect.fromRectAndRadius(
        p.shift(const Offset(9, 18)),
        Radius.circular(radius),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(p.inflate(4), Radius.circular(radius)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB7BCC6),
            Color(0xFF454B57),
            Color(0xFF9C9FA8),
            Color(0xFF343944),
          ],
        ).createShader(p),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(p, Radius.circular(radius - 2)),
      Paint()..color = const Color(0xFF11151C),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(p.deflate(6), Radius.circular(radius - 6)),
      Paint()..color = const Color(0xFF292B30),
    );
    // Physical side button is always visible and touchable.
    c.drawRRect(
      RRect.fromRectAndRadius(
        g.rect('power', s).deflate(6),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFB0B6C3),
    );
    if (!s.isOpen || s.frontFacing) {
      if (dragTarget != 'screen' &&
          dragTarget != 'front_display' &&
          !(s.frontFacing && s.partRemoved)) {
        _screen(
          c,
          p.deflate(9),
          cracked: s.service == 'display' && !s.newPartInstalled,
        );
      }
    } else {
      if (photo != null) {
        photo!.body(c, p, profile);
      } else {
        art.underlay(c, p);
      }
      for (final part in ['battery', 'camera', 'port']) {
        if (!(s.service == part &&
                (s.partRemoved ||
                    s.current?.id == 'part_out' && s.targetDone(part))) &&
            dragTarget != part) {
          if (photo == null || photo!.spec.separateParts) {
            _component(
              c,
              part,
              g.rect(part, s),
              fresh: s.service == part && s.newPartInstalled,
            );
          }
        } else {
          c.drawRRect(
            RRect.fromRectAndRadius(g.rect(part, s), const Radius.circular(7)),
            Paint()..color = Colors.black54,
          );
        }
      }
      for (var i = 0; i < profile.auxiliaryBatteries.length; i++) {
        final id = 'aux_battery_$i';
        final removed =
            s.service == 'battery' &&
            (s.done('part_out') && !s.auxiliaryInstalled(i) ||
                s.current?.id == 'part_out' && s.targetDone(id));
        final r = g.rect(id, s);
        if (removed || dragTarget == id) {
          c.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(6)),
            Paint()..color = const Color(0xFF242A30),
          );
        } else if (photo == null || photo!.spec.separateParts) {
          if (photo != null) {
            photo!.part(c, profile, id, r);
          } else {
            art.part(c, 'battery', r, fresh: s.newPartInstalled);
          }
        }
      }
      if (photo == null) art.cables(c, p, s);
      for (final id in [
        'battery_connector',
        'part_connector',
        if (profile.rearAccess) 'interconnect_1',
        for (var i = 0; i < profile.auxiliaryBatteries.length; i++)
          'aux_battery_connector_$i',
      ]) {
        final disconnected =
            (id == 'battery_connector' ||
                    id.startsWith('aux_battery_connector'))
                ? s.connectorDisconnected(id)
                : s.done('part_off') && !s.done('part_on');
        final r = g.rect(id, s);
        final end =
            r.center + Offset(disconnected ? -10 : 0, disconnected ? -9 : 0);
        final start = r.center + const Offset(22, 24);
        final ribbon =
            Path()
              ..moveTo(start.dx, start.dy)
              ..cubicTo(
                start.dx - 22,
                start.dy,
                end.dx + 18,
                end.dy + 14,
                end.dx,
                end.dy,
              );
        c.drawPath(
          ribbon,
          Paint()
            ..color = const Color(0xFF111318)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10,
        );
        c.drawPath(
          ribbon,
          Paint()
            ..color = const Color(0xFF5B513A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(2)),
          Paint()..color = const Color(0xFF8B9296),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: end, width: 23, height: 10),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF22252A),
        );
        if (disconnected) {
          for (var pin = 0; pin < 7; pin++) {
            c.drawLine(
              end + Offset(-8 + pin * 2.6, 2),
              end + Offset(-8 + pin * 2.6, 5),
              Paint()
                ..color = const Color(0xFFE3C886)
                ..strokeWidth = 1,
            );
          }
        }
      }
      if (!s.shieldRemoved && dragTarget != 'shield') {
        _shield(c, g.rect('shield', s));
      }
      for (var i = 0; i < profile.shieldScrews; i++) {
        final id = 'shield_$i';
        final absent =
            s.done('shield_screws_out') && !s.done('shield_screws_in');
        final inCurrent = s.current?.targets.contains(id) == true;
        if ((!absent || s.current?.id == 'shield_screws_in') &&
            !(inCurrent && s.targetDone(id))) {
          _screw(c, g.rect(id, s).center, 1, turns: s.turnsFor(id));
        }
      }
      if (s.service == 'camera' || s.service == 'port') {
        for (var i = 0; i < (s.service == 'port' ? 3 : 2); i++) {
          final id = 'part_$i';
          if (!(s.done('part_screws_out') && !s.done('part_screws_in')) ||
              s.current?.id == 'part_screws_in') {
            if (!s.targetDone(id)) {
              _screw(c, g.rect(id, s).center, .85, turns: s.turnsFor(id));
            }
          }
        }
      }
      if (s.service == 'battery' && !s.done('adhesive_out')) {
        for (var i = 0; i < profile.adhesiveTabs; i++) {
          final id = 'adhesive_$i';
          if (s.targetDone(id) || dragTarget == id) continue;
          c.drawRRect(
            RRect.fromRectAndRadius(g.rect(id, s), const Radius.circular(5)),
            Paint()
              ..color =
                  profile.id == 'galaxys23'
                      ? const Color(0xFF6696BB)
                      : const Color(0xFFEBE0CF),
          );
        }
      }
    }
    for (var i = 0; i < (profile.frameScrews ? 2 : 0); i++) {
      final id = 'frame_$i';
      if (!(s.done('frame_out') && !s.done('frame_in')) ||
          s.current?.id == 'frame_in') {
        if (!s.targetDone(id)) {
          _screw(c, g.rect(id, s).center, .9, turns: s.turnsFor(id));
        }
      }
    }
  }

  void _screen(Canvas c, Rect r, {bool cracked = false}) {
    final s = session;
    if (profile.rearAccess && !s.powered && !s.frontFacing) {
      art.rearCover(c, r);
      return;
    }
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(27)),
      Paint()..color = Colors.black,
    );
    final glass = r.deflate(4);
    if (s.powered) {
      c.drawRRect(
        RRect.fromRectAndRadius(glass, const Radius.circular(25)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E3D60),
              Color(0xFF244BA8),
              Color(0xFF65ACCE),
              Color(0xFF122536),
            ],
          ).createShader(glass),
      );
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(glass, const Radius.circular(25)));
      c.drawOval(
        Rect.fromCenter(
          center: r.center + const Offset(80, 130),
          width: 260,
          height: 450,
        ),
        Paint()..color = const Color(0xFF91D4E5).withValues(alpha: .28),
      );
      c.restore();
      _text(
        c,
        'TECHLIFE',
        r.topCenter + const Offset(0, 68),
        13,
        Colors.white70,
        centered: true,
        spacing: 2,
      );
      _text(
        c,
        s.finished ? '✓' : '09:41',
        r.topCenter + const Offset(0, 109),
        36,
        Colors.white,
        centered: true,
      );
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(glass, const Radius.circular(25)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF151F27), Color(0xFF05080B)],
          ).createShader(glass),
      );
      c.drawLine(
        glass.topLeft + const Offset(24, 46),
        glass.bottomRight - const Offset(28, 76),
        Paint()
          ..color = Colors.white.withValues(alpha: .025)
          ..strokeWidth = 56,
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: r.topCenter + const Offset(0, 16),
          width: 62,
          height: 14,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF060B10),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: r.bottomCenter - const Offset(0, 12),
          width: 72,
          height: 3,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white38,
    );
    if (cracked) {
      final origin = r.topLeft + Offset(r.width * .33, r.height * .54);
      final p =
          Paint()
            ..color = Colors.white.withValues(alpha: .64)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + .2;
        final end =
            origin + Offset(math.cos(angle) * 83, math.sin(angle) * 147);
        final middle =
            Offset.lerp(origin, end, .5)! + Offset(i.isEven ? 9 : -7, 4);
        c.drawPath(
          Path()
            ..moveTo(origin.dx, origin.dy)
            ..lineTo(middle.dx, middle.dy)
            ..lineTo(end.dx, end.dy),
          p,
        );
        c.drawLine(middle, middle + Offset(i.isEven ? 22 : -15, 17), p);
      }
      if (s.powered) {
        c.drawRect(
          Rect.fromLTWH(r.left + 16, r.top + 35, 3, r.height - 70),
          Paint()..color = const Color(0xFFB5FF66),
        );
      }
    }
    if (s.current?.id == 'test') {
      for (final id in s.current!.targets) {
        final test = geometry.rect(id, s);
        final ok = s.targetDone(id);
        c.drawRRect(
          RRect.fromRectAndRadius(test, const Radius.circular(13)),
          Paint()..color = benchInk.withValues(alpha: .9),
        );
        _text(
          c,
          '${ok ? '✓ ' : ''}${rt('r_$id')}',
          test.center,
          14,
          ok ? benchGreen : Colors.white,
          centered: true,
        );
      }
    }
  }

  void _displayBack(
    Canvas c,
    Rect r, {
    required bool fresh,
    bool cover = false,
  }) {
    if (!cover && photo?.display != null) {
      photo!.display!.body(c, r, profile);
      return;
    }
    if (cover) {
      art.rearCover(c, r, inside: true);
      return;
    }
    final k = math.min(1.0, r.width / 224);
    final radius = Radius.circular(28 * k);
    c.drawRRect(
      RRect.fromRectAndRadius(r.shift(Offset(6 * k, 10 * k)), radius),
      Paint()..color = Colors.black45,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, radius),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFA3A6AF), Color(0xFF333941), Color(0xFF959AA0)],
        ).createShader(r),
    );
    final inside = r.deflate(8 * k);
    c.drawRRect(
      RRect.fromRectAndRadius(inside, Radius.circular(22 * k)),
      Paint()..color = const Color(0xFF10151A),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(inside.deflate(14 * k), Radius.circular(14 * k)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF272B31), Color(0xFF12181C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(inside),
    );
    for (final y in [.18, .45, .72]) {
      c.drawRect(
        Rect.fromLTWH(
          r.left + 10 * k,
          r.top + r.height * y,
          r.width - 20 * k,
          14 * k,
        ),
        Paint()..color = const Color(0xFF41474D),
      );
    }
    _text(
      c,
      '${profile.id == 'iphone11' ? 'LCD' : 'OLED'}${fresh ? ' · QC OK' : ''}',
      r.center,
      12 * k,
      fresh ? benchGreen : Colors.white30,
      centered: true,
      spacing: 2 * k,
    );
  }

  void _component(Canvas c, String type, Rect r, {required bool fresh}) {
    if (r.width <= 0 || r.height <= 0) return;
    if (type != 'display') {
      final b =
          type == 'battery'
              ? profile.battery
              : type == 'camera'
              ? profile.camera
              : profile.port;
      final w = math.min(r.width, r.height * b.w / b.h);
      final fitted = Rect.fromCenter(
        center: r.center,
        width: w,
        height: w * b.h / b.w,
      );
      if (photo != null) {
        photo!.part(c, profile, type, fitted);
      } else {
        art.part(c, type, fitted, fresh: fresh);
      }
      return;
    }
    switch (type) {
      case 'display':
        final landscape = r.width > r.height;
        final space = landscape ? Size(r.height, r.width) : r.size;
        final w = math.min(space.width, space.height * .51);
        c.save();
        c.translate(r.center.dx, r.center.dy);
        if (landscape) c.rotate(-math.pi / 2);
        _displayBack(
          c,
          Rect.fromCenter(
            center: Offset.zero,
            width: w,
            height: math.min(space.height, w * 1.96),
          ),
          fresh: fresh,
        );
        c.restore();
        break;
    }
  }

  void _shield(Canvas c, Rect r) {
    if (photo?.spec.sprites.containsKey('shield') == true) {
      photo!.part(c, profile, 'shield', r);
      return;
    }
    final b = profile.shield;
    final w = math.min(r.width, r.height * b.w / b.h);
    art.shield(
      c,
      Rect.fromCenter(center: r.center, width: w, height: w * b.h / b.w),
    );
  }

  void _screw(Canvas c, Offset p, double scale, {int turns = 0}) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    c.rotate(turns * .6);
    c.drawCircle(const Offset(1, 2), 7, Paint()..color = Colors.black87);
    c.drawCircle(
      Offset.zero,
      6.5,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFE1E3E4), Color(0xFF737D87), Color(0xFF353C44)],
        ).createShader(const Rect.fromLTWH(-7, -7, 14, 14)),
    );
    final pnt =
        Paint()
          ..color = const Color(0xFF242A32)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-3, 0), const Offset(3, 0), pnt);
    c.drawLine(const Offset(0, -3), const Offset(0, 3), pnt);
    c.restore();
  }

  void _flex(Canvas c) {
    final g = geometry;
    final socket = profile.connector('display');
    final start =
        g.phone.topLeft +
        Offset(socket.x + socket.w / 2, socket.y + socket.h / 2);
    final end = g.parkedDisplay.centerLeft + const Offset(12, 25);
    final path =
        Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx + 85,
            start.dy + 45,
            end.dx - 50,
            end.dy + 30,
            end.dx,
            end.dy,
          );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF171C22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF38342F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFA58251)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
  }

  void _highlights(Canvas c) {
    final step = session.current!;
    final glow = .45 + .25 * math.sin(pulse * math.pi * 2);
    for (final id in step.targets) {
      if (session.targetDone(id) || dragTarget == id) continue;
      final r = geometry.rect(id, session).inflate(7);
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(14)),
        Paint()..color = benchBlue.withValues(alpha: glow * .18),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(14)),
        Paint()
          ..color = benchBlue.withValues(alpha: glow + .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      if (step.turns > 1) {
        final dot = r.topCenter - const Offset(0, 20);
        c.drawCircle(dot, 16, Paint()..color = benchInk);
        _text(
          c,
          '${session.turnsFor(id)}/${step.turns}',
          dot,
          11,
          benchBlue,
          centered: true,
        );
      }
    }
    if (step.destination != null) {
      final r = geometry.rect(step.destination!, session).inflate(12);
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(20)),
        Paint()
          ..color = benchGreen.withValues(
            alpha: dragTarget == null ? .04 : .15,
          ),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(20)),
        Paint()
          ..color = benchGreen.withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _text(
        c,
        '↓',
        r.bottomCenter + const Offset(0, 20),
        24,
        benchGreen,
        centered: true,
      );
    }
  }

  void _text(
    Canvas c,
    String text,
    Offset p,
    double size,
    Color color, {
    bool centered = false,
    double? spacing,
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, centered ? p - Offset(t.width / 2, t.height / 2) : p);
  }

  @override
  bool shouldRepaint(covariant WorkbenchPainter oldDelegate) => true;
}
