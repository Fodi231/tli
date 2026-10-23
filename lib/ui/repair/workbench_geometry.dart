import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../core/repair/repair_session.dart';
import '../../core/repair/device_profile.dart';

/// A single coordinate system shared by rendering, hit testing and drop zones.
class WorkbenchGeometry {
  final bool wide;
  WorkbenchGeometry(this.wide);
  Size get size => wide ? const Size(1000, 680) : const Size(700, 820);
  Rect get phone => Rect.fromLTWH(wide ? 335 : 78, wide ? 104 : 160, 224, 438);
  Rect get parkedDisplay =>
      Rect.fromLTWH(wide ? 640 : 396, phone.top + 4, 224, 438);
  Rect get newTray =>
      wide
          ? const Rect.fromLTWH(52, 104, 215, 158)
          : const Rect.fromLTWH(396, 28, 224, 102);
  Rect get oldTray =>
      wide
          ? const Rect.fromLTWH(52, 304, 215, 158)
          : const Rect.fromLTWH(396, 660, 224, 110);
  Rect get partsTray =>
      wide
          ? const Rect.fromLTWH(52, 505, 215, 114)
          : const Rect.fromLTWH(78, 660, 224, 110);

  Rect rect(String id, RepairSession s) {
    final p = phone;
    Rect at(double x, double y, double w, double h) =>
        Rect.fromLTWH(p.left + x, p.top + y, w, h);
    final profile = profileFor(s.device);
    Rect box(PartBox b) => at(b.x, b.y, b.w, b.h);
    if (id == 'battery') return box(profile.battery);
    if (id == 'adhesive_edge') {
      return at(
        profile.battery.x - 5,
        profile.battery.y + 35,
        24,
        profile.battery.h - 60,
      );
    }
    if (id == 'camera') return box(profile.camera);
    if (id == 'port') return box(profile.port);
    if (id == 'shield') return box(profile.shield);
    if (id == 'battery_connector') return box(profile.connector('battery'));
    if (id == 'part_connector') {
      return box(
        profile.connector(
          s.service == 'battery'
              ? (profile.rearAccess ? 'port' : 'display')
              : s.service,
        ),
      );
    }
    if (id == 'interconnect_1') return at(124, 348, 30, 16);
    if (id.startsWith('shield_')) {
      final i = int.tryParse(id.split('_').last) ?? 0;
      final b = profile.shield;
      return at(
        b.x + (i.isEven ? 3 : b.w - 19),
        b.y +
            3 +
            (i ~/ 2) *
                (b.h - 22) /
                ((profile.shieldScrews - 1) ~/ 2).clamp(1, 10),
        18,
        18,
      );
    }
    if (id.startsWith('adhesive_')) {
      final i = int.tryParse(id.split('_').last) ?? 0;
      final b = profile.battery;
      if (profile.id == 'galaxys23') {
        return at(b.x + b.w / 2 - 16, b.y + b.h / 2 - 17, 32, 34);
      }
      final rowCount =
          profile.adhesiveTabs > 3
              ? profile.adhesiveTabs ~/ 2
              : profile.adhesiveTabs;
      final top = profile.adhesiveTabs > 3 && i >= rowCount;
      final col = i % rowCount.clamp(1, 6);
      return at(
        b.x + 15 + col * (b.w - 53) / (rowCount - 1).clamp(1, 5),
        top ? b.y - 8 : b.y + b.h - 13,
        23,
        25,
      );
    }
    if (id == 'part_0' || id == 'part_1' || id == 'part_2') {
      final b = s.service == 'camera' ? profile.camera : profile.port;
      final i = int.parse(id.split('_').last);
      return at(
        b.x +
            (i == 0
                ? -4
                : i == 1
                ? b.w - 14
                : b.w / 2),
        b.y + (i == 1 ? b.h - 14 : -4),
        18,
        18,
      );
    }
    switch (id) {
      case 'screen':
        return s.isOpen ? parkedDisplay : p.deflate(8);
      case 'front_display':
      case 'display_mount':
      case 'chassis':
        return p;
      case 'display_park':
        return parkedDisplay;
      case 'new_part':
        return newTray.deflate(24);
      case 'old_tray':
        return oldTray;
      case 'parts_tray':
        return partsTray;
      case 'stored_shield':
        return partsTray.deflate(28);
      case 'power':
        return at(211, 85, 24, 62);
      case 'frame_0':
        return at(49, 421, 18, 18);
      case 'frame_1':
        return at(157, 421, 18, 18);
      case 'test_screen':
        return at(44, 125, 136, 72);
      case 'test_camera':
        return at(44, 219, 136, 72);
      case 'test_charge':
        return at(44, 313, 136, 72);
      default:
        return p;
    }
  }

  String? hit(Offset point, RepairSession s, double scale) {
    bool contains(String id) {
      final r = rect(id, s);
      final extra = math.max(
        0.0,
        (44 / scale - math.min(r.width, r.height)) / 2,
      );
      return r.inflate(extra).contains(point);
    }

    // Small screw heads have a 44 px touch target, also after zooming out.
    final pending =
        s.current?.targets.where((id) => !s.targetDone(id)).toList() ??
        <String>[];
    final nearby =
        pending.where(contains).toList()..sort(
          (a, b) => (rect(a, s).center - point).distance.compareTo(
            (rect(b, s).center - point).distance,
          ),
        );
    if (nearby.isNotEmpty) return nearby.first;
    final visible = [
      if (!s.newPartInstalled && s.service != 'diag') 'new_part',
      if (s.shieldRemoved) 'stored_shield',
      'power',
      'frame_0',
      'frame_1',
      if (s.isOpen) ...[
        'shield_0',
        'shield_1',
        'shield_2',
        'battery_connector',
        'part_connector',
        'shield',
        'camera',
        'port',
        'battery',
      ],
      if (!(s.service == 'display' && s.partRemoved)) 'screen',
    ];
    for (final id in visible) {
      if (rect(id, s).contains(point)) return id;
    }
    return null;
  }

  String? dropZone(Offset point, RepairSession s) {
    final expected = s.current?.destination;
    if (expected != null && rect(expected, s).inflate(24).contains(point)) {
      return expected;
    }
    return null;
  }
}
