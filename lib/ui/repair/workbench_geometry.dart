import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../core/repair/repair_session.dart';

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
    switch (id) {
      case 'screen':
        return s.isOpen ? parkedDisplay : p.deflate(8);
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
      case 'battery':
        return at(22, 132, 126, 230);
      case 'camera':
        return at(20, 24, 104, 86);
      case 'port':
        return at(32, 385, 160, 30);
      case 'shield':
        return at(157, 195, 45, 112);
      case 'battery_connector':
        return at(150, 277, 32, 20);
      case 'part_connector':
        return at(150, 234, 32, 20);
      case 'frame_0':
        return at(49, 421, 18, 18);
      case 'frame_1':
        return at(157, 421, 18, 18);
      case 'shield_0':
        return at(167, 190, 18, 18);
      case 'shield_1':
        return at(187, 242, 18, 18);
      case 'shield_2':
        return at(164, 300, 18, 18);
      case 'adhesive_0':
        return at(45, 350, 25, 30);
      case 'adhesive_1':
        return at(100, 350, 25, 30);
      case 'part_0':
        return s.service == 'camera' ? at(15, 21, 18, 18) : at(26, 380, 18, 18);
      case 'part_1':
        return s.service == 'camera'
            ? at(114, 100, 18, 18)
            : at(182, 380, 18, 18);
      case 'part_2':
        return at(106, 400, 18, 18);
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
