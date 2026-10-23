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
];
MarketListing? listingFor(String id) {
  for (final listing in marketListings) {
    if (listing.id == id) return listing;
  }
  return null;
}

class PlayerListing {
  final String id, stockId, title, description;
  final double price;
  String status;
  PlayerListing({
    required this.id,
    required this.stockId,
    required this.title,
    required this.description,
    required this.price,
    this.status = 'active',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'stock': stockId,
    'title': title,
    'description': description,
    'price': price,
    'status': status,
  };
  factory PlayerListing.fromJson(Map<String, dynamic> j) => PlayerListing(
    id: j['id'],
    stockId: j['stock'],
    title: j['title'],
    description: j['description'],
    price: (j['price'] as num).toDouble(),
    status: j['status'] ?? 'active',
  );
}
