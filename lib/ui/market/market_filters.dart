import 'package:flutter/material.dart';
import '../../core/market/market_models.dart';
import '../../core/market/market_strings.dart';
import 'market_style.dart';

class MarketFilter {
  final String brand, condition;
  final double? min, max;
  const MarketFilter({
    this.brand = 'all',
    this.condition = 'all',
    this.min,
    this.max,
  });
  bool get active =>
      brand != 'all' || condition != 'all' || min != null || max != null;
  bool accepts(MarketListing l) =>
      (brand == 'all' || l.device.brand == brand) &&
      (condition == 'all' ||
          (condition == 'repair' ? l.damaged : !l.damaged)) &&
      (min == null || l.price >= min!) &&
      (max == null || l.price <= max!);
}

Future<MarketFilter?> editMarketFilters(
  BuildContext context,
  MarketFilter value,
) => showModalBottomSheet<MarketFilter>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => Theme(data: marketTheme(), child: _Filters(value: value)),
);

class _Filters extends StatefulWidget {
  final MarketFilter value;
  const _Filters({required this.value});
  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final form = GlobalKey<FormState>();
  late String brand = widget.value.brand, condition = widget.value.condition;
  late final low = TextEditingController(
    text: widget.value.min?.toStringAsFixed(0) ?? '',
  );
  late final high = TextEditingController(
    text: widget.value.max?.toStringAsFixed(0) ?? '',
  );
  @override
  void dispose() {
    low.dispose();
    high.dispose();
    super.dispose();
  }

  double? parse(String value) =>
      double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
  String? validate(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final n = parse(value!);
    if (n == null || !n.isFinite || n < 0 || n > 1000000) {
      return mt('Неверная цена', 'Invalid price', 'Неправильна ціна');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FCFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mt('Фильтры', 'Filters', 'Фільтри'),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: brand,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: mt('Марка', 'Brand', 'Бренд'),
                ),
                items:
                    ['all', 'Apple', 'Samsung', 'Google']
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b == 'all'
                                  ? mt('Все марки', 'All brands', 'Усі бренди')
                                  : b,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => brand = v ?? 'all',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: condition,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: mt('Состояние', 'Condition', 'Стан'),
                ),
                items:
                    ['all', 'working', 'repair']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v == 'all'
                                  ? mt('Любое', 'Any', 'Будь-який')
                                  : v == 'repair'
                                  ? mt(
                                    'Под ремонт',
                                    'For repair',
                                    'Для ремонту',
                                  )
                                  : mt('Исправные', 'Working', 'Справні'),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => condition = v ?? 'all',
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('market_min_price'),
                      controller: low,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: validate,
                      decoration: InputDecoration(
                        labelText: mt(
                          'Цена от, \$',
                          'Min price, \$',
                          'Ціна від, \$',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('market_max_price'),
                      controller: high,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final error = validate(v);
                        if (error != null) return error;
                        if (parse(low.text) != null &&
                            parse(high.text) != null &&
                            parse(low.text)! > parse(high.text)!) {
                          return mt(
                            'Меньше минимума',
                            'Below minimum',
                            'Менше мінімуму',
                          );
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: mt(
                          'Цена до, \$',
                          'Max price, \$',
                          'Ціна до, \$',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('apply_market_filters'),
                  onPressed: () {
                    if (form.currentState!.validate()) {
                      Navigator.pop(
                        context,
                        MarketFilter(
                          brand: brand,
                          condition: condition,
                          min: parse(low.text),
                          max: parse(high.text),
                        ),
                      );
                    }
                  },
                  child: Text(
                    mt(
                      'Показать объявления',
                      'Show listings',
                      'Показати оголошення',
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, const MarketFilter()),
                  child: Text(
                    mt('Сбросить фильтры', 'Reset filters', 'Скинути фільтри'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
