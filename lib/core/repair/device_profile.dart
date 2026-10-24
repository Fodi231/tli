import '../market/device_catalog.dart';

/// Original game artwork coordinates in a 224 × 438 chassis. These describe
/// the service-side view, so camera positions differ from a rear product photo.
/// Sources and deliberately simplified fasteners are documented in ASSET_NOTES.
class PartBox {
  final double x, y, w, h;
  const PartBox(this.x, this.y, this.w, this.h);
}

class Lens {
  final double x, y, r;
  const Lens(this.x, this.y, this.r);
}

class DeviceProfile {
  final String id, batteryCode, access, portType;
  final PartBox battery, camera, board, shield;
  final List<Lens> lenses;
  final double batterySocketX, batterySocketY, displaySocketX, displaySocketY;
  final bool rearAccess, lBattery;
  final int shieldScrews;
  final int segments;
  final List<PartBox> auxiliaryBatteries;
  const DeviceProfile({
    required this.id,
    required this.batteryCode,
    required this.access,
    required this.battery,
    required this.camera,
    required this.board,
    required this.shield,
    required this.lenses,
    required this.batterySocketX,
    required this.batterySocketY,
    required this.displaySocketX,
    required this.displaySocketY,
    this.rearAccess = false,
    this.lBattery = false,
    this.shieldScrews = 3,
    this.portType = 'Lightning',
    this.segments = 1,
    this.auxiliaryBatteries = const [],
  });
  int get adhesiveTabs => switch (id) {
    'iphone11' => 6,
    'iphone12' || 'iphone13' => 4,
    'iphone15pro' => 3,
    'galaxys22' => 0,
    'galaxys23' => 1,
    _ => 2,
  };
  bool get pixel => id == 'pixel7';
  bool get apple => id.startsWith('iphone');
  String get manufacturer => deviceFor(id)!.brand;
  String get modelName => deviceFor(id)!.name;
  bool get frameScrews => apple && !rearAccess;
  double get bodyWidth =>
      segments == 1
          ? deviceFor(id)!.closedAspect * 438
          : id == 'iphoneduo'
          ? 612.0
          : id == 'matext'
          ? 612.2
          : 448.0;
  int get batteryMah => deviceFor(id)!.batteryMah;
  PartBox get port =>
      id == 'iphoneduo'
          ? const PartBox(74, 393, 113, 28)
          : segments > 1
          ? PartBox(224.0 * (segments - 1) + 30, 382, 162, 35)
          : rearAccess
          ? const PartBox(31, 378, 162, 39)
          : const PartBox(30, 389, 162, 29);
  PartBox connector(String type) {
    if (type == 'battery') {
      return PartBox(batterySocketX, batterySocketY, 26, 14);
    }
    if (type == 'display') {
      return PartBox(displaySocketX, displaySocketY, 26, 14);
    }
    if (type == 'camera') return PartBox(board.x + 7, board.y + 38, 26, 14);
    return rearAccess
        ? const PartBox(123, 132, 26, 14)
        : PartBox(board.x + 8, board.y + board.h - 28, 26, 14);
  }
}

const repairProfiles = <DeviceProfile>[
  DeviceProfile(
    id: 'iphone11',
    batteryCode: 'iPhone 11 · 11.91 Wh',
    access: 'front',
    battery: PartBox(82, 123, 124, 234),
    camera: PartBox(17, 24, 76, 97),
    board: PartBox(17, 117, 57, 247),
    shield: PartBox(20, 191, 56, 108),
    lenses: [Lens(.47, .27, .22), Lens(.47, .72, .22)],
    batterySocketX: 48,
    batterySocketY: 270,
    displaySocketX: 47,
    displaySocketY: 221,
  ),
  DeviceProfile(
    id: 'iphone12',
    batteryCode: 'iPhone 12 · 10.78 Wh',
    access: 'front',
    battery: PartBox(17, 130, 130, 231),
    camera: PartBox(139, 23, 69, 99),
    board: PartBox(153, 119, 54, 246),
    shield: PartBox(151, 216, 55, 105),
    lenses: [Lens(.49, .28, .24), Lens(.49, .73, .24)],
    batterySocketX: 151,
    batterySocketY: 288,
    displaySocketX: 158,
    displaySocketY: 246,
  ),
  DeviceProfile(
    id: 'iphone13',
    batteryCode: 'iPhone 13 · 12.41 Wh',
    access: 'front',
    battery: PartBox(78, 125, 130, 237),
    camera: PartBox(17, 25, 92, 94),
    board: PartBox(17, 127, 53, 238),
    shield: PartBox(19, 205, 53, 93),
    lenses: [Lens(.28, .29, .24), Lens(.71, .72, .24)],
    batterySocketX: 43,
    batterySocketY: 272,
    displaySocketX: 42,
    displaySocketY: 232,
  ),
  DeviceProfile(
    id: 'iphone15pro',
    batteryCode: 'iPhone 15 Pro · 12.70 Wh',
    access: 'front',
    battery: PartBox(77, 143, 131, 229),
    camera: PartBox(62, 24, 145, 113),
    board: PartBox(17, 54, 53, 273),
    shield: PartBox(18, 203, 56, 91),
    lenses: [Lens(.23, .28, .205), Lens(.73, .29, .205), Lens(.48, .75, .205)],
    batterySocketX: 43,
    batterySocketY: 278,
    displaySocketX: 43,
    displaySocketY: 240,
    lBattery: false,
    portType: 'USB-C',
  ),
  DeviceProfile(
    id: 'galaxys22',
    batteryCode: 'EB-BS901ABY · 14.36 Wh',
    access: 'rear',
    battery: PartBox(29, 145, 169, 218),
    camera: PartBox(17, 26, 47, 113),
    board: PartBox(70, 24, 136, 115),
    shield: PartBox(17, 117, 191, 254),
    lenses: [Lens(.5, .17, .32), Lens(.5, .50, .32), Lens(.5, .84, .32)],
    batterySocketX: 160,
    batterySocketY: 135,
    displaySocketX: 76,
    displaySocketY: 128,
    rearAccess: true,
    shieldScrews: 6,
    portType: 'USB-C',
  ),
  DeviceProfile(
    id: 'galaxys23',
    batteryCode: 'EB-BS912ABY · 15.13 Wh',
    access: 'rear',
    battery: PartBox(27, 151, 171, 211),
    camera: PartBox(18, 24, 49, 120),
    board: PartBox(75, 22, 131, 122),
    shield: PartBox(18, 118, 189, 252),
    lenses: [Lens(.5, .17, .33), Lens(.5, .50, .33), Lens(.5, .83, .33)],
    batterySocketX: 163,
    batterySocketY: 142,
    displaySocketX: 72,
    displaySocketY: 135,
    rearAccess: true,
    shieldScrews: 6,
    portType: 'USB-C',
  ),
  DeviceProfile(
    id: 'pixel7',
    batteryCode: 'GZE8U · 16.81 Wh',
    access: 'front',
    battery: PartBox(84, 127, 121, 236),
    camera: PartBox(17, 29, 118, 67),
    board: PartBox(17, 105, 60, 274),
    shield: PartBox(17, 101, 190, 278),
    lenses: [Lens(.25, .5, .30), Lens(.73, .5, .26)],
    batterySocketX: 53,
    batterySocketY: 211,
    displaySocketX: 43,
    displaySocketY: 178,
    shieldScrews: 6,
    portType: 'USB-C',
  ),
  DeviceProfile(
    id: 'iphoneduo',
    batteryCode: 'Dual battery',
    access: 'rear',
    segments: 2,
    battery: PartBox(20, 119, 177, 263),
    auxiliaryBatteries: [PartBox(249, 100, 175, 266)],
    camera: PartBox(28, 29, 100, 80),
    board: PartBox(143, 102, 74, 160),
    shield: PartBox(153, 133, 58, 140),
    lenses: [Lens(.25, .5, .22), Lens(.73, .5, .22)],
    batterySocketX: 151,
    batterySocketY: 270,
    displaySocketX: 174,
    displaySocketY: 225,
    rearAccess: true,
    shieldScrews: 6,
    portType: 'USB-C',
  ),
  DeviceProfile(
    id: 'galaxyfold7',
    batteryCode: 'Dual battery · 4400 mAh',
    access: 'rear',
    segments: 2,
    battery: PartBox(35, 181, 164, 204),
    auxiliaryBatteries: [PartBox(270, 98, 145, 288)],
    camera: PartBox(34, 20, 54, 142),
    board: PartBox(102, 24, 105, 125),
    shield: PartBox(105, 30, 100, 117),
    lenses: [Lens(.5, .17, .28), Lens(.5, .50, .28), Lens(.5, .83, .28)],
    batterySocketX: 166,
    batterySocketY: 129,
    displaySocketX: 322,
    displaySocketY: 133,
    rearAccess: true,
    shieldScrews: 6,
    portType: 'USB-C',
  ),
  DeviceProfile(
    id: 'matext',
    batteryCode: 'Distributed battery · 5600 mAh',
    access: 'rear',
    segments: 3,
    battery: PartBox(40, 214, 153, 184),
    auxiliaryBatteries: [
      PartBox(252, 87, 170, 313),
      PartBox(478, 96, 173, 307),
    ],
    camera: PartBox(44, 50, 104, 115),
    board: PartBox(132, 24, 75, 130),
    shield: PartBox(152, 44, 53, 110),
    lenses: [Lens(.27, .25, .21), Lens(.74, .25, .21), Lens(.5, .72, .23)],
    batterySocketX: 166,
    batterySocketY: 109,
    displaySocketX: 559,
    displaySocketY: 153,
    rearAccess: true,
    shieldScrews: 6,
    portType: 'USB-C',
  ),
];

DeviceProfile profileFor(String device) {
  final id = deviceFor(device)?.id ?? device;
  return repairProfiles.firstWhere(
    (p) => p.id == id,
    orElse: () => repairProfiles[2],
  );
}
