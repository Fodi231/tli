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
  String get facts => '$screen · $chip · $storage · $batteryMah mAh';
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
];
DeviceSpec? deviceFor(String value) {
  for (final d in deviceCatalog) {
    if (d.id == value || d.name == value) return d;
  }
  return null;
}
