import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

/// Real OpenStreetMap. Tap the map to travel there (costs a small fare).
class MapApp extends StatelessWidget {
  const MapApp({super.key});

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

    return AppPage(
      title: 'map'.tr,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: FlutterMap(
              key: ValueKey('map_${gs.cityIndex}'),
              options: MapOptions(
                initialCenter: LatLng(c.lat, c.lng),
                initialZoom: 12.5,
                onTap: (tp, p) => _move(context, gs, p),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.techlife.game',
                ),
                MarkerLayer(markers: markers),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
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
                          toast(context, ok ? '${'flew'.tr} ${cities[i].name(gs.lang)}' : 'no_money'.tr);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
