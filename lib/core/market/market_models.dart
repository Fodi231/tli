import 'device_catalog.dart';

class MarketListing {
  final String id, deviceId, seller, city, color;
  final String? fault;
  final int price, ageHours;
  final double rating;
  const MarketListing(
    this.id,
    this.deviceId,
    this.seller,
    this.city,
    this.color,
    this.price,
    this.ageHours,
    this.rating, {
    this.fault,
  });
  DeviceSpec get device => deviceFor(deviceId)!;
  bool get damaged => fault != null;
}

const marketListings = <MarketListing>[
  MarketListing(
    'm01',
    'iphone13',
    'Алексей',
    'Нордкапп',
    'Midnight',
    195,
    1,
    4.9,
    fault: 'display',
  ),
  MarketListing(
    'm02',
    'galaxys23',
    'Мария',
    'Нордкапп',
    'Phantom Black',
    460,
    2,
    5.0,
  ),
  MarketListing(
    'm03',
    'iphone15pro',
    'Даниил',
    'Нордкапп',
    'Natural Titanium',
    390,
    3,
    4.8,
    fault: 'battery',
  ),
  MarketListing(
    'm04',
    'pixel7',
    'Анна',
    'Нордкапп',
    'Obsidian',
    145,
    4,
    4.7,
    fault: 'port',
  ),
  MarketListing('m05', 'iphone12', 'Михаил', 'Нордкапп', 'Blue', 245, 5, 4.9),
  MarketListing(
    'm06',
    'galaxys22',
    'Ольга',
    'Нордкапп',
    'Green',
    160,
    6,
    4.8,
    fault: 'camera',
  ),
  MarketListing(
    'm07',
    'iphone11',
    'Андрей',
    'Нордкапп',
    'Black',
    105,
    7,
    4.6,
    fault: 'battery',
  ),
  MarketListing(
    'm08',
    'iphone13',
    'София',
    'Нордкапп',
    'Starlight',
    370,
    8,
    5.0,
  ),
  MarketListing(
    'm09',
    'iphone15pro',
    'Максим',
    'Нордкапп',
    'Blue Titanium',
    680,
    9,
    4.9,
  ),
  MarketListing(
    'm10',
    'galaxys23',
    'Елена',
    'Нордкапп',
    'Cream',
    245,
    10,
    4.8,
    fault: 'display',
  ),
  MarketListing('m11', 'pixel7', 'Артём', 'Нордкапп', 'Snow', 270, 11, 4.7),
  MarketListing(
    'm12',
    'iphone12',
    'Виктор',
    'Нордкапп',
    'Black',
    120,
    12,
    4.9,
    fault: 'display',
  ),
  MarketListing('m13', 'galaxys22', 'Ирина', 'Нордкапп', 'White', 290, 14, 4.8),
  MarketListing('m14', 'iphone11', 'Никита', 'Нордкапп', 'Green', 205, 16, 4.9),
  MarketListing(
    'm15',
    'iphoneduo',
    'Роман',
    'Нордкапп',
    'Night Sky',
    920,
    17,
    4.8,
    fault: 'display',
  ),
  MarketListing(
    'm16',
    'galaxyfold7',
    'Валерия',
    'Нордкапп',
    'Blue Shadow',
    790,
    18,
    4.9,
    fault: 'battery',
  ),
  MarketListing(
    'm17',
    'matext',
    'Денис',
    'Нордкапп',
    'Red',
    1150,
    19,
    4.7,
    fault: 'port',
  ),
];
MarketListing? listingFor(String id) {
  for (final listing in marketListings) {
    if (listing.id == id) return listing;
  }
  return null;
}

class PlayerListing {
  final String id, stockId, title, description;
  final String? deviceId;
  final List<String> photos;
  final String condition;
  final double price;
  String status;
  PlayerListing({
    required this.id,
    required this.stockId,
    required this.title,
    required this.description,
    required this.price,
    this.deviceId,
    this.photos = const [],
    this.condition = 'used',
    this.status = 'active',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'stock': stockId,
    'title': title,
    'description': description,
    'price': price,
    'device': deviceId,
    'photos': photos,
    'condition': condition,
    'status': status,
  };
  factory PlayerListing.fromJson(Map<String, dynamic> j) => PlayerListing(
    id: j['id'],
    stockId: j['stock'],
    title: j['title'],
    description: j['description'],
    price: (j['price'] as num).toDouble(),
    deviceId: j['device'],
    photos: listingPhotos(j['photos']),
    condition: j['condition'] ?? 'used',
    status: j['status'] ?? 'active',
  );
}

/// Local listing photos are bundled assets or user-selected encoded images.
/// Imported saves cannot turn a photo into an arbitrary network request.
List<String> listingPhotos(dynamic value) {
  if (value is! List) return [];
  var bytes = 0;
  final result = <String>[];
  for (final photo in value.whereType<String>()) {
    final asset = deviceCatalog.any((d) => d.photo == photo);
    final data =
        (photo.startsWith('data:image/jpeg;base64,') ||
            photo.startsWith('data:image/png;base64,')) &&
        photo.length <= 1400000;
    if ((!asset && !data) || bytes + photo.length > 6000000) continue;
    result.add(photo);
    bytes += photo.length;
    if (result.length == 10) break;
  }
  return result;
}

class MarketDraft {
  final String stockId, title, description, price;
  final List<String> photos;
  const MarketDraft({
    required this.stockId,
    required this.title,
    required this.description,
    required this.price,
    this.photos = const [],
  });
  Map<String, dynamic> toJson() => {
    'stock': stockId,
    'title': title,
    'description': description,
    'price': price,
    'photos': photos,
  };
  factory MarketDraft.fromJson(Map<String, dynamic> j) => MarketDraft(
    stockId: j['stock'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    price: j['price'] as String? ?? '',
    photos: listingPhotos(j['photos']),
  );
}
