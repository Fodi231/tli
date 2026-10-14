import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../../core/app_log.dart';
import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/geo_data.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/tile_client.dart';
import '../shell.dart';
import '../widgets.dart';

// ---------------------------------------------------------------- providers

/// How a tile source looks in the dark app theme:
///  dark    – already dark, used as is
///  invert  – bright map, darkened with a colour filter in both themes
///  natural – photo map (satellite), must keep its colours in the light theme
class _Prov {
  final String id, url, credit, mode;
  final int maxNative;
  const _Prov(this.id, this.url, this.maxNative, this.mode, this.credit);
}

const _esri = 'https://server.arcgisonline.com/ArcGIS/rest/services';
const _esriDark = _Prov('esri_dark', '$_esri/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}', 16, 'dark', 'Esri, HERE, Garmin');
const _osm = _Prov('osm', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 19, 'invert', '© OpenStreetMap contributors');
const _esriStreet = _Prov('esri_street', '$_esri/World_Street_Map/MapServer/tile/{z}/{y}/{x}', 19, 'invert', 'Esri, HERE, Garmin');
const _esriSat = _Prov('esri_sat', '$_esri/World_Imagery/MapServer/tile/{z}/{y}/{x}', 18, 'natural', 'Esri, Maxar, Earthstar Geographics');

/// Tile sources per map style (0 auto, 1 streets, 2 satellite, 3 offline).
/// When one source keeps failing the next one in the chain is used.
const List<List<_Prov>> _chains = [
  [_esriDark, _osm, _esriStreet],
  [_osm, _esriStreet, _esriDark],
  [_esriSat, _esriStreet, _osm],
  [],
];

// -------------------------------------------------------------- label hits

class LabelHits {
  final List<Rect> rects = [];
  final List<int> idx = [];

  void clear() {
    rects.clear();
    idx.clear();
  }

  int? find(Offset o) {
    for (var i = rects.length - 1; i >= 0; i--) {
      if (rects[i].inflate(7).contains(o)) return idx[i];
    }
    return null;
  }
}

// ------------------------------------------------------------------ layers

/// Offline world: simplified country polygons drawn under the tiles. Always
/// visible, so the map is never an empty grey rectangle even without internet.
class _WorldLayer extends StatelessWidget {
  final GeoData geo;
  const _WorldLayer({required this.geo});

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(painter: _WorldPainter(geo, cam.zoom, cam.pixelOrigin.x, cam.pixelOrigin.y)),
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  final GeoData geo;
  final double zoom, ox, oy;
  _WorldPainter(this.geo, this.zoom, this.ox, this.oy);

  static final Paint _land = Paint()..color = const Color(0xFF1B2540);
  static final Paint _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFF3A4A78);

  @override
  void paint(Canvas canvas, Size size) {
    if (zoom > 11) return; // the tiles cover it; huge coordinates also confuse the rasterizer
    final w = 256.0 * math.pow(2, zoom);
    for (var ci = 0; ci < geo.shapes.length; ci++) {
      Path? path;
      for (final r in geo.shapes[ci]) {
        final x0 = r.minX * w - ox, x1 = r.maxX * w - ox;
        final y0 = r.minY * w - oy, y1 = r.maxY * w - oy;
        if (x1 < -10 || x0 > size.width + 10 || y1 < -10 || y0 > size.height + 10) continue;
        if (x1 - x0 < 0.8 && y1 - y0 < 0.8) continue; // specks
        path ??= Path()..fillType = PathFillType.evenOdd;
        final xy = r.xy;
        var lx = 0.0, ly = 0.0;
        var first = true;
        for (var i = 0; i < xy.length; i += 2) {
          final x = xy[i] * w - ox;
          final y = xy[i + 1] * w - oy;
          if (first) {
            path.moveTo(x, y);
            lx = x;
            ly = y;
            first = false;
          } else if ((x - lx).abs() + (y - ly).abs() >= 0.8) {
            path.lineTo(x, y);
            lx = x;
            ly = y;
          }
        }
        path.close();
      }
      if (path != null) {
        canvas.drawPath(path, _land);
        canvas.drawPath(path, _border);
      }
    }
  }

  @override
  bool shouldRepaint(_WorldPainter o) => o.zoom != zoom || o.ox != ox || o.oy != oy || o.geo != geo;
}

/// Country and city names in the game language with collision avoidance:
/// the more you zoom in, the more names appear.
class _LabelsLayer extends StatelessWidget {
  final GeoData geo;
  final String lang;
  final LabelHits hits;
  const _LabelsLayer({required this.geo, required this.lang, required this.hits});

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _LabelsPainter(geo, geoLangIndex(lang), cam.zoom, cam.pixelOrigin.x, cam.pixelOrigin.y, hits),
        ),
      ),
    );
  }
}

class _Lbl {
  final TextPainter fill, halo;
  final double w, h;
  _Lbl(this.fill, this.halo, this.w, this.h);
}

class _LabelsPainter extends CustomPainter {
  final GeoData geo;
  final int li;
  final double zoom, ox, oy;
  final LabelHits hits;
  _LabelsPainter(this.geo, this.li, this.zoom, this.ox, this.oy, this.hits);

  static final Map<String, _Lbl> _cache = {};

  static _Lbl _text(String key, String text, double size, FontWeight weight, Color color, double spacing) {
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length > 3000) _cache.clear();
    TextPainter mk(TextStyle st) => TextPainter(
          text: TextSpan(text: text, style: st),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
    final fill = mk(TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing));
    final halo = mk(TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xE6050A18),
    ));
    return _cache[key] = _Lbl(fill, halo, fill.width, fill.height);
  }

  static bool _free(List<Rect> placed, Rect r) {
    for (final p in placed) {
      if (p.overlaps(r)) return false;
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    hits.clear();
    final w = 256.0 * math.pow(2, zoom);
    final view = Rect.fromLTWH(-60, -30, size.width + 120, size.height + 60);
    final placed = <Rect>[];
    final places = geo.places;

    void drawPlaces(bool important) {
      for (var i = 0; i < places.length; i++) {
        final p = places[i];
        if ((p.rank <= 2) != important) continue;
        if (zoom < p.minZoom) continue;
        final cx = p.mx * w - ox, cy = p.my * w - oy;
        if (!view.contains(Offset(cx, cy))) continue;
        if (placed.length > 450) return;

        final size0 = p.rank <= 1 ? 14.5 : (p.rank <= 3 ? 13.0 : 12.0);
        final weight = p.rank <= 1 ? FontWeight.w700 : (p.rank <= 3 ? FontWeight.w600 : FontWeight.w500);
        final lb = _text('p$i|$li', p.name(li), size0, weight, Colors.white, 0);
        final r = p.cap == 1 ? 3.6 : 2.6;
        // label to the right of the dot, otherwise to the left
        var lx = cx + r + 3;
        var rect = Rect.fromLTWH(cx - r - 1, cy - lb.h / 2, (lx - cx) + lb.w + r, lb.h);
        if (!_free(placed, rect)) {
          lx = cx - r - 3 - lb.w;
          rect = Rect.fromLTWH(lx - 1, cy - lb.h / 2, (cx - lx) + r + 2, lb.h);
          if (!_free(placed, rect)) continue;
        }
        placed.add(rect.inflate(1.5));
        hits.rects.add(rect);
        hits.idx.add(i);

        final c = Offset(cx, cy);
        canvas.drawCircle(c, r + 1.6, Paint()..color = const Color(0xE6050A18));
        canvas.drawCircle(c, r, Paint()..color = p.cap == 1 ? const Color(0xFFFFD166) : Colors.white);
        if (p.cap == 1) canvas.drawCircle(c, r - 1.8, Paint()..color = const Color(0xFF0B1426));
        final o = Offset(lx, cy - lb.h / 2);
        lb.halo.paint(canvas, o);
        lb.fill.paint(canvas, o);
      }
    }

    // 1) the most important cities, 2) country names, 3) everything else
    drawPlaces(true);

    final cs = geo.countries;
    for (var i = 0; i < cs.length; i++) {
      final c = cs[i];
      if (zoom < c.minLabel || zoom > c.maxLabel) continue;
      final cx = c.mx * w - ox, cy = c.my * w - oy;
      if (!view.contains(Offset(cx, cy))) continue;
      final big = c.rank <= 1;
      final lb = _text('c$i|$li', c.name(li).toUpperCase(), big ? 13.5 : 11.5, FontWeight.w600, const Color(0xFFB8C4E6), 1.6);
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: lb.w, height: lb.h);
      if (!_free(placed, rect)) continue;
      placed.add(rect.inflate(4));
      final o = Offset(cx - lb.w / 2, cy - lb.h / 2);
      lb.halo.paint(canvas, o);
      lb.fill.paint(canvas, o);
    }

    drawPlaces(false);
  }

  @override
  bool shouldRepaint(_LabelsPainter o) =>
      o.zoom != zoom || o.ox != ox || o.oy != oy || o.li != li || o.geo != geo;
}

// --------------------------------------------------------------------- app

/// World map: offline country polygons + (optional) online tiles + all 7 000+
/// cities labelled in the game language. Tap a city to fly there, tap anywhere
/// else to travel (a small fare).
class MapApp extends StatefulWidget {
  const MapApp({super.key});
  @override
  State<MapApp> createState() => _MapAppState();
}

class _MapAppState extends State<MapApp> {
  final MapController controller = MapController();
  final LabelHits _hits = LabelHits();
  final Map<String, NetworkTileProvider> _providers = {};

  GeoData? _geo;
  String? _geoError;

  int _prov = 0; // index inside the current chain
  int _errs = 0;
  int _gen = 0;
  int _styleSeen = -1;
  bool _down = false;
  DateTime _lastErr = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _downTimer;
  double _minZoom = 2;

  @override
  void initState() {
    super.initState();
    GeoData.ensure().then((g) {
      if (mounted) setState(() => _geo = g);
    }).catchError((Object e) {
      if (mounted) setState(() => _geoError = e.toString());
    });
  }

  @override
  void dispose() {
    _downTimer?.cancel();
    super.dispose();
  }

  List<_Prov> _chain(int style) => _chains[style.clamp(0, _chains.length - 1).toInt()];

  void _tileError(Object error, int style) {
    final now = DateTime.now();
    if (now.difference(_lastErr).inSeconds > 15) _errs = 0;
    _lastErr = now;
    _errs++;
    if (_errs == 1) {
      AppLog.I.warn('map', 'плитка карты не загрузилась: ${error.toString().split('\n').first}');
    }
    if (_errs < 8) return;
    final chain = _chain(style);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_prov < chain.length - 1) {
        AppLog.I.warn('map', 'источник ${chain[_prov].id} не отвечает, переключаюсь на ${chain[_prov + 1].id}');
        setState(() {
          _prov++;
          _errs = 0;
          _gen++;
        });
      } else if (!_down) {
        AppLog.I.error('map', 'ни один сервер карты не отвечает — работает офлайн-карта');
        setState(() => _down = true);
        _downTimer?.cancel();
        _downTimer = Timer(const Duration(seconds: 20), () {
          if (mounted) setState(() => _down = false);
        });
      }
    });
  }

  void _reload() {
    setState(() {
      _prov = 0;
      _errs = 0;
      _down = false;
      _gen++;
      _providers.clear();
    });
  }

  NetworkTileProvider _providerFor(String key) => _providers.putIfAbsent(
        key,
        () => NetworkTileProvider(httpClient: LimitedClient.shared),
      );

  void _zoomBy(double d) {
    final cam = controller.camera;
    controller.move(cam.center, (cam.zoom + d).clamp(_minZoom, 18.0).toDouble());
  }

  void _move(GameState gs, LatLng p) {
    final km = const Distance().as(LengthUnit.Kilometer, gs.player, p);
    final fare = context.read<GameState>().movePlayer(p);
    if (fare < 0) {
      toast(context, 'no_money'.tr);
    } else {
      toast(context, '${'moved'.tr} ${km.toStringAsFixed(1)} km · ${'fare'.tr} ${money(fare)}');
    }
  }

  void _onTap(GameState gs, LatLng p) {
    final geo = _geo;
    if (geo != null) {
      final cam = controller.camera;
      final pt = cam.project(p) - cam.pixelOrigin;
      final hit = _hits.find(Offset(pt.x, pt.y));
      if (hit != null) {
        _placeSheet(geo, geo.places[hit]);
        return;
      }
    }
    _move(gs, p);
  }

  City _cityOf(int index, GeoPlace p) =>
      City('g$index', [p.names[1].isEmpty ? p.names[0] : p.names[1], p.names[0], p.names[2].isEmpty ? p.names[0] : p.names[2]], p.lat, p.lng, City.approxTemp(p.lat));

  void _placeSheet(GeoData geo, GeoPlace p) {
    final index = geo.places.indexOf(p);
    final city = _cityOf(index, p);
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) {
        final gs = ctx.watch<GameState>();
        final cost = gs.flightCost(p.lat, p.lng);
        final here = const Distance().as(LengthUnit.Kilometer, LatLng(gs.city.lat, gs.city.lng), LatLng(p.lat, p.lng)) < 25;
        final country = p.country >= 0 && p.country < geo.countries.length ? geo.countries[p.country].name(geoLangIndex(gs.lang)) : '';
        final km = gs.distanceKm(p.lat, p.lng);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (p.cap == 1) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.star, color: Color(0xFFFFD166), size: 20)),
                Expanded(child: Text(p.name(geoLangIndex(gs.lang)), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              ]),
              if (country.isNotEmpty) Text(country, style: const TextStyle(color: C.sub)),
              const SizedBox(height: 6),
              Text(
                '${p.pop > 0 ? '${'population'.tr}: ${money(p.pop).replaceAll('\$', '')}  ·  ' : ''}${km.toStringAsFixed(0)} km',
                style: const TextStyle(color: C.sub, fontSize: 13),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: here
                    ? null
                    : () {
                        final ok = ctx.read<GameState>().flyToCity(city);
                        Navigator.pop(ctx);
                        if (ok) controller.move(LatLng(p.lat, p.lng), 11.5);
                        toast(context, ok ? '${'flew'.tr} ${city.name(gs.lang)}' : 'no_money'.tr);
                      },
                icon: const Icon(Icons.flight_takeoff),
                label: Text(here ? 'you_are_here'.tr : '${'fly_here'.tr} · ${money(cost)}'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  controller.move(LatLng(p.lat, p.lng), math.max(controller.camera.zoom, 8));
                },
                child: Text('show_on_map'.tr),
              ),
            ],
          ),
        );
      },
    );
  }

  void _searchSheet(GeoData geo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) => _SearchSheet(
        geo: geo,
        onPick: (p) {
          Navigator.pop(ctx);
          controller.move(LatLng(p.lat, p.lng), 9);
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _placeSheet(geo, p);
          });
        },
      ),
    );
  }

  void _orderSheet(Order o) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) {
        final gs = ctx.watch<GameState>();
        final s = services[o.service]!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.nameKey.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('${o.device} · ${gs.distanceKm(o.lat, o.lng).toStringAsFixed(1)} km', style: const TextStyle(color: C.sub)),
              const SizedBox(height: 8),
              Text(money(o.price), style: const TextStyle(color: C.green, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (o.status == 'available')
                FilledButton(
                  onPressed: () {
                    ctx.read<GameState>().acceptOrder(o);
                    Navigator.pop(ctx);
                  },
                  child: Text('accept'.tr),
                )
              else
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<Shell>().open('repair', arg: o.id);
                  },
                  child: Text('start_repair'.tr),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tiles(GameState gs, bool light) {
    final chain = _chain(gs.mapStyle);
    if (chain.isEmpty) return const SizedBox.shrink();
    final pr = chain[_prov.clamp(0, chain.length - 1).toInt()];
    final key = '${pr.id}_$_gen';
    Widget layer = TileLayer(
      key: ValueKey(key),
      urlTemplate: pr.url,
      maxNativeZoom: pr.maxNative,
      userAgentPackageName: 'com.techlife.techlife',
      tileProvider: _providerFor(key),
      keepBuffer: 3,
      panBuffer: 1,
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
      errorTileCallback: (tile, error, stackTrace) => _tileError(error, gs.mapStyle),
    );
    if (pr.mode == 'invert') layer = ColorFiltered(colorFilter: lightModeFilter, child: layer);
    if (pr.mode == 'natural') layer = ThemeFilter(light: light, child: layer);
    return layer;
  }

  Widget _mapButton(IconData icon, String tip, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Tooltip(
          message: tip,
          child: Material(
            color: C.card2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white, size: 22)),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final c = gs.city;
    final light = isLightMode(gs.themeMode, MediaQuery.platformBrightnessOf(context));
    if (_styleSeen != gs.mapStyle) {
      _styleSeen = gs.mapStyle;
      _prov = 0;
      _errs = 0;
      _down = false;
      _gen++;
    }
    final geo = _geo;
    final chain = _chain(gs.mapStyle);
    final credit = chain.isEmpty ? 'Natural Earth' : chain[_prov.clamp(0, chain.length - 1).toInt()].credit;

    final markers = <Marker>[
      for (final o in gs.orders.where((o) => o.status != 'done'))
        Marker(
          point: LatLng(o.lat, o.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _orderSheet(o),
            child: Icon(Icons.build_circle, size: 34, color: o.status == 'active' ? C.green : C.orange),
          ),
        ),
      for (final off in shopOffsets)
        Marker(
          point: LatLng(c.lat + off[0], c.lng + off[1]),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => context.read<Shell>().open('shop'),
            child: const Icon(Icons.storefront, size: 32, color: C.accent),
          ),
        ),
      Marker(
        point: gs.player,
        width: 44,
        height: 44,
        child: const Icon(Icons.person_pin_circle, size: 40, color: Colors.redAccent),
      ),
    ];

    return AppPage(
      title: 'map'.tr,
      wide: true,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(builder: (context, box) {
              // The whole world must always cover the view (also on big PC windows).
              final side = math.max(box.maxWidth, box.maxHeight);
              _minZoom = math.max(1.0, (math.log(side / 256) / math.ln2 * 10).ceil() / 10);
              return FlutterMap(
                mapController: controller,
                options: MapOptions(
                  initialCenter: LatLng(c.lat, c.lng),
                  initialZoom: math.max(11.5, _minZoom),
                  minZoom: _minZoom,
                  maxZoom: 18,
                  backgroundColor: const Color(0xFF0B1426),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(const LatLng(-85, -180), const LatLng(85, 180)),
                  ),
                  onTap: (tp, p) => _onTap(gs, p),
                ),
                children: [
                  if (geo != null) _WorldLayer(geo: geo),
                  _tiles(gs, light),
                  if (geo != null) _LabelsLayer(geo: geo, lang: gs.lang, hits: _hits),
                  MarkerLayer(markers: markers),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(credit),
                      const TextSourceAttribution('Natural Earth'),
                    ],
                  ),
                ],
              );
            }),
          ),
          // --- top: city chips + search
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (gs.customCity != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(gs.customCity!.name(gs.lang)),
                              selected: true,
                              onSelected: (_) => controller.move(LatLng(c.lat, c.lng), 11.5),
                            ),
                          ),
                        for (var i = 0; i < cities.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cities[i].name(gs.lang) +
                                  (gs.customCity == null && i == gs.cityIndex ? '' : ' · ${money(gs.flightCost(cities[i].lat, cities[i].lng))}')),
                              selected: gs.customCity == null && i == gs.cityIndex,
                              onSelected: (_) {
                                if (gs.customCity == null && i == gs.cityIndex) return;
                                final ok = context.read<GameState>().flyTo(i);
                                if (ok) controller.move(LatLng(cities[i].lat, cities[i].lng), 11.5);
                                toast(context, ok ? '${'flew'.tr} ${cities[i].name(gs.lang)}' : 'no_money'.tr);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (geo != null)
                  Material(
                    color: C.card2,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      tooltip: 'search_city'.tr,
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () => _searchSheet(geo),
                    ),
                  ),
              ],
            ),
          ),
          // --- status banners
          Positioned(
            top: 58,
            left: 12,
            right: 12,
            child: Column(
              children: [
                if (geo == null && _geoError == null)
                  _banner('loading_geo'.tr, C.card2, null)
                else if (_geoError != null)
                  _banner('${'geo_failed'.tr}: $_geoError', C.red.withValues(alpha: 0.85), null),
                if (_down) _banner('tiles_down'.tr, C.red.withValues(alpha: 0.85), _reload),
              ],
            ),
          ),
          // --- right side buttons
          Positioned(
            right: 10,
            bottom: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapButton(Icons.add, '+', () => _zoomBy(1)),
                _mapButton(Icons.remove, '−', () => _zoomBy(-1)),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: PopupMenuButton<int>(
                    tooltip: 'map_style'.tr,
                    color: C.card2,
                    initialValue: gs.mapStyle,
                    onSelected: (v) => context.read<GameState>().setMapStyle(v),
                    itemBuilder: (_) => [
                      for (final e in const [
                        [0, 'style_auto'],
                        [1, 'style_streets'],
                        [2, 'style_sat'],
                        [3, 'style_offline'],
                      ])
                        PopupMenuItem<int>(
                          value: e[0] as int,
                          child: Row(children: [
                            Icon(gs.mapStyle == e[0] ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
                            const SizedBox(width: 8),
                            Text((e[1] as String).tr),
                          ]),
                        ),
                    ],
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: C.card2, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.layers, color: Colors.white, size: 22),
                    ),
                  ),
                ),
                _mapButton(Icons.refresh, 'reload_map'.tr, _reload),
                _mapButton(Icons.my_location, 'recenter'.tr, () => controller.move(gs.player, 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(String text, Color color, VoidCallback? retry) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(text, style: const TextStyle(fontSize: 12.5))),
            if (retry != null) ...[
              const SizedBox(width: 8),
              InkWell(onTap: retry, child: const Icon(Icons.refresh, size: 18)),
            ],
          ],
        ),
      );
}

// ------------------------------------------------------------------ search

class _SearchSheet extends StatefulWidget {
  final GeoData geo;
  final ValueChanged<GeoPlace> onPick;
  const _SearchSheet({required this.geo, required this.onPick});
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String q = '';

  List<GeoPlace> _results() {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return widget.geo.places.take(30).toList();
    final starts = <GeoPlace>[];
    final contains = <GeoPlace>[];
    for (final p in widget.geo.places) {
      var s0 = false, s1 = false;
      for (final n in p.names) {
        final l = n.toLowerCase();
        if (l.startsWith(s)) {
          s0 = true;
          break;
        }
        if (l.contains(s)) s1 = true;
      }
      if (s0) {
        starts.add(p);
      } else if (s1) {
        contains.add(p);
      }
      if (starts.length >= 40) break;
    }
    return [...starts, ...contains].take(40).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final li = geoLangIndex(gs.lang);
    final res = _results();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'search_hint'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (v) => setState(() => q = v),
              ),
            ),
            Expanded(
              child: res.isEmpty
                  ? Empty('no_results'.tr)
                  : ListView.builder(
                      itemCount: res.length,
                      itemBuilder: (ctx, i) {
                        final p = res[i];
                        final country = p.country >= 0 && p.country < widget.geo.countries.length ? widget.geo.countries[p.country].name(li) : '';
                        return ListTile(
                          leading: Icon(p.cap == 1 ? Icons.star : Icons.location_city, color: p.cap == 1 ? const Color(0xFFFFD166) : C.sub),
                          title: Text(p.name(li)),
                          subtitle: Text(country),
                          onTap: () => widget.onPick(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
