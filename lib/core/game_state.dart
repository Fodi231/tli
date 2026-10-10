import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import 'catalog.dart';
import 'i18n.dart';
import 'models.dart';

class GameState extends ChangeNotifier {
  final Random _rng = Random();
  SharedPreferences? _prefs;
  Timer? _timer;
  int _idSeq = 0;
  bool ready = false;

  double balance = 1500;
  double reputation = 4.0;
  int cityIndex = 0;
  String lang = 'ru';
  String geminiKey = '';
  Map<String, int> parts = {};
  Map<String, double> courseProgress = {};
  double loan = 0, invested = 0, taxDue = 0;
  bool insured = false;
  int completedOrders = 0;
  double totalEarned = 0;
  List<Order> orders = [];
  List<StockItem> stock = [];
  List<Deal> deals = [];
  List<AppNotification> notifications = [];
  List<Txn> txns = [];
  late LatLng player;

  // --- appearance / settings
  String playerName = '';
  int wallpaperIndex = 0;
  String? wallpaperB64;
  Uint8List? wallpaperBytes;
  double wallpaperDim = 0;
  double textScale = 1.0;
  bool haptics = true, notifOrders = true, notifDeals = true;

  // --- network / AI
  static const String _builtInKey = String.fromEnvironment('GEMINI_API_KEY');
  bool online = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  String get aiKey => geminiKey.isNotEmpty ? geminiKey : _builtInKey;
  bool get hasBuiltInKey => _builtInKey.isNotEmpty;

  City get city => cities[cityIndex];
  int get unreadCount => notifications.where((n) => !n.read).length;
  int get openDeals => deals.where((d) => d.status == 'open').length;
  int get certCount => courseProgress.values.where((v) => v >= 1).length;
  bool hasCert(String id) => (courseProgress[id] ?? 0) >= 1;
  double get netWorth =>
      balance + invested + stock.fold(0.0, (s, e) => s + e.market) - loan - taxDue;

  String nextId() => '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  // ---------------------------------------------------------------- init
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString('save');
    if (raw != null) {
      try {
        _load(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    I18n.lang = lang;
    player = LatLng(city.lat, city.lng);
    _seedWorld();
    try {
      final c = Connectivity();
      online = (await c.checkConnectivity()).any((r) => r != ConnectivityResult.none);
      _connSub = c.onConnectivityChanged.listen((list) {
        final v = list.any((r) => r != ConnectivityResult.none);
        if (v != online) {
          online = v;
          notifyListeners();
        }
      });
    } catch (_) {}
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
    ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  void _seedWorld() {
    while (orders.where((o) => o.status == 'available').length < 4) {
      _spawnOrder(silent: true);
    }
    if (deals.isEmpty) {
      spawnDeal('buy', silent: true);
      spawnDeal('buy', silent: true);
    }
  }

  void _load(Map<String, dynamic> j) {
    balance = (j['balance'] as num? ?? balance).toDouble();
    reputation = (j['rep'] as num? ?? reputation).toDouble();
    cityIndex = ((j['city'] as int?) ?? 0).clamp(0, cities.length - 1).toInt();
    lang = (j['lang'] as String?) ?? 'ru';
    geminiKey = (j['key'] as String?) ?? '';
    parts = Map<String, int>.from((j['parts'] as Map?) ?? {});
    courseProgress = ((j['courses'] as Map?) ?? {})
        .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    loan = (j['loan'] as num? ?? 0).toDouble();
    invested = (j['invested'] as num? ?? 0).toDouble();
    taxDue = (j['tax'] as num? ?? 0).toDouble();
    insured = (j['insured'] as bool?) ?? false;
    completedOrders = (j['completed'] as int?) ?? 0;
    totalEarned = (j['earned'] as num? ?? 0).toDouble();
    stock = ((j['stock'] as List?) ?? [])
        .map((e) => StockItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    txns = ((j['txns'] as List?) ?? [])
        .map((e) => Txn.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    playerName = (j['pname'] as String?) ?? '';
    wallpaperIndex = (j['wp'] as int?) ?? 0;
    wallpaperB64 = j['wpimg'] as String?;
    if (wallpaperB64 != null) {
      try {
        wallpaperBytes = base64Decode(wallpaperB64!);
      } catch (_) {
        wallpaperB64 = null;
      }
    }
    wallpaperDim = (j['wpdim'] as num? ?? 0).toDouble();
    textScale = (j['tscale'] as num? ?? 1.0).toDouble();
    haptics = (j['haptics'] as bool?) ?? true;
    notifOrders = (j['nord'] as bool?) ?? true;
    notifDeals = (j['ndeal'] as bool?) ?? true;
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString(
      'save',
      jsonEncode({
        'balance': balance,
        'rep': reputation,
        'city': cityIndex,
        'lang': lang,
        'key': geminiKey,
        'parts': parts,
        'courses': courseProgress,
        'loan': loan,
        'invested': invested,
        'tax': taxDue,
        'insured': insured,
        'completed': completedOrders,
        'earned': totalEarned,
        'stock': stock.map((e) => e.toJson()).toList(),
        'txns': txns.take(40).map((e) => e.toJson()).toList(),
        'pname': playerName,
        'wp': wallpaperIndex,
        'wpimg': wallpaperB64,
        'wpdim': wallpaperDim,
        'tscale': textScale,
        'haptics': haptics,
        'nord': notifOrders,
        'ndeal': notifDeals,
      }),
    );
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _prefs?.remove('save');
    balance = 1500;
    reputation = 4.0;
    cityIndex = 0;
    parts = {};
    courseProgress = {};
    loan = invested = taxDue = 0;
    insured = false;
    completedOrders = 0;
    totalEarned = 0;
    orders = [];
    stock = [];
    deals = [];
    notifications = [];
    txns = [];
    player = LatLng(city.lat, city.lng);
    _seedWorld();
    _changed();
  }

  // ------------------------------------------------------------ settings
  void setLang(String l) {
    lang = l;
    I18n.lang = l;
    _changed();
  }

  void setKey(String k) {
    geminiKey = k.trim();
    _changed();
  }

  void setPlayerName(String n) {
    playerName = n.trim();
    _changed();
  }

  void setWallpaperPreset(int i) {
    wallpaperIndex = i;
    wallpaperB64 = null;
    wallpaperBytes = null;
    _changed();
  }

  void setWallpaperImage(Uint8List bytes) {
    wallpaperBytes = bytes;
    wallpaperB64 = base64Encode(bytes);
    _changed();
  }

  void setWallpaperDim(double v) {
    wallpaperDim = v;
    _changed();
  }

  void setTextScale(double v) {
    textScale = v;
    _changed();
  }

  void setHaptics(bool v) {
    haptics = v;
    _changed();
  }

  void setNotifOrders(bool v) {
    notifOrders = v;
    _changed();
  }

  void setNotifDeals(bool v) {
    notifDeals = v;
    _changed();
  }

  // --------------------------------------------------------------- money
  void _income(String title, double amt) {
    balance += amt;
    totalEarned += amt;
    taxDue += amt * 0.1;
    txns.insert(0, Txn(title, amt));
  }

  void _spend(String title, double amt) {
    balance -= amt;
    txns.insert(0, Txn(title, -amt));
  }

  void _note(String type, String titleKey, String body) {
    notifications.insert(0, AppNotification(type, titleKey, body));
    if (notifications.length > 50) notifications.removeLast();
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- tick
  void _tick() {
    if (orders.where((o) => o.status == 'available').length < 6 && _rng.nextDouble() < 0.6) {
      _spawnOrder();
    }
    if (openDeals < 4 && _rng.nextDouble() < 0.3) {
      spawnDeal('buy');
    }
    if (invested > 0) invested *= 1 + (_rng.nextDouble() * 0.05 - 0.02);
    if (loan > 0) loan *= 1.002;
    _changed();
  }

  void _spawnOrder({bool silent = false}) {
    final keys = services.keys.toList();
    final k = keys[_rng.nextInt(keys.length)];
    final s = services[k]!;
    final price = (s.min + _rng.nextInt(s.max - s.min + 1)).toDouble();
    final dev = devices[_rng.nextInt(devices.length)];
    final c = city;
    orders.add(Order(
      id: nextId(),
      device: dev,
      service: k,
      price: price,
      lat: c.lat + (_rng.nextDouble() - 0.5) * 0.08,
      lng: c.lng + (_rng.nextDouble() - 0.5) * 0.1,
    ));
    if (!silent && notifOrders) _note('order', 'n_order', '${s.nameKey.tr} · $dev');
  }

  // -------------------------------------------------------------- orders
  double distanceKm(double lat, double lng) =>
      const Distance().as(LengthUnit.Kilometer, player, LatLng(lat, lng));

  void acceptOrder(Order o) {
    o.status = 'active';
    _changed();
  }

  bool hasPartFor(Order o) {
    final cat = services[o.service]!.cat;
    return cat == null || (parts[cat] ?? 0) > 0;
  }

  /// Returns the reward that was paid.
  double completeRepair(Order o, int mistakes) {
    final s = services[o.service]!;
    if (s.cat != null) parts[s.cat!] = max(0, (parts[s.cat!] ?? 0) - 1);
    final f = (1 - 0.12 * mistakes * (insured ? 0.5 : 1)).clamp(0.4, 1.0).toDouble();
    var reward = o.price * f * (1 + 0.05 * certCount);
    reward = reward.roundToDouble();
    o.status = 'done';
    completedOrders++;
    final delta = mistakes == 0 ? 0.04 : (mistakes > 3 ? -0.08 : -0.01);
    reputation = (reputation + delta).clamp(1.0, 5.0).toDouble();
    _income(s.nameKey.tr, reward);
    _note('money', 'n_pay', '+\$${reward.toInt()}');
    _changed();
    return reward;
  }

  // ---------------------------------------------------------------- shop
  bool buyPart(Product p) {
    if (balance < p.price) return false;
    _spend('${'part_${p.cat}'.tr} · ${p.device}', p.price);
    parts[p.cat] = (parts[p.cat] ?? 0) + 1;
    _changed();
    return true;
  }

  // ----------------------------------------------------------------- map
  /// Moves the player, returns the fare or -1 if there is not enough money.
  double movePlayer(LatLng p) {
    final km = const Distance().as(LengthUnit.Kilometer, player, p);
    final fare = max(1.0, (km * 0.8).roundToDouble());
    if (fare > balance) return -1;
    _spend('fare'.tr, fare);
    player = p;
    _changed();
    return fare;
  }

  bool flyTo(int i) {
    if (i == cityIndex) return true;
    if (balance < 150) return false;
    _spend('fly'.tr, 150);
    cityIndex = i;
    player = LatLng(city.lat, city.lng);
    orders.removeWhere((o) => o.status == 'available');
    for (var n = 0; n < 4; n++) {
      _spawnOrder(silent: true);
    }
    _changed();
    return true;
  }

  // ---------------------------------------------------------------- bank
  void takeLoan() {
    loan += 1000;
    balance += 1000;
    txns.insert(0, Txn('credits'.tr, 1000));
    _changed();
  }

  void repayLoan() {
    final a = min(500.0, min(loan, balance));
    if (a <= 0) return;
    loan -= a;
    _spend('credits'.tr, a);
    _changed();
  }

  void investMoney() {
    final a = min(500.0, balance);
    if (a <= 0) return;
    invested += a;
    _spend('invest'.tr, a);
    _changed();
  }

  void withdrawInvest() {
    if (invested <= 0) return;
    balance += invested;
    txns.insert(0, Txn('invest'.tr, invested));
    invested = 0;
    _changed();
  }

  void payTaxes() {
    final a = min(taxDue, balance);
    if (a <= 0) return;
    taxDue -= a;
    _spend('taxes'.tr, a);
    _changed();
  }

  bool buyInsurance() {
    if (insured || balance < 200) return false;
    insured = true;
    _spend('insurance'.tr, 200);
    _changed();
    return true;
  }

  // ------------------------------------------------------------ learning
  bool canStudy(Course c) {
    if ((courseProgress[c.id] ?? 0) >= 1) return false;
    if (c.prereq != null && !hasCert(c.prereq!)) return false;
    return true;
  }

  bool study(Course c) {
    if (!canStudy(c) || balance < 50) return false;
    _spend(c.nameKey.tr, 50);
    courseProgress[c.id] = ((courseProgress[c.id] ?? 0) + 0.25).clamp(0.0, 1.0).toDouble();
    _changed();
    return true;
  }

  // --------------------------------------------------------------- deals
  Deal spawnDeal(String kind, {StockItem? item, bool silent = false}) {
    final name = counterpartNames[_rng.nextInt(counterpartNames.length)];
    late Deal d;
    if (kind == 'buy') {
      final dev = dealDevices[_rng.nextInt(dealDevices.length)];
      final market = dev.market.toDouble();
      final ask = (market * (1.05 + _rng.nextDouble() * 0.15) / 5).round() * 5.0;
      final limit = (market * (0.6 + _rng.nextDouble() * 0.2) / 5).round() * 5.0;
      d = Deal(id: nextId(), kind: 'buy', item: dev.name, counterpart: name, market: market, ask: ask, limit: limit);
      d.messages.add(ChatMsg(
        false,
        'greet_buy'.tr.replaceAll('{item}', dev.name).replaceAll('{ask}', ask.toInt().toString()),
      ));
    } else {
      final it = item!;
      final limit = (it.market * (0.9 + _rng.nextDouble() * 0.3) / 5).round() * 5.0;
      d = Deal(id: nextId(), kind: 'sell', item: it.name, counterpart: name, market: it.market, ask: it.market * 1.1, limit: limit);
      d.stockId = it.id;
      d.messages.add(ChatMsg(false, 'greet_sell'.tr.replaceAll('{item}', it.name)));
    }
    deals.insert(0, d);
    if (deals.length > 14) {
      final old = deals.skip(10).where((x) => x.status != 'open').toList();
      for (final x in old) {
        deals.remove(x);
      }
    }
    if (!silent) {
      if (notifDeals) _note('deal', 'n_deal', '$name · ${d.item}');
      _changed();
    }
    return d;
  }

  Deal? sellDealFor(StockItem s) {
    for (final d in deals) {
      if (d.stockId == s.id && d.status == 'open') return d;
    }
    return null;
  }

  /// Handles a player message. A number in the text is treated as an offer.
  /// Local rules decide the outcome; the AI only writes the reply.
  Future<void> sendToDeal(Deal d, String text) async {
    text = text.trim();
    if (text.isEmpty || d.status != 'open' || d.busy || !online) return;

    final m = RegExp(r'\d+([.,]\d+)?').firstMatch(text);
    double? offer;
    if (m != null) offer = double.parse(m.group(0)!.replaceAll(',', '.'));

    if (d.kind == 'buy' && offer != null && offer > balance) {
      d.messages.add(ChatMsg(true, text));
      d.messages.add(ChatMsg(false, 'no_money'.tr));
      notifyListeners();
      return;
    }

    d.messages.add(ChatMsg(true, text));
    d.busy = true;
    notifyListeners();

    String outcome = 'chat';
    double? number;
    var hint = 'The player made no price offer. Reply briefly in character and ask them to name a price.';
    var offlineKey = 'o_chat';

    if (offer != null) {
      d.rounds++;
      if (d.kind == 'buy') {
        if (offer >= d.limit) {
          outcome = 'accept';
          number = offer;
        } else if (d.rounds >= 5) {
          outcome = 'leave';
        } else {
          outcome = 'counter';
          final k = max(0.15, 0.5 - 0.1 * d.rounds);
          number = ((d.limit + (d.ask - d.limit) * k) / 5).round() * 5.0;
        }
      } else {
        if (offer <= d.limit) {
          outcome = 'accept';
          number = offer;
        } else if (d.rounds >= 5) {
          outcome = 'leave';
        } else {
          outcome = 'counter';
          number = ((d.limit * (0.93 + 0.01 * d.rounds)) / 5).round() * 5.0;
        }
      }
      final p = number?.toInt();
      switch (outcome) {
        case 'accept':
          hint = 'GAME RESULT: you ACCEPT the price \$$p. Confirm the deal in 1-2 short sentences.';
          offlineKey = d.kind == 'buy' ? 'o_acc_s' : 'o_acc_b';
          break;
        case 'counter':
          hint = 'GAME RESULT: you REJECT this offer and counter with exactly \$$p. Say so in 1-2 short sentences.';
          offlineKey = d.kind == 'buy' ? 'o_ctr_s' : 'o_ctr_b';
          break;
        default:
          hint = 'GAME RESULT: you are done negotiating and walk away. Say goodbye in 1 short sentence.';
          offlineKey = 'o_leave';
      }
    }

    final role = d.kind == 'buy'
        ? 'a private person selling a used ${d.item} (market value about \$${d.market.toInt()}, your asking price \$${d.ask.toInt()}) to the player, who owns a tech repair and resale shop'
        : 'a customer who wants to buy a used ${d.item} (market value about \$${d.market.toInt()}) from the player, who owns a tech repair and resale shop';
    final persona = 'You are ${d.counterpart}, $role, in a game called TechLife. '
        'Stay in character, haggle realistically, keep every reply to 1-2 short sentences, '
        'reply only in ${AiService.langName(lang)}. Never reveal your hidden limit price '
        'and never invent a price the GAME RESULT does not give you.';

    final reply = await AiService.reply(
      apiKey: aiKey,
      lang: lang,
      persona: persona,
      history: List.of(d.messages),
      hint: hint,
      offlineKey: offlineKey,
      number: number,
    );

    d.messages.add(ChatMsg(false, reply));
    d.busy = false;

    if (outcome == 'accept' && number != null) {
      d.price = number;
      d.status = 'won';
      if (d.kind == 'buy') {
        _spend('deal_buy'.tr, number);
        stock.add(StockItem(nextId(), d.item, number, d.market));
      } else {
        _income('deal_sell'.tr, number);
        stock.removeWhere((s) => s.id == d.stockId);
        _note('money', 'n_pay', '+\$${number.toInt()}');
      }
      reputation = (reputation + 0.02).clamp(1.0, 5.0).toDouble();
    } else if (outcome == 'leave') {
      d.status = 'lost';
    }
    _changed();
  }
}
