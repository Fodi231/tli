import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/geo.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

/// Real world map (CARTO dark tiles without text). Country and city names are
/// drawn by the game itself, so they always use the language chosen in settings.
/// Tap the map to travel there (costs a small fare).
class MapApp extends StatefulWidget {
  const MapApp({super.key});
  @override
  State<MapApp> createState() => _MapAppState();
}

class _MapAppState extends State<MapApp> {
  final MapController controller = MapController();
  double zoom = 12.5;

  void _move(BuildContext context, GameState gs, LatLng p) {
    final km = const Distance().as(LengthUnit.Kilometer, gs.player, p);
    final fare = context.read<GameState>().movePlayer(p);
    if (fare < 0) {
      toast(context, 'no_money'.tr);
    } else {
      toast(context, '${'moved'.tr} ${km.toStringAsFixed(1)} km · ${'fare'.tr} ${money(fare)}');
    }
  }

  void _orderSheet(BuildContext context, Order o) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
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

  Marker _label(GeoLabel g, String lang, {required bool country}) {
    final text = country ? g.name(lang).toUpperCase() : g.name(lang);
    return Marker(
      point: LatLng(g.lat, g.lng),
      width: 200,
      height: 22,
      child: IgnorePointer(
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: country ? const Color(0xFFB8C4E6) : Colors.white,
              fontSize: country ? 11 : 12,
              fontWeight: country ? FontWeight.w500 : FontWeight.w700,
              letterSpacing: country ? 1.4 : 0,
              shadows: const [
                Shadow(blurRadius: 3, color: Colors.black),
                Shadow(blurRadius: 8, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _labels(String lang) {
    final out = <Marker>[];
    if (zoom < 5.5) {
      for (final g in geoCountries) {
        out.add(_label(g, lang, country: true));
      }
    }
    if (zoom >= 3.5 && zoom < 12) {
      for (final g in geoCities) {
        if (g.rank == 1 || zoom >= 5.5) out.add(_label(g, lang, country: false));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final c = gs.city;
    final markers = <Marker>[
      for (final o in gs.orders.where((o) => o.status != 'done'))
        Marker(
          point: LatLng(o.lat, o.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _orderSheet(context, o),
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

    const subdomains = ['a', 'b', 'c', 'd'];
    return AppPage(
      title: 'map'.tr,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: LatLng(c.lat, c.lng),
                initialZoom: 12.5,
                minZoom: 2,
                maxZoom: 18,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(const LatLng(-85, -180), const LatLng(85, 180)),
                ),
                onTap: (tp, p) => _move(context, gs, p),
                onPositionChanged: (camera, hasGesture) {
                  final z = camera.zoom;
                  if ((z * 2).floor() != (zoom * 2).floor()) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => zoom = z);
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
                  subdomains: subdomains,
                  userAgentPackageName: 'com.techlife.game',
                ),
                // Street names only at close zoom (in the local language of the place).
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png',
                  subdomains: subdomains,
                  userAgentPackageName: 'com.techlife.game',
                  minZoom: 12,
                ),
                MarkerLayer(markers: _labels(gs.lang)),
                MarkerLayer(markers: markers),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                    TextSourceAttribution('© CARTO'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < cities.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cities[i].name(gs.lang) + (i == gs.cityIndex ? '' : ' · \$150')),
                        selected: i == gs.cityIndex,
                        onSelected: (_) {
                          if (i == gs.cityIndex) return;
                          final ok = context.read<GameState>().flyTo(i);
                          if (ok) controller.move(LatLng(cities[i].lat, cities[i].lng), 12.5);
                          toast(context, ok ? '${'flew'.tr} ${cities[i].name(gs.lang)}' : 'no_money'.tr);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 28,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              tooltip: 'recenter'.tr,
              backgroundColor: C.card2,
              onPressed: () => controller.move(gs.player, 12.5),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
