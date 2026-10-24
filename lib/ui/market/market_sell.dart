import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/models.dart';
import '../../core/market/device_catalog.dart';
import '../../core/market/market_strings.dart';
import '../shell.dart';
import '../widgets.dart' show money, toast;
import 'market_style.dart';

class MarketSell extends StatefulWidget {
  final String? initialStockId;
  final ValueChanged<Deal> onListed;
  final VoidCallback onBrowse, onDraftSaved;
  const MarketSell({
    super.key,
    this.initialStockId,
    required this.onListed,
    required this.onBrowse,
    required this.onDraftSaved,
  });
  @override
  State<MarketSell> createState() => _MarketSellState();
}

class _MarketSellState extends State<MarketSell> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      description = TextEditingController(),
      price = TextEditingController();
  String? stockId;
  List<String> photos = [];
  bool picking = false;
  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    final item =
        gs.stock.where((s) => s.id == widget.initialStockId).firstOrNull ??
        gs.stock.where((s) => !gs.stockUnderRepair(s.id)).firstOrNull ??
        gs.stock.firstOrNull;
    if (item != null) load(item, gs);
  }

  void load(StockItem item, GameState gs) {
    stockId = item.id;
    final draft = gs.marketDrafts[item.id];
    final listing =
        gs.playerListings
            .where((l) => l.stockId == item.id && l.status == 'active')
            .firstOrNull;
    final spec = deviceFor(item.deviceId ?? item.name);
    title.text =
        draft?.title ??
        listing?.title ??
        '${item.name}${spec == null ? '' : ', ${spec.storage}'}';
    description.text =
        draft?.description ??
        listing?.description ??
        '${faultText(item.fault)}. ${item.repaired ? mt('Ремонт выполнен, устройство проверено.', 'Repaired and tested.', 'Ремонт виконано, пристрій перевірено.') : ''}'
            .trim();
    price.text =
        draft?.price ?? (listing?.price ?? item.resaleValue).round().toString();
    photos = List.of(
      draft?.photos ??
          (listing?.photos.isNotEmpty == true
              ? listing!.photos
              : spec == null
              ? <String>[]
              : [spec.photo]),
    );
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  void persist() {
    final gs = context.read<GameState>();
    final item = gs.stock.where((s) => s.id == stockId).firstOrNull;
    if (item != null) {
      gs.saveMarketDraft(
        item,
        title: title.text,
        description: description.text,
        price: price.text,
        photos: photos,
      );
    }
  }

  void edited(String _) {
    setState(() {});
    persist();
  }

  Future<void> choose() async {
    final gs = context.read<GameState>();
    final item = await showModalBottomSheet<StockItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FCFC),
      builder:
          (c) => Theme(
            data: marketTheme(),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(c).height * .75,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      mt('Твой инвентарь', 'Your inventory', 'Твій інвентар'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final s in gs.stock)
                      ListTile(
                        key: ValueKey('choose_stock_${s.id}'),
                        contentPadding: const EdgeInsets.symmetric(vertical: 7),
                        leading: SizedBox(
                          width: 52,
                          height: 64,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: DevicePhoto(s.deviceId ?? s.name),
                          ),
                        ),
                        title: Text(s.name),
                        subtitle: Text(
                          gs.stockUnderRepair(s.id)
                              ? mt(
                                'Сейчас в ремонте',
                                'Being repaired',
                                'Зараз у ремонті',
                              )
                              : faultText(s.fault),
                        ),
                        trailing: Icon(
                          s.id == stockId
                              ? Icons.check_circle
                              : Icons.chevron_right,
                          color: marketBlue,
                        ),
                        onTap: () => Navigator.pop(c, s),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
    if (item != null && mounted) setState(() => load(item, gs));
  }

  Future<void> addPhoto() async {
    if (photos.length >= 10 || picking) return;
    setState(() => picking = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 72,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 1000000 ||
          photos.fold(0, (n, p) => n + p.length) + bytes.length * 4 / 3 >
              6000000) {
        toast(
          context,
          mt(
            'Фото слишком большое. Выбери изображение поменьше.',
            'Photo is too large. Choose a smaller image.',
            'Фото завелике. Обери менше зображення.',
          ),
        );
        return;
      }
      final png = bytes.length > 3 && bytes[0] == 137 && bytes[1] == 80;
      final jpeg = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216;
      if (!png && !jpeg) {
        toast(
          context,
          mt(
            'Выбери фото JPEG или PNG.',
            'Choose a JPEG or PNG photo.',
            'Обери фото JPEG або PNG.',
          ),
        );
        return;
      }
      setState(
        () => photos.add(
          'data:image/${png ? 'png' : 'jpeg'};base64,${base64Encode(bytes)}',
        ),
      );
      persist();
    } catch (_) {
      if (mounted) {
        toast(
          context,
          mt(
            'Не удалось открыть фото. Можно использовать фото модели.',
            'Could not open the photo. You can use the model photo.',
            'Не вдалося відкрити фото. Можна використати фото моделі.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  void publish(StockItem item, GameState gs) {
    if (!form.currentState!.validate()) return;
    if (photos.isEmpty) {
      toast(
        context,
        mt(
          'Добавь хотя бы одно фото.',
          'Add at least one photo.',
          'Додай хоча б одне фото.',
        ),
      );
      return;
    }
    final amount = double.tryParse(
      price.text.replaceAll(',', '.').replaceAll(' ', ''),
    );
    final listing =
        amount == null
            ? null
            : gs.publishListing(
              item,
              amount,
              description.text,
              title: title.text,
              photos: photos,
            );
    if (listing == null) {
      toast(
        context,
        mt(
          'Устройство недоступно для продажи.',
          'This device is not available for sale.',
          'Пристрій недоступний для продажу.',
        ),
      );
      return;
    }
    final deal = gs.sellDealFor(item);
    if (deal != null) widget.onListed(deal);
  }

  Widget fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF566470),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final item = gs.stock.where((s) => s.id == stockId).firstOrNull;
    if (item == null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          MarketHeading(
            mt('Продать технику', 'Sell a device', 'Продати техніку'),
            mt(
              'Создай объявление из своего инвентаря',
              'Create a listing from your inventory',
              'Створи оголошення зі свого інвентарю',
            ),
          ),
          MarketEmpty(
            icon: Icons.inventory_2_outlined,
            title: mt(
              'Сначала найди устройство',
              'Find your first device',
              'Спочатку знайди пристрій',
            ),
            subtitle: mt(
              'Здесь появится техника, которую ты купишь в ТехМаркете.',
              'Devices you buy in TechMarket will appear here.',
              'Тут з’явиться техніка, яку ти придбаєш у ТехМаркеті.',
            ),
            action: mt(
              'Перейти в каталог',
              'Explore the catalog',
              'Перейти до каталогу',
            ),
            onAction: widget.onBrowse,
          ),
          if (gs.stock.isNotEmpty)
            OutlinedButton(
              onPressed: choose,
              child: Text(
                mt('Выбрать устройство', 'Choose a device', 'Обрати пристрій'),
              ),
            ),
        ],
      );
    }
    final spec = deviceFor(item.deviceId ?? item.name);
    final condition =
        item.fault != null
            ? mt('Под ремонт', 'For repair', 'Для ремонту')
            : item.repaired
            ? mt('После ремонта', 'Repaired', 'Після ремонту')
            : mt('Б/у', 'Used', 'Б/в');
    final amount = double.tryParse(
      price.text.replaceAll(',', '.').replaceAll(' ', ''),
    );
    final validAmount =
        amount != null && amount.isFinite && amount >= 1 && amount <= 1000000;
    final repairing = gs.stockUnderRepair(item.id);
    return Form(
      key: form,
      child: ListView(
        key: const PageStorageKey('market_sell_scroll'),
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        children: [
          MarketHeading(
            mt('Продать технику', 'Sell a device', 'Продати техніку'),
            mt(
              'Создай объявление из своего инвентаря',
              'Create a listing from your inventory',
              'Створи оголошення зі свого інвентарю',
            ),
          ),
          MarketSurface(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DevicePhoto(item.deviceId ?? item.name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spec?.storage ?? condition,
                        style: const TextStyle(
                          fontSize: 12,
                          color: marketMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const ValueKey('change_sell_device'),
                  onPressed: choose,
                  child: Text(
                    mt('Изменить', 'Change', 'Змінити'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  mt('Фото техники', 'Device photos', 'Фото техніки'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${photos.length}/10',
                style: const TextStyle(color: marketMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: SizedBox(
                      width: 113,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ListingPhoto(
                              photos[i],
                              device: item.deviceId ?? item.name,
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: IconButton(
                                  key: ValueKey('remove_listing_photo_$i'),
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: .9,
                                    ),
                                  ),
                                  tooltip: mt(
                                    'Удалить фото',
                                    'Remove photo',
                                    'Видалити фото',
                                  ),
                                  icon: const Icon(Icons.close, size: 17),
                                  onPressed: () {
                                    setState(() => photos.removeAt(i));
                                    persist();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (photos.length < 10)
                  SizedBox(
                    width: 113,
                    child: Material(
                      color: const Color(0xFFEFF8F6),
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        key: const ValueKey('add_listing_photo'),
                        borderRadius: BorderRadius.circular(15),
                        onTap: picking ? null : addPhoto,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBE1DE)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (picking)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.add,
                                  size: 31,
                                  color: marketBlue,
                                ),
                              const SizedBox(height: 9),
                              Text(
                                mt('Добавить', 'Add photo', 'Додати'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: marketMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (spec != null &&
              !photos.contains(spec.photo) &&
              photos.length < 10)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() => photos.insert(0, spec.photo));
                  persist();
                },
                child: Text(
                  mt(
                    'Использовать фото модели',
                    'Use model photo',
                    'Використати фото моделі',
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel(mt('Категория', 'Category', 'Категорія')),
                    InputDecorator(
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.smartphone, size: 19),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              mt('Смартфоны', 'Phones', 'Смартфони'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel(mt('Состояние', 'Condition', 'Стан')),
                    InputDecorator(
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.build_outlined, size: 19),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              condition,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          fieldLabel(mt('Название', 'Title', 'Назва')),
          TextFormField(
            key: const ValueKey('listing_title'),
            controller: title,
            onChanged: edited,
            maxLength: 100,
            decoration: const InputDecoration(counterText: ''),
            validator:
                (s) =>
                    (s ?? '').trim().isEmpty
                        ? mt('Укажи название', 'Enter a title', 'Вкажи назву')
                        : null,
          ),
          fieldLabel(mt('Описание', 'Description', 'Опис')),
          TextFormField(
            key: const ValueKey('listing_description'),
            controller: description,
            onChanged: edited,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            decoration: const InputDecoration(counterText: ''),
            validator:
                (s) =>
                    (s ?? '').trim().isEmpty
                        ? mt(
                          'Добавь описание',
                          'Add a description',
                          'Додай опис',
                        )
                        : null,
          ),
          fieldLabel(mt('Цена продажи', 'Selling price', 'Ціна продажу')),
          TextFormField(
            key: const ValueKey('listing_price'),
            controller: price,
            onChanged: edited,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: '\$'),
            validator:
                (_) =>
                    validAmount
                        ? null
                        : mt(
                          'Укажи цену от 1 до 1 000 000',
                          'Enter a price from 1 to 1,000,000',
                          'Вкажи ціну від 1 до 1 000 000',
                        ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: marketBlue, size: 19),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${mt('Ориентир по состоянию', 'Condition-based estimate', 'Орієнтир за станом')}: ${money(item.resaleValue)}',
                  style: const TextStyle(color: marketBlue, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          MarketSurface(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mt(
                          'Комиссия сервиса',
                          'Service fee',
                          'Комісія сервісу',
                        ),
                        style: const TextStyle(
                          color: marketMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Text('\$0'),
                  ],
                ),
                const Divider(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mt('Ты получишь', 'You receive', 'Ти отримаєш'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      validAmount ? money(amount) : '—',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  mt(
                    'После подтверждения сделки',
                    'After confirming the trade',
                    'Після підтвердження угоди',
                  ),
                  style: const TextStyle(fontSize: 10, color: marketMuted),
                ),
              ],
            ),
          ),
          if (repairing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                mt(
                  'Сначала заверши текущий ремонт.',
                  'Finish the current repair first.',
                  'Спочатку заверши поточний ремонт.',
                ),
                style: const TextStyle(color: Colors.deepOrange),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('publish_listing'),
            onPressed: repairing ? null : () => publish(item, gs),
            child: Text(
              mt(
                'Опубликовать объявление',
                'Publish listing',
                'Опублікувати оголошення',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            key: const ValueKey('save_listing_draft'),
            onPressed: () {
              persist();
              widget.onDraftSaved();
            },
            child: Text(
              mt('Сохранить черновик', 'Save draft', 'Зберегти чернетку'),
            ),
          ),
          if (item.fault != null)
            OutlinedButton.icon(
              onPressed: () {
                final order = gs.repairStock(item);
                if (order != null) {
                  context.read<Shell>().open('repair', arg: order.id);
                }
              },
              icon: const Icon(Icons.build_outlined),
              label: Text(
                mt(
                  'Сначала отремонтировать',
                  'Repair it first',
                  'Спочатку відремонтувати',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
