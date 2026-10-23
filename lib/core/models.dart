import 'dart:math' as math;

class Product {
  final String id, cat, device;
  final double price, rating;
  const Product(this.id, this.cat, this.device, this.price, this.rating);
}

class ServiceDef {
  final String nameKey;
  final String? cat; // part category needed, null = none
  final int min, max;
  const ServiceDef(this.nameKey, this.cat, this.min, this.max);
}

class City {
  final String id;
  final List<String> names; // ru, en, uk
  final double lat, lng;
  final String temp;
  const City(this.id, this.names, this.lat, this.lng, this.temp);

  String name(String lang) {
    final i = const ['ru', 'en', 'uk'].indexOf(lang);
    final n = names[i < 0 ? 0 : i];
    return n.isEmpty ? names[1] : n;
  }

  /// Rough typical temperature for a latitude and the current month
  /// (used for cities picked on the world map; there is no weather service).
  static String approxTemp(double lat, [DateTime? now]) {
    final m = (now ?? DateTime.now()).month;
    final a = lat.abs();
    final peak = lat >= 0 ? 7 : 1;
    final season = (a / 90) * 16 * math.cos((m - peak) * math.pi / 6);
    final t = 29 - 0.55 * a + season;
    return '${t.round()}°C';
  }
}

class DealDevice {
  final String name;
  final int market;
  const DealDevice(this.name, this.market);
}

class Course {
  final String id, nameKey;
  final String? prereq;
  const Course(this.id, this.nameKey, this.prereq);
}

class Order {
  final String id, device, service;
  final double price, lat, lng;
  final String? stockId;
  String status; // available | active | done
  Order({
    required this.id,
    required this.device,
    required this.service,
    required this.price,
    required this.lat,
    required this.lng,
    this.status = 'available',
    this.stockId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'device': device,
    'service': service,
    'price': price,
    'lat': lat,
    'lng': lng,
    'status': status,
    'stockId': stockId,
  };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as String,
    device: j['device'] as String,
    service: j['service'] as String,
    price: (j['price'] as num).toDouble(),
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    status: j['status'] as String? ?? 'available',
    stockId: j['stockId'] as String?,
  );
}

class StockItem {
  final String id, name;
  final double cost, market;
  final String? deviceId, sourceListingId;
  String? fault;
  bool repaired;
  StockItem(
    this.id,
    this.name,
    this.cost,
    this.market, {
    this.deviceId,
    this.sourceListingId,
    this.fault,
    this.repaired = false,
  });
  double get resaleValue => fault == null ? market : market * .52;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cost': cost,
    'market': market,
    'device': deviceId,
    'listing': sourceListingId,
    'fault': fault,
    'repaired': repaired,
  };
  factory StockItem.fromJson(Map<String, dynamic> j) => StockItem(
    j['id'],
    j['name'],
    (j['cost'] as num).toDouble(),
    (j['market'] as num).toDouble(),
    deviceId: j['device'],
    sourceListingId: j['listing'],
    fault: j['fault'],
    repaired: j['repaired'] == true,
  );
}

class ChatMsg {
  final bool mine;
  final String text;
  final bool fallback;
  final DateTime at;
  ChatMsg(this.mine, this.text, {this.fallback = false, DateTime? at})
    : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {
    'mine': mine,
    'text': text,
    'fallback': fallback,
    'at': at.millisecondsSinceEpoch,
  };
  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
    j['mine'] == true,
    j['text'] ?? '',
    fallback: j['fallback'] == true,
    at: j['at'] is int ? DateTime.fromMillisecondsSinceEpoch(j['at']) : null,
  );
}

class Deal {
  final String id, kind, item, counterpart;
  final double market, ask, limit;
  final String? listingId, deviceId, fault;
  final String description;
  String? stockId;
  String status = 'open'; // open | agreed | won | lost
  int rounds = 0;
  bool busy = false;
  double price = 0;
  final List<ChatMsg> messages = [];
  double get currentPrice => price > 0 ? price : ask;
  Deal({
    required this.id,
    required this.kind,
    required this.item,
    required this.counterpart,
    required this.market,
    required this.ask,
    required this.limit,
    this.listingId,
    this.deviceId,
    this.fault,
    this.description = '',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'item': item,
    'name': counterpart,
    'market': market,
    'ask': ask,
    'limit': limit,
    'listing': listingId,
    'device': deviceId,
    'fault': fault,
    'description': description,
    'stock': stockId,
    'status': status,
    'rounds': rounds,
    'price': price,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
  factory Deal.fromJson(Map<String, dynamic> j) {
    final d = Deal(
      id: j['id'],
      kind: j['kind'],
      item: j['item'],
      counterpart: j['name'],
      market: (j['market'] as num).toDouble(),
      ask: (j['ask'] as num).toDouble(),
      limit: (j['limit'] as num).toDouble(),
      listingId: j['listing'],
      deviceId: j['device'],
      fault: j['fault'],
      description: j['description'] ?? '',
    );
    d.stockId = j['stock'];
    d.status = j['status'] ?? 'open';
    d.rounds = j['rounds'] ?? 0;
    d.price = (j['price'] as num? ?? 0).toDouble();
    d.messages.addAll(
      (j['messages'] as List? ?? []).map(
        (m) => ChatMsg.fromJson(Map<String, dynamic>.from(m)),
      ),
    );
    return d;
  }
}

class AppNotification {
  final String type, titleKey, body;
  final DateTime time;
  bool read = false;
  AppNotification(this.type, this.titleKey, this.body) : time = DateTime.now();
}

class Txn {
  final String title;
  final double amount;
  final DateTime time;
  Txn(this.title, this.amount, [DateTime? t]) : time = t ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    't': title,
    'a': amount,
    'ts': time.millisecondsSinceEpoch,
  };
  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
    j['t'],
    (j['a'] as num).toDouble(),
    DateTime.fromMillisecondsSinceEpoch(j['ts']),
  );
}
