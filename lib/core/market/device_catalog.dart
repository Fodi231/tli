class DeviceSpec {
  final String id, name, brand, chip, screen, storage;
  final int market, batteryMah;
  final String source;
  const DeviceSpec(
    this.id,
    this.name,
    this.brand,
    this.chip,
    this.screen,
    this.storage,
    this.market,
    this.batteryMah,
    this.source,
  );
  String get photo => 'assets/market/$id.jpg';
  String get facts =>
      '$screen · $chip · $storage${batteryMah > 0 ? ' · $batteryMah mAh' : ''}';
  int get panels =>
      id == 'matext'
          ? 3
          : (id == 'galaxyfold7' || id == 'iphoneduo')
          ? 2
          : 1;
  bool get apple => brand == 'Apple';

  /// Built-in magnetic alignment, not ordinary Qi charging or a magnetic case.
  bool get magSafe =>
      const {'iphone12', 'iphone13', 'iphone15pro', 'iphoneduo'}.contains(id);
  bool get wirelessCharging => true;
  String get system =>
      apple
          ? 'iOS'
          : brand == 'Samsung'
          ? 'One UI'
          : brand == 'HUAWEI'
          ? 'HarmonyOS'
          : 'Android';
  double get closedAspect => switch (id) {
    'iphoneduo' => 84.1 / 117.8,
    'galaxyfold7' => 72.8 / 158.4,
    'matext' => 73.5 / 156.7,
    'iphone11' => 75.7 / 150.9,
    'iphone12' || 'iphone13' => 71.5 / 146.7,
    'iphone15pro' => 70.6 / 146.6,
    'galaxys22' => 70.6 / 146.0,
    'galaxys23' => 70.9 / 146.3,
    'pixel7' => 73.2 / 155.6,
    _ => .5114,
  };
  int get bootMs =>
      apple
          ? 12000
          : brand == 'HUAWEI'
          ? 14000
          : 11000;
}

const deviceCatalog = <DeviceSpec>[
  DeviceSpec(
    'iphone11',
    'iPhone 11',
    'Apple',
    'A13 Bionic',
    '6.1″ LCD',
    '128 GB',
    230,
    3110,
    'https://support.apple.com/en-us/111865',
  ),
  DeviceSpec(
    'iphone12',
    'iPhone 12',
    'Apple',
    'A14 Bionic',
    '6.1″ OLED',
    '128 GB',
    280,
    2815,
    'https://support.apple.com/en-us/111876',
  ),
  DeviceSpec(
    'iphone13',
    'iPhone 13',
    'Apple',
    'A15 Bionic',
    '6.1″ OLED',
    '128 GB',
    420,
    3227,
    'https://support.apple.com/en-us/111872',
  ),
  DeviceSpec(
    'iphone15pro',
    'iPhone 15 Pro',
    'Apple',
    'A17 Pro',
    '6.1″ OLED · 120 Hz',
    '256 GB',
    740,
    3274,
    'https://support.apple.com/en-us/111829',
  ),
  DeviceSpec(
    'galaxys22',
    'Galaxy S22',
    'Samsung',
    'Snapdragon 8 Gen 1',
    '6.1″ AMOLED · 120 Hz',
    '128 GB',
    330,
    3700,
    'https://www.ifixit.com/Device/Samsung_Galaxy_S22',
  ),
  DeviceSpec(
    'galaxys23',
    'Galaxy S23',
    'Samsung',
    'Snapdragon 8 Gen 2',
    '6.1″ AMOLED · 120 Hz',
    '256 GB',
    520,
    3900,
    'https://www.ifixit.com/Device/Samsung_Galaxy_S23',
  ),
  DeviceSpec(
    'pixel7',
    'Pixel 7',
    'Google',
    'Google Tensor G2',
    '6.3″ OLED · 90 Hz',
    '128 GB',
    300,
    4355,
    'https://www.ifixit.com/Device/Google_Pixel_7',
  ),
  DeviceSpec(
    'iphoneduo',
    'iPhone Duo',
    'Apple',
    'A20 Pro',
    '5.4″ / 7.6″ OLED · 120 Hz',
    '256 GB',
    1700,
    0,
    'https://www.apple.com/iphone-duo/specs/',
  ),
  DeviceSpec(
    'galaxyfold7',
    'Galaxy Z Fold7',
    'Samsung',
    'Snapdragon 8 Elite for Galaxy',
    '6.5″ / 8.0″ AMOLED · 120 Hz',
    '256 GB',
    1450,
    4400,
    'https://www.samsung.com/uk/smartphones/galaxy-z-fold7/specs/',
  ),
  DeviceSpec(
    'matext',
    'HUAWEI Mate XT',
    'HUAWEI',
    'Kirin',
    '6.4″ / 7.9″ / 10.2″ OLED',
    '512 GB',
    2100,
    5600,
    'https://consumer.huawei.com/en/phones/mate-xt-ultimate-design/specs/',
  ),
];
DeviceSpec? deviceFor(String value) {
  for (final d in deviceCatalog) {
    if (d.id == value || d.name == value) return d;
  }
  return null;
}
