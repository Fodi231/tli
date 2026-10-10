import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class ShopApp extends StatefulWidget {
  const ShopApp({super.key});
  @override
  State<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends State<ShopApp> {
  String cat = 'all';
  String query = '';

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final list = products.where((p) {
      if (cat != 'all' && p.cat != cat) return false;
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return p.device.toLowerCase().contains(q) || 'part_${p.cat}'.tr.toLowerCase().contains(q);
    }).toList();
    return AppPage(
      title: 'shop'.tr,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'search_parts'.tr,
              filled: true,
              fillColor: C.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ChipRow(
            ids: ['all', ...categories],
            selected: cat,
            label: (id) => id == 'all' ? 'all'.tr : 'cat_$id'.tr,
            onSelect: (id) => setState(() => cat = id),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = list[i];
                final have = gs.parts[p.cat] ?? 0;
                return Panel(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: C.card2, borderRadius: BorderRadius.circular(12)),
                        child: Icon(serviceIcon(p.cat), color: C.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('part_${p.cat}'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${'for_device'.tr} ${p.device}', style: const TextStyle(color: C.sub, fontSize: 12)),
                            Row(children: [
                              Text(money(p.price), style: const TextStyle(color: C.green, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, size: 14, color: C.orange),
                              Text(p.rating.toString(), style: const TextStyle(fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () {
                              final ok = context.read<GameState>().buyPart(p);
                              toast(context, ok ? '${'bought'.tr}: ${'part_${p.cat}'.tr}' : 'no_money'.tr);
                            },
                            child: Text('buy'.tr),
                          ),
                          if (have > 0) Text('x$have', style: const TextStyle(color: C.sub, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
