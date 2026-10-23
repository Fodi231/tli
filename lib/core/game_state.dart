import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import 'app_log.dart';
import 'catalog.dart';
import 'i18n.dart';
import 'models.dart';
import 'repair/repair_session.dart';
import 'wallpaper_cfg.dart';
import 'window_service.dart';

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
  final Map<String, RepairSession> repairs = {};
  List<StockItem> stock = [];
  List<Deal> deals = [];
  List<AppNotification> notifications = [];
  List<Txn> txns = [];
  late LatLng player;

  // --- appearance / settings
  String playerName = '';
  int themeMode = 2; // 0 = system, 1 = light, 2 = dark
  final WallpaperCfg homeWp = WallpaperCfg();
  final WallpaperCfg lockWp = WallpaperCfg();
  bool lockSeparate = false;
  double wallpaperDim = 0;
  double textScale = 1.0;
  bool haptics = true, notifOrders = true, notifDeals = true;

  // --- display (PC / tablet)
  int layoutMode = 0; // 0 = automatic, 1 = phone, 2 = tablet / PC
  int uiScalePct = 100; // 70..160
  bool fullscreen = false;
  int winW = 1280, winH = 800;

  // --- map
  int mapStyle = 0; // 0 auto, 1 streets, 2 satellite, 3 offline only
  City? customCity; // a city picked on the world map (instead of the 3 presets)

  // --- network / AI
  static const String _builtInKey = String.fromEnvironment('GEMINI_API_KEY');
  bool _netOnline = true;
  bool forceOffline = false; // admin: simulate "no internet"
  String aiModel = '';
  String aiCustomUrl = '', aiCustomKey = '', aiCustomModel = '';
  String? lastAiError;
  int lastAiMs = 0;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  bool get online => _netOnline && !forceOffline;
  String get aiKey => geminiKey.isNotEmpty ? geminiKey : _builtInKey;
  bool get hasBuiltInKey => _builtInKey.isNotEmpty;
  WallpaperCfg get lockCfg => lockSeparate ? lockWp : homeWp;

  City get city => customCity ?? cities[cityIndex];
  int get unreadCount => notifications.where((n) => !n.read).length;
  int get openDeals => deals.where((d) => d.status == 'open').length;
  int get certCount => courseProgress.values.where((v) => v >= 1).length;
  bool hasCert(String id) => (courseProgress[id] ?? 0) >= 1;
  double get netWorth =>
      balance +
      invested +
      stock.fold(0.0, (s, e) => s + e.market) -
      loan -
      taxDue;

  String nextId() => '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  // ---------------------------------------------------------------- init
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await AppLog.I.init(_prefs!);
    final raw = _prefs!.getString('save');
    if (raw != null) {
      try {
        _load(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        AppLog.I.error('game', 'не удалось прочитать сохранение: $e');
      }
    }
    _loadImage('wp_home_img', homeWp);
    _loadImage('wp_lock_img', lockWp);
    I18n.lang = lang;
    _applyAi();
    player = LatLng(city.lat, city.lng);
    _seedWorld();
    try {
      final c = Connectivity();
      _netOnline = (await c.checkConnectivity()).any(
        (r) => r != ConnectivityResult.none,
      );
      AppLog.I.info('net', _netOnline ? 'онлайн' : 'нет сети');
      _connSub = c.onConnectivityChanged.listen((list) {
        final v = list.any((r) => r != ConnectivityResult.none);
        if (v != _netOnline) {
          _netOnline = v;
          AppLog.I.info('net', v ? 'сеть появилась' : 'сеть пропала');
          notifyListeners();
        }
      });
    } catch (e) {
      AppLog.I.warn('net', 'проверка сети недоступна: $e');
    }
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

  void _loadImage(String key, WallpaperCfg cfg) {
    final s = _prefs?.getString(key);
    if (s == null) return;
    try {
      cfg.bytes = base64Decode(s);
    } catch (_) {
      cfg.bytes = null;
    }
  }

  void _saveImage(WallpaperCfg cfg) {
    final p = _prefs;
    if (p == null) return;
    final key = identical(cfg, lockWp) ? 'wp_lock_img' : 'wp_home_img';
    if (cfg.bytes == null) {
      p.remove(key);
    } else {
      p.setString(key, base64Encode(cfg.bytes!));
    }
  }

  void _load(Map<String, dynamic> j) {
    balance = (j['balance'] as num? ?? balance).toDouble();
    reputation = (j['rep'] as num? ?? reputation).toDouble();
    cityIndex = ((j['city'] as int?) ?? 0).clamp(0, cities.length - 1).toInt();
    lang = (j['lang'] as String?) ?? 'ru';
    geminiKey = (j['key'] as String?) ?? '';
    parts = Map<String, int>.from((j['parts'] as Map?) ?? {});
    courseProgress = ((j['courses'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    );
    loan = (j['loan'] as num? ?? 0).toDouble();
    invested = (j['invested'] as num? ?? 0).toDouble();
    taxDue = (j['tax'] as num? ?? 0).toDouble();
    insured = (j['insured'] as bool?) ?? false;
    completedOrders = (j['completed'] as int?) ?? 0;
    totalEarned = (j['earned'] as num? ?? 0).toDouble();
    // Older saves have neither of these fields and migrate without a reset.
    orders = [];
    for (final item in (j['orders'] as List? ?? [])) {
      try {
        final order = Order.fromJson(Map<String, dynamic>.from(item as Map));
        if (services.containsKey(order.service) &&
            const ['available', 'active', 'done'].contains(order.status) &&
            !orders.any((o) => o.id == order.id)) {
          orders.add(order);
        }
      } catch (_) {
        /* Skip an invalid record, keep the rest of the save. */
      }
    }
    repairs.clear();
    for (final item in (j['repairs'] as List? ?? [])) {
      try {
        final session = RepairSession.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        final order = orders.where((o) => o.id == session.orderId);
        if ((session.training && session.orderId == RepairSession.practiceId) ||
            (order.isNotEmpty && order.first.service == session.service)) {
          repairs[session.orderId] = session;
        }
      } catch (_) {
        /* A bad session must not erase money or inventory. */
      }
    }
    stock =
        ((j['stock'] as List?) ?? [])
            .map((e) => StockItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    txns =
        ((j['txns'] as List?) ?? [])
            .map((e) => Txn.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    playerName = (j['pname'] as String?) ?? '';
    themeMode = ((j['theme'] as int?) ?? 2).clamp(0, 2).toInt();
    homeWp.loadJson(
      j['wpHome'] == null
          ? null
          : Map<String, dynamic>.from(j['wpHome'] as Map),
    );
    lockWp.loadJson(
      j['wpLock'] == null
          ? null
          : Map<String, dynamic>.from(j['wpLock'] as Map),
    );
    lockSeparate = (j['lockSep'] as bool?) ?? false;
    wallpaperDim = (j['wpdim'] as num? ?? 0).toDouble();
    textScale = (j['tscale'] as num? ?? 1.0).toDouble();
    haptics = (j['haptics'] as bool?) ?? true;
    notifOrders = (j['nord'] as bool?) ?? true;
    notifDeals = (j['ndeal'] as bool?) ?? true;
    aiModel = (j['aiModel'] as String?) ?? '';
    aiCustomUrl = (j['aiUrl'] as String?) ?? '';
    aiCustomKey = (j['aiCKey'] as String?) ?? '';
    aiCustomModel = (j['aiCModel'] as String?) ?? '';
    layoutMode = ((j['layout'] as int?) ?? 0).clamp(0, 2).toInt();
    uiScalePct = ((j['uiScale'] as int?) ?? 100).clamp(70, 160).toInt();
    fullscreen = (j['fullscreen'] as bool?) ?? false;
    winW = ((j['winW'] as int?) ?? 1280).clamp(480, 7680).toInt();
    winH = ((j['winH'] as int?) ?? 800).clamp(640, 4320).toInt();
    mapStyle = ((j['mapStyle'] as int?) ?? 0).clamp(0, 3).toInt();
    final cc = j['cCity'];
    customCity = null;
    if (cc is Map) {
      try {
        customCity = City(
          (cc['id'] ?? 'custom').toString(),
          [for (final n in (cc['n'] as List)) n.toString()],
          (cc['lat'] as num).toDouble(),
          (cc['lng'] as num).toDouble(),
          (cc['t'] ?? '—').toString(),
        );
        if (customCity!.names.length < 3) customCity = null;
      } catch (_) {
        customCity = null;
      }
    }
  }

  Map<String, dynamic> _toJson() => {
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
    'orders': orders.map((o) => o.toJson()).toList(),
    'repairs': repairs.values.map((r) => r.toJson()).toList(),
    'stock': stock.map((e) => e.toJson()).toList(),
    'txns': txns.take(40).map((e) => e.toJson()).toList(),
    'pname': playerName,
    'theme': themeMode,
    'wpHome': homeWp.toJson(),
    'wpLock': lockWp.toJson(),
    'lockSep': lockSeparate,
    'wpdim': wallpaperDim,
    'tscale': textScale,
    'haptics': haptics,
    'nord': notifOrders,
    'ndeal': notifDeals,
    'aiModel': aiModel,
    'aiUrl': aiCustomUrl,
    'aiCKey': aiCustomKey,
    'aiCModel': aiCustomModel,
    'layout': layoutMode,
    'uiScale': uiScalePct,
    'fullscreen': fullscreen,
    'winW': winW,
    'winH': winH,
    'mapStyle': mapStyle,
    'cCity':
        customCity == null
            ? null
            : {
              'id': customCity!.id,
              'n': customCity!.names,
              'lat': customCity!.lat,
              'lng': customCity!.lng,
              't': customCity!.temp,
            },
  };

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString('save', jsonEncode(_toJson()));
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
    customCity = null;
    parts = {};
    courseProgress = {};
    loan = invested = taxDue = 0;
    insured = false;
    completedOrders = 0;
    totalEarned = 0;
    orders = [];
    repairs.clear();
    stock = [];
    deals = [];
    notifications = [];
    txns = [];
    player = LatLng(city.lat, city.lng);
    _seedWorld();
    AppLog.I.info('game', 'прогресс сброшен');
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

  void setThemeMode(int m) {
    themeMode = m;
    _changed();
  }

  /// Called when the device switches between light and dark ("system" theme).
  void refreshTheme() => notifyListeners();

  WallpaperCfg _cfg(bool lock) => (lock && lockSeparate) ? lockWp : homeWp;

  void setWallpaperPreset(int i, {bool lock = false}) {
    final c = _cfg(lock);
    c.preset = i;
    c.bytes = null;
    c.iw = 0;
    c.ih = 0;
    c.scale = 1;
    c.ox = 0;
    c.oy = 0;
    _saveImage(c);
    _changed();
  }

  void setWallpaperImage(
    Uint8List bytes,
    int iw,
    int ih,
    double scale,
    double ox,
    double oy, {
    bool lock = false,
  }) {
    final c = _cfg(lock);
    c.bytes = bytes;
    c.iw = iw;
    c.ih = ih;
    c.scale = scale;
    c.ox = ox;
    c.oy = oy;
    _saveImage(c);
    _changed();
  }

  void setWallpaperTransform(
    double scale,
    double ox,
    double oy, {
    bool lock = false,
  }) {
    final c = _cfg(lock);
    c.scale = scale;
    c.ox = ox;
    c.oy = oy;
    _changed();
  }

  void setLockSeparate(bool v) {
    lockSeparate = v;
    if (v) {
      lockWp.copyFrom(homeWp); // start from the same picture
      _saveImage(lockWp);
    }
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
    if (orders.where((o) => o.status == 'available').length < 6 &&
        _rng.nextDouble() < 0.6) {
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
    orders.add(
      Order(
        id: nextId(),
        device: dev,
        service: k,
        price: price,
        lat: c.lat + (_rng.nextDouble() - 0.5) * 0.08,
        lng: c.lng + (_rng.nextDouble() - 0.5) * 0.1,
      ),
    );
    if (!silent && notifOrders) {
      _note('order', 'n_order', '${s.nameKey.tr} · $dev');
    }
  }

  // -------------------------------------------------------------- orders
  double distanceKm(double lat, double lng) =>
      const Distance().as(LengthUnit.Kilometer, player, LatLng(lat, lng));

  void acceptOrder(Order o) {
    if (!orders.contains(o) || o.status != 'available') return;
    o.status = 'active';
    _changed();
  }

  bool hasPartFor(Order o) {
    if (repairs[o.id]?.partConsumed == true) return true;
    final cat = services[o.service]!.cat;
    return cat == null || (parts[cat] ?? 0) > 0;
  }

  /// Returns the reward that was paid.
  double completeRepair(Order o, int mistakes) {
    if (!orders.contains(o)) return 0;
    final session = repairs[o.id];
    if (o.status != 'active') return session?.reward ?? 0;
    if (supportsWorkbench(o.device) && (session == null || !session.finished)) {
      return 0;
    }
    final s = services[o.service]!;
    if (s.cat != null && session?.partConsumed != true) {
      if ((parts[s.cat!] ?? 0) <= 0) return 0;
      parts[s.cat!] = parts[s.cat!]! - 1;
    }
    final f =
        (1 - 0.12 * mistakes * (insured ? 0.5 : 1)).clamp(0.4, 1.0).toDouble();
    var reward = o.price * f * (1 + 0.05 * certCount);
    reward = reward.roundToDouble();
    o.status = 'done';
    completedOrders++;
    final delta = mistakes == 0 ? 0.04 : (mistakes > 3 ? -0.08 : -0.01);
    reputation = (reputation + delta).clamp(1.0, 5.0).toDouble();
    _income(s.nameKey.tr, reward);
    if (session != null) session.reward = reward;
    _note('money', 'n_pay', '+\$${reward.toInt()}');
    AppLog.I.info(
      'game',
      'ремонт ${o.service} завершён, ошибок: $mistakes, награда: \$${reward.toInt()}',
    );
    _changed();
    return reward;
  }

  /// Called on entry, outside build; sessions survive navigation and restart.
  RepairSession? startWorkbench(String id) {
    if (id == RepairSession.practiceId) {
      return repairs.putIfAbsent(
        id,
        () => RepairSession(id, 'display', training: true),
      );
    }
    for (final order in orders) {
      if (order.id == id &&
          supportsWorkbench(order.device) &&
          (order.status == 'active' || order.status == 'done')) {
        return repairs.putIfAbsent(id, () => RepairSession(id, order.service));
      }
    }
    return null;
  }

  void selectRepairTool(String id, RepairTool tool) {
    final session = repairs[id];
    if (session == null) return;
    session.tool = tool;
    _changed();
  }

  void toggleRepairHints(String id) {
    final session = repairs[id];
    if (session == null) return;
    session.hints = !session.hints;
    _changed();
  }

  void resetPractice() {
    repairs[RepairSession.practiceId] = RepairSession(
      RepairSession.practiceId,
      'display',
      training: true,
    );
    _changed();
  }

  RepairResult repairAction(
    String id,
    String target,
    RepairGesture gesture, {
    String? destination,
    int heldMs = 0,
  }) {
    final session = repairs[id];
    if (session == null) {
      return const RepairResult(RepairOutcome.blocked, 'no_orders');
    }
    final matching = orders.where((o) => o.id == id);
    final order = matching.isEmpty ? null : matching.first;
    if (!session.training && (order == null || order.status != 'active')) {
      return const RepairResult(RepairOutcome.blocked, 'r_already_done');
    }
    final previous = session.current?.id;
    final cat = services[session.service]!.cat;
    final result = session.act(
      target,
      gesture,
      destination: destination,
      heldMs: heldMs,
      hasPart: cat == null || (parts[cat] ?? 0) > 0,
    );
    if (result.accepted &&
        previous == 'part_in' &&
        session.done('part_in') &&
        !session.training &&
        !session.partConsumed &&
        cat != null) {
      parts[cat] = parts[cat]! - 1;
      session.partConsumed = true;
    }
    if (result.accepted && session.finished) {
      if (session.training) {
        session.reward = 0;
      } else {
        completeRepair(order!, session.mistakes);
      }
    }
    _changed();
    return result;
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

  /// Ticket price to a point: grows with distance.
  int flightCost(double lat, double lng) {
    final km = const Distance().as(
      LengthUnit.Kilometer,
      player,
      LatLng(lat, lng),
    );
    final v = (30 + km * 0.06).clamp(30.0, 900.0);
    return (v / 5).round() * 5;
  }

  bool flyTo(int i, {bool free = false}) {
    final c = cities[i];
    return flyToCity(c, index: i, free: free);
  }

  /// Moves the player's base to any city (one of the presets or one picked on the map).
  bool flyToCity(City c, {int? index, bool free = false}) {
    if (customCity == null && index != null && index == cityIndex) return true;
    final cost = flightCost(c.lat, c.lng);
    if (!free && balance < cost) return false;
    if (!free) _spend('fly'.tr, cost.toDouble());
    if (index != null) {
      cityIndex = index;
      customCity = null;
    } else {
      customCity = c;
    }
    player = LatLng(city.lat, city.lng);
    orders.removeWhere((o) => o.status == 'available');
    for (var n = 0; n < 4; n++) {
      _spawnOrder(silent: true);
    }
    AppLog.I.info('game', 'перелёт: ${c.names[1]} (\$$cost)');
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
    courseProgress[c.id] =
        ((courseProgress[c.id] ?? 0) + 0.25).clamp(0.0, 1.0).toDouble();
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
      final ask =
          (market * (1.05 + _rng.nextDouble() * 0.15) / 5).round() * 5.0;
      final limit =
          (market * (0.6 + _rng.nextDouble() * 0.2) / 5).round() * 5.0;
      d = Deal(
        id: nextId(),
        kind: 'buy',
        item: dev.name,
        counterpart: name,
        market: market,
        ask: ask,
        limit: limit,
      );
      d.messages.add(
        ChatMsg(
          false,
          'greet_buy'.tr
              .replaceAll('{item}', dev.name)
              .replaceAll('{ask}', ask.toInt().toString()),
        ),
      );
    } else {
      final it = item!;
      final limit =
          (it.market * (0.9 + _rng.nextDouble() * 0.3) / 5).round() * 5.0;
      d = Deal(
        id: nextId(),
        kind: 'sell',
        item: it.name,
        counterpart: name,
        market: it.market,
        ask: it.market * 1.1,
        limit: limit,
      );
      d.stockId = it.id;
      d.messages.add(
        ChatMsg(false, 'greet_sell'.tr.replaceAll('{item}', it.name)),
      );
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
    var hint =
        'The player made no price offer. Reply briefly in character and ask them to name a price.';
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
          hint =
              'GAME RESULT: you ACCEPT the price \$$p. Confirm the deal in 1-2 short sentences.';
          offlineKey = d.kind == 'buy' ? 'o_acc_s' : 'o_acc_b';
          break;
        case 'counter':
          hint =
              'GAME RESULT: you REJECT this offer and counter with exactly \$$p. Say so in 1-2 short sentences.';
          offlineKey = d.kind == 'buy' ? 'o_ctr_s' : 'o_ctr_b';
          break;
        default:
          hint =
              'GAME RESULT: you are done negotiating and walk away. Say goodbye in 1 short sentence.';
          offlineKey = 'o_leave';
      }
    }

    final role =
        d.kind == 'buy'
            ? 'a private person selling a used ${d.item} (market value about \$${d.market.toInt()}, your asking price \$${d.ask.toInt()}) to the player, who owns a tech repair and resale shop'
            : 'a customer who wants to buy a used ${d.item} (market value about \$${d.market.toInt()}) from the player, who owns a tech repair and resale shop';
    final persona =
        'You are ${d.counterpart}, $role, in a game called TechLife. '
        'Stay in character, haggle realistically, keep every reply to 1-2 short sentences, '
        'reply only in ${AiService.langName(lang)}. Never reveal your hidden limit price '
        'and never invent a price the GAME RESULT does not give you.';

    final r = await AiService.reply(
      apiKey: aiKey,
      lang: lang,
      persona: persona,
      history: List.of(d.messages),
      hint: hint,
      offlineKey: offlineKey,
      number: number,
    );
    lastAiError = r.error;
    lastAiMs = r.ms;

    d.messages.add(ChatMsg(false, r.text, fallback: !r.ok));
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
      AppLog.I.info(
        'game',
        'сделка (${d.kind}) ${d.item} за \$${number.toInt()}',
      );
    } else if (outcome == 'leave') {
      d.status = 'lost';
    }
    _changed();
  }

  // ------------------------------------------------------------- display
  void setLayoutMode(int m) {
    layoutMode = m;
    _changed();
  }

  void setUiScale(int pct) {
    uiScalePct = pct.clamp(70, 160).toInt();
    _changed();
  }

  Future<void> setFullscreen(bool v) async {
    fullscreen = v;
    _changed();
    await WinService.setFullscreen(v);
  }

  Future<void> setWindowSize(int w, int h) async {
    winW = w;
    winH = h;
    fullscreen = false;
    _changed();
    await WinService.setSize(w, h);
  }

  void setMapStyle(int m) {
    mapStyle = m;
    _changed();
  }

  // --------------------------------------------------------------- admin
  void adminAddMoney(double v) {
    balance += v;
    txns.insert(0, Txn('admin', v));
    AppLog.I.info('admin', 'баланс ${v >= 0 ? '+' : ''}${v.toInt()}');
    _changed();
  }

  void adminSetBalance(double v) {
    balance = v;
    AppLog.I.info('admin', 'баланс установлен: ${v.toInt()}');
    _changed();
  }

  void adminSetReputation(double v) {
    reputation = v.clamp(1.0, 5.0).toDouble();
    _changed();
  }

  void adminSpawnOrders(int n) {
    for (var i = 0; i < n; i++) {
      _spawnOrder(silent: true);
    }
    AppLog.I.info('admin', 'создано заказов: $n');
    _changed();
  }

  void adminSpawnDeal() {
    spawnDeal('buy');
    AppLog.I.info('admin', 'создана сделка');
  }

  void adminGiveParts(int n) {
    for (final c in categories) {
      parts[c] = (parts[c] ?? 0) + n;
    }
    AppLog.I.info('admin', 'выдано запчастей: по $n');
    _changed();
  }

  void adminUnlockCourses() {
    for (final c in courses) {
      courseProgress[c.id] = 1;
    }
    AppLog.I.info('admin', 'все курсы пройдены');
    _changed();
  }

  void adminClearDebts() {
    loan = 0;
    taxDue = 0;
    AppLog.I.info('admin', 'долги и налоги обнулены');
    _changed();
  }

  void adminTick() => _tick();

  void setForceOffline(bool v) {
    forceOffline = v;
    AppLog.I.info(
      'net',
      v
          ? 'админ: имитация «нет интернета» включена'
          : 'админ: имитация «нет интернета» выключена',
    );
    notifyListeners();
  }

  void _applyAi() {
    AiService.modelOverride = aiModel.isEmpty ? null : aiModel;
    AiService.customUrl = aiCustomUrl;
    AiService.customKey = aiCustomKey;
    AiService.customModel = aiCustomModel;
  }

  /// Own OpenAI-compatible provider (empty url = back to Google).
  void setAiProvider(String url, String key, String model) {
    aiCustomUrl = url.trim();
    aiCustomKey = key.trim();
    aiCustomModel = model.trim();
    _applyAi();
    AiService.resume();
    AppLog.I.info(
      'admin',
      aiCustomUrl.isEmpty
          ? 'ИИ: провайдер Google'
          : 'ИИ: свой провайдер $aiCustomUrl, модель ${aiCustomModel.isEmpty ? 'по умолчанию' : aiCustomModel}',
    );
    _changed();
  }

  void setAiModel(String m) {
    aiModel = m.trim();
    AiService.modelOverride = aiModel.isEmpty ? null : aiModel;
    AppLog.I.info(
      'admin',
      'модель ИИ: ${aiModel.isEmpty ? 'по умолчанию' : aiModel}',
    );
    _changed();
  }

  Future<AiResult> adminTestAi() async {
    AppLog.I.info('ai', 'тест соединения с ИИ…');
    final r = await AiService.ping(aiKey);
    lastAiError = r.error;
    lastAiMs = r.ms;
    notifyListeners();
    return r;
  }

  String exportSave() => const JsonEncoder.withIndent('  ').convert(_toJson());

  bool importSave(String text) {
    try {
      _load(jsonDecode(text) as Map<String, dynamic>);
      I18n.lang = lang;
      player = LatLng(city.lat, city.lng);
      AppLog.I.info('admin', 'сохранение импортировано');
      _changed();
      return true;
    } catch (e) {
      AppLog.I.error('admin', 'ошибка импорта сохранения: $e');
      return false;
    }
  }
}
