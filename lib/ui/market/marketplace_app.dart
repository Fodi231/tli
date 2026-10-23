import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import 'market_chat.dart';
import '../../core/ai_service.dart';
import '../../core/admin_auth.dart';
import '../../core/models.dart';
import '../../core/market/device_catalog.dart';
import '../../core/market/market_models.dart';
import '../../core/market/market_strings.dart';
import '../shell.dart';
import '../widgets.dart';
import 'photo_credit.dart';

const marketBlue = Color(0xFF0099F7);
const marketGray = Color(0xFFF2F3F5);
const marketText = Color(0xFF151719);

class DevicePhoto extends StatelessWidget {
  final String device;
  final BoxFit fit;
  const DevicePhoto(this.device, {super.key, this.fit = BoxFit.contain});
  @override
  Widget build(BuildContext context) {
    final d = deviceFor(device);
    return ColoredBox(
      color: marketGray,
      child:
          d == null
              ? const Icon(Icons.smartphone, color: Colors.blueGrey)
              : Image.asset(
                d.photo,
                fit: d.id == 'pixel7' ? BoxFit.contain : fit,
                errorBuilder:
                    (c, e, s) => const Center(
                      child: Icon(
                        Icons.smartphone,
                        color: Colors.blueGrey,
                        size: 54,
                      ),
                    ),
              ),
    );
  }
}

class MarketplaceApp extends StatefulWidget {
  final int initialTab;
  final String? initialDealId;
  const MarketplaceApp({super.key, this.initialTab = 0, this.initialDealId});
  @override
  State<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends State<MarketplaceApp> {
  late int tab = widget.initialTab;
  late String? dealId = widget.initialDealId;
  MarketListing? selected;
  final search = TextEditingController();
  String brand = 'all', condition = 'all', sort = 'new';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void chat(Deal d) => setState(() {
    dealId = d.id;
    selected = null;
    tab = 3;
  });
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final d = gs.deals.where((d) => d.id == dealId).firstOrNull;
    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        chipTheme: const ChipThemeData(
          backgroundColor: marketGray,
          selectedColor: Color(0xFFE2F4FF),
          side: BorderSide.none,
          labelStyle: TextStyle(
            fontFamily: 'Roboto',
            color: marketText,
            fontSize: 12,
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: marketBlue,
          surface: Colors.white,
        ),
        textTheme: ThemeData.light(useMaterial3: true).textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: marketText,
          displayColor: marketText,
        ),
      ),
      child: Material(
        color: Colors.white,
        child:
            d != null
                ? MarketChat(
                  deal: d,
                  onBack: () => setState(() => dealId = null),
                )
                : selected != null
                ? _detail(gs, selected!)
                : Column(
                  children: [
                    _header(),
                    Expanded(
                      child: switch (tab) {
                        0 || 1 => _browse(gs),
                        2 => _sell(gs),
                        3 => _messages(gs),
                        _ => _profile(gs),
                      },
                    ),
                    NavigationBar(
                      height: 66,
                      selectedIndex: tab,
                      indicatorColor: const Color(0xFFE2F4FF),
                      backgroundColor: Colors.white,
                      onDestinationSelected: (i) => setState(() => tab = i),
                      destinations: [
                        NavigationDestination(
                          icon: const Icon(Icons.search),
                          label: mt('Поиск', 'Browse', 'Пошук'),
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.favorite_border),
                          label: mt('Избранное', 'Saved', 'Обране'),
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.add_box_outlined),
                          label: mt('Продать', 'Sell', 'Продати'),
                        ),
                        NavigationDestination(
                          icon: Badge(
                            isLabelVisible: gs.openDeals > 0,
                            label: Text('${gs.openDeals}'),
                            child: const Icon(Icons.chat_bubble_outline),
                          ),
                          label: mt('Сообщения', 'Inbox', 'Повідомлення'),
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.person_outline),
                          label: mt('Профиль', 'Profile', 'Профіль'),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 12, 3),
    child: Row(
      children: [
        IconButton(
          onPressed: () => context.read<Shell>().close(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
        ),
        const Icon(Icons.bubble_chart, color: marketBlue, size: 30),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            mt('ТехМаркет', 'TechMarket', 'ТехМаркет'),
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: marketGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'TechLife',
            style: TextStyle(fontSize: 10, color: Colors.blueGrey),
          ),
        ),
      ],
    ),
  );
  Widget _browse(GameState gs) {
    final query = search.text.toLowerCase().trim();
    final list =
        marketListings
            .where(
              (l) =>
                  !gs.purchasedListings.contains(l.id) &&
                  (tab != 1 || gs.favorites.contains(l.id)) &&
                  (brand == 'all' || l.device.brand == brand) &&
                  (condition == 'all' ||
                      (condition == 'broken' ? l.damaged : !l.damaged)) &&
                  ('${l.device.name} ${l.device.facts} ${l.color}'
                      .toLowerCase()
                      .contains(query)),
            )
            .toList();
    if (sort != 'new') {
      list.sort(
        (a, b) =>
            sort == 'cheap'
                ? a.price.compareTo(b.price)
                : b.price.compareTo(a.price),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                TextField(
                  key: const ValueKey('market_search'),
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: mt(
                      'Поиск по объявлениям',
                      'Search listings',
                      'Пошук оголошень',
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: marketGray,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon:
                        search.text.isEmpty
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                search.clear();
                                setState(() {});
                              },
                            ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final b in ['all', 'Apple', 'Samsung', 'Google'])
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(
                              b == 'all'
                                  ? mt('Все марки', 'All brands', 'Усі бренди')
                                  : b,
                            ),
                            selected: b == brand,
                            onSelected: (_) => setState(() => brand = b),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (tab == 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6F6FF), Color(0xFFF0EEFF)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mt(
                                  'Техника с историей',
                                  'Tech with a story',
                                  'Техніка з історією',
                                ),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                mt(
                                  'Найди. Почини. Продай дороже.',
                                  'Find it. Fix it. Give it a new life.',
                                  'Знайди. Полагодь. Продай дорожче.',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.phonelink_setup,
                          size: 42,
                          color: marketBlue,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tab == 1
                            ? mt('Избранное', 'Saved listings', 'Обране')
                            : mt(
                              'Рекомендации для вас',
                              'Recommended for you',
                              'Рекомендації для вас',
                            ),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: mt('Сортировать', 'Sort', 'Сортувати'),
                      onSelected: (s) => setState(() => sort = s),
                      icon: const Icon(Icons.sort),
                      itemBuilder:
                          (c) => [
                            PopupMenuItem(
                              value: 'new',
                              child: Text(
                                mt(
                                  'Сначала новые',
                                  'Newest first',
                                  'Спочатку нові',
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'cheap',
                              child: Text(
                                mt('Дешевле', 'Lowest price', 'Дешевші'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'expensive',
                              child: Text(
                                mt('Дороже', 'Highest price', 'Дорожчі'),
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final v in ['all', 'working', 'broken'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              v == 'all'
                                  ? mt('Все', 'All', 'Усі')
                                  : v == 'broken'
                                  ? mt(
                                    'Под ремонт',
                                    'For repair',
                                    'Для ремонту',
                                  )
                                  : mt('Исправные', 'Working', 'Справні'),
                            ),
                            selected: condition == v,
                            onSelected: (_) => setState(() => condition = v),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                mt(
                  'Ничего не найдено',
                  'No matching listings',
                  'Нічого не знайдено',
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverLayoutBuilder(
              builder: (c, constraints) {
                final count =
                    constraints.crossAxisExtent > 950
                        ? 4
                        : constraints.crossAxisExtent > 650
                        ? 3
                        : 2;
                final width =
                    (constraints.crossAxisExtent - (count - 1) * 12) / count;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    mainAxisExtent:
                        width / 1.05 +
                        128 * MediaQuery.textScalerOf(context).scale(1),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (c, i) => _card(gs, list[i]),
                    childCount: list.length,
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    );
  }

  Widget _card(GameState gs, MarketListing l) => InkWell(
    key: ValueKey('listing_${l.id}'),
    onTap: () => setState(() => selected = l),
    borderRadius: BorderRadius.circular(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.05,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: DevicePhoto(l.deviceId),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Material(
                  color: Colors.white.withValues(alpha: .95),
                  shape: const CircleBorder(),
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => gs.toggleFavorite(l.id),
                    icon: Icon(
                      gs.favorites.contains(l.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          gs.favorites.contains(l.id) ? Colors.red : marketText,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          money(l.price),
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        Text(
          '${l.device.name}, ${l.device.storage}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF147AC4),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.damaged
              ? mt('Под ремонт', 'For repair', 'Для ремонту')
              : mt('В хорошем состоянии', 'Good condition', 'Гарний стан'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: l.damaged ? Colors.deepOrange : Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${l.city} · ${l.ageHours} ${mt('ч назад', 'h ago', 'год тому')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    ),
  );
  Widget _detail(GameState gs, MarketListing l) => Column(
    children: [
      Row(
        children: [
          IconButton(
            onPressed: () => setState(() => selected = null),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              l.device.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => gs.toggleFavorite(l.id),
            icon: Icon(
              gs.favorites.contains(l.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
        ],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: DevicePhoto(l.deviceId),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              money(l.price),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            Text(
              '${l.device.name}, ${l.device.storage}',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${l.city} · ${mt('Игровое объявление', 'In-game listing', 'Ігрове оголошення')} № ${l.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            _section(mt('Характеристики', 'Specifications', 'Характеристики')),
            _spec(mt('Процессор', 'Processor', 'Процесор'), l.device.chip),
            _spec(mt('Экран', 'Display', 'Екран'), l.device.screen),
            _spec(mt('Память', 'Storage', 'Пам’ять'), l.device.storage),
            _spec(
              mt('Батарея', 'Battery', 'Батарея'),
              '${l.device.batteryMah} mAh',
            ),
            _spec(mt('Состояние', 'Condition', 'Стан'), faultText(l.fault)),
            const SizedBox(height: 18),
            _section(mt('Описание', 'Description', 'Опис')),
            Text(
              marketDescription(l),
              style: const TextStyle(height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE9F5FF),
                child: Text(l.seller.substring(0, 1)),
              ),
              title: Text(l.seller),
              subtitle: Text(
                '${l.rating} / 5 · ${mt('Частный продавец', 'Private seller', 'Приватний продавець')}',
              ),
              trailing: const Icon(Icons.verified, color: marketBlue),
            ),
            TextButton.icon(
              onPressed: () => showPhotoCredit(context, l.deviceId),
              icon: const Icon(Icons.info_outline, size: 17),
              label: Text(
                mt(
                  'Источник фото и характеристики',
                  'Photo source and facts',
                  'Джерело фото й характеристики',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('contact_seller'),
            onPressed: () {
              final d = gs.openMarketDeal(l.id);
              if (d != null) chat(d);
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              mt('Написать продавцу', 'Message seller', 'Написати продавцю'),
            ),
          ),
        ),
      ),
    ],
  );
  Widget _messages(GameState gs) =>
      gs.deals.isEmpty
          ? Center(
            child: Text(
              mt(
                'Здесь появятся диалоги',
                'Your conversations will appear here',
                'Тут з’являться діалоги',
              ),
            ),
          )
          : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: gs.deals.length,
            separatorBuilder:
                (_, i) => const Divider(height: 1, color: marketGray),
            itemBuilder: (c, i) {
              final d = gs.deals[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                onTap: () => chat(d),
                leading: SizedBox(
                  width: 58,
                  height: 62,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DevicePhoto(d.deviceId ?? d.item),
                  ),
                ),
                title: Text(
                  d.counterpart,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${d.item}\n${d.busy ? mt("Печатает…", "Typing…", "Друкує…") : d.messages.lastOrNull?.text ?? ""}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  d.status == 'won'
                      ? Icons.check_circle
                      : d.status == 'agreed'
                      ? Icons.handshake_outlined
                      : Icons.chevron_right,
                  color: d.status == 'won' ? Colors.green : marketBlue,
                ),
              );
            },
          );
  Widget _sell(GameState gs) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _section(mt('Продать устройство', 'Sell a device', 'Продати пристрій')),
      Text(
        mt(
          'Выбери устройство со склада. После публикации с тобой свяжется игровой покупатель.',
          'Choose a device from inventory. An in-game buyer will contact you after publishing.',
          'Обери пристрій зі складу. Після публікації з тобою зв’яжеться ігровий покупець.',
        ),
        style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
      ),
      const SizedBox(height: 16),
      if (gs.stock.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Text(
            mt(
              'Пока нет устройств. Начни с покупки на вкладке «Поиск».',
              'No devices yet. Buy one from Browse.',
              'Поки немає пристроїв. Придбай один на вкладці «Пошук».',
            ),
          ),
        ),
      for (final item in gs.stock)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: marketGray),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 78,
                height: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      faultText(item.fault),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            item.fault == null
                                ? Colors.green
                                : Colors.deepOrange,
                      ),
                    ),
                    Text(
                      '${mt("Куплено за", "Paid", "Придбано за")} ${money(item.cost)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.fault != null)
                          OutlinedButton(
                            onPressed: () {
                              final o = gs.repairStock(item);
                              if (o != null) {
                                context.read<Shell>().open('repair', arg: o.id);
                              }
                            },
                            child: Text(mt('Ремонт', 'Repair', 'Ремонт')),
                          ),
                        FilledButton(
                          onPressed:
                              gs.stockUnderRepair(item.id)
                                  ? null
                                  : () => _publish(gs, item),
                          child: Text(
                            mt('Выставить', 'List item', 'Виставити'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (gs.playerListings.isNotEmpty) ...[
        _section(mt('Мои объявления', 'My listings', 'Мої оголошення')),
        for (final l in gs.playerListings)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.title),
            subtitle: Text('${money(l.price)} · ${l.status}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final d =
                  gs.deals
                      .where(
                        (d) =>
                            d.stockId == l.stockId &&
                            (d.status == 'open' || d.status == 'agreed'),
                      )
                      .firstOrNull;
              if (d != null) chat(d);
            },
          ),
      ],
    ],
  );
  Future<void> _publish(GameState gs, StockItem item) async {
    final price = TextEditingController(
      text: item.resaleValue.round().toString(),
    );
    final desc = TextEditingController(
      text:
          '${deviceFor(item.deviceId ?? item.name)?.facts ?? item.name}. ${faultText(item.fault)}.',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(
              mt('Новое объявление', 'New listing', 'Нове оголошення'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: mt(
                        'Цена, игровые \$',
                        'Price, game \$',
                        'Ціна, ігрові \$',
                      ),
                    ),
                  ),
                  TextField(
                    controller: desc,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: mt('Описание', 'Description', 'Опис'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(mt('Отмена', 'Cancel', 'Скасувати')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(mt('Опубликовать', 'Publish', 'Опублікувати')),
              ),
            ],
          ),
    );
    if (ok == true && mounted) {
      final p = double.tryParse(price.text.replaceAll(',', '.'));
      final l = p == null ? null : gs.publishListing(item, p, desc.text);
      if (l != null) {
        final d = gs.sellDealFor(item);
        if (d != null) chat(d);
      } else {
        toast(
          context,
          mt(
            'Проверь цену и доступность устройства',
            'Check the price and device availability',
            'Перевір ціну й доступність пристрою',
          ),
        );
      }
    }
    price.dispose();
    desc.dispose();
  }

  Widget _profile(GameState gs) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const CircleAvatar(
        radius: 35,
        backgroundColor: Color(0xFFE7F5FF),
        child: Icon(Icons.person, size: 40, color: marketBlue),
      ),
      const SizedBox(height: 12),
      Text(
        gs.playerName.isEmpty ? 'TechLife Master' : gs.playerName,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      Text(
        '${gs.reputation.toStringAsFixed(1)} / 5',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.green),
      ),
      const SizedBox(height: 25),
      _spec(mt('Баланс', 'Balance', 'Баланс'), money(gs.balance)),
      _spec(mt('Устройства', 'Devices', 'Пристрої'), '${gs.stock.length}'),
      _spec(
        mt('Покупки', 'Purchases', 'Купівлі'),
        '${gs.purchasedListings.length}',
      ),
      const SizedBox(height: 20),
      _section('Gemini AI'),
      Text(
        mt(
          'Продавцы и покупатели отвечают с учётом модели, поломки и истории переписки. ИИ подключается автоматически.',
          'Sellers and buyers use the model, fault and chat history. AI connects automatically.',
          'Продавці та покупці враховують модель, поломку й історію розмови. ШІ підключається автоматично.',
        ),
        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () async {
          final r = await gs.adminTestAi();
          if (mounted) {
            toast(
              context,
              r.ok
                  ? mt(
                    'ИИ готов к работе',
                    'AI is ready',
                    'ШІ готовий до роботи',
                  )
                  : mt(
                    'Сервис временно недоступен. Работают игровые ответы.',
                    'Service temporarily unavailable. Using offline replies.',
                    'Сервіс тимчасово недоступний. Працюють ігрові відповіді.',
                  ),
            );
          }
        },
        icon: const Icon(Icons.auto_awesome),
        label: Text(mt('Проверить ИИ', 'Check AI', 'Перевірити ШІ')),
      ),
      if (AdminAuth.unlocked) ...[
        TextButton(
          onPressed: () {
            gs.useAutomaticAi();
            toast(
              context,
              mt(
                'Автоматический ИИ включён',
                'Automatic AI enabled',
                'Автоматичний ШІ ввімкнено',
              ),
            );
          },
          child: Text(
            mt('Автоматический ИИ', 'Automatic AI', 'Автоматичний ШІ'),
          ),
        ),
        TextButton(
          onPressed:
              () => showDialog<void>(
                context: context,
                builder: (_) => GeminiSetupDialog(gs: gs),
              ),
          child: Text(
            mt(
              'Свой API · администратор',
              'Custom API · administrator',
              'Власний API · адміністратор',
            ),
          ),
        ),
      ],
      OutlinedButton(
        onPressed: () => context.read<Shell>().open('settings'),
        child: Text(mt('Настройки игры', 'Game settings', 'Налаштування гри')),
      ),
      const SizedBox(height: 20),
      Text(
        mt(
          'Все продавцы, сделки и цены здесь игровые. ТехМаркет — часть TechLife.',
          'Sellers, trades and prices are fictional. TechMarket is part of TechLife.',
          'Усі продавці, угоди й ціни тут ігрові. ТехМаркет — частина TechLife.',
        ),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    ],
  );
  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
  );
  Widget _spec(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class GeminiSetupDialog extends StatefulWidget {
  final GameState gs;
  const GeminiSetupDialog({super.key, required this.gs});
  @override
  State<GeminiSetupDialog> createState() => _GeminiSetupDialogState();
}

class _GeminiSetupDialogState extends State<GeminiSetupDialog> {
  late final keyCtrl = TextEditingController(text: widget.gs.geminiKey);
  late final modelCtrl = TextEditingController(
    text:
        widget.gs.aiModel.isEmpty ? AiService.defaultModel : widget.gs.aiModel,
  );
  late String endpoint = widget.gs.aiEndpoint;
  bool busy = false;
  String? result;
  @override
  void dispose() {
    keyCtrl.dispose();
    modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Gemini AI'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mt(
              'Ключ сохраняется на этом устройстве. Скопируй его из Google AI Studio.',
              'The key is saved on this device. Get it from Google AI Studio.',
              'Ключ зберігається на цьому пристрої. Отримай його в Google AI Studio.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: endpoint,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Google API'),
            items: const [
              DropdownMenuItem(
                value: 'gemini',
                child: Text(
                  'Gemini API · AI Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'vertex',
                child: Text(
                  'Vertex / Agent Platform Express',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged:
                busy
                    ? null
                    : (v) {
                      if (v != null) setState(() => endpoint = v);
                    },
          ),
          const SizedBox(height: 8),
          Text(
            mt(
              'AI Studio → Gemini API. Ключ Cloud Express → Vertex. Доступ к API должен быть включён в проекте ключа.',
              'AI Studio → Gemini API. Cloud Express key → Vertex. Enable the selected API in the key’s project.',
              'AI Studio → Gemini API. Ключ Cloud Express → Vertex. Обраний API має бути ввімкнений у проєкті ключа.',
            ),
            style: const TextStyle(fontSize: 11),
          ),
          TextField(
            controller: keyCtrl,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'API key',
              hintText: 'AIza…',
            ),
          ),
          TextField(
            controller: modelCtrl,
            decoration: InputDecoration(
              labelText: mt('Модель', 'Model', 'Модель'),
            ),
          ),
          const SizedBox(height: 12),
          if (busy) const LinearProgressIndicator(),
          if (result != null)
            Text(result!, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(mt('Закрыть', 'Close', 'Закрити')),
      ),
      OutlinedButton(
        onPressed:
            busy
                ? null
                : () async {
                  widget.gs.setAiProvider('', '', '');
                  widget.gs.setGoogleEndpoint(endpoint);
                  widget.gs.setKey(keyCtrl.text);
                  widget.gs.setAiModel(modelCtrl.text);
                  setState(() => busy = true);
                  final r = await widget.gs.adminTestAi();
                  if (mounted) {
                    setState(() {
                      busy = false;
                      result =
                          r.ok
                              ? mt(
                                'Подключение работает',
                                'Connection successful',
                                'Підключення працює',
                              )
                              : r.error;
                    });
                  }
                },
        child: Text(mt('Проверить', 'Test', 'Перевірити')),
      ),
      FilledButton(
        onPressed:
            busy
                ? null
                : () {
                  widget.gs.setAiProvider('', '', '');
                  widget.gs.setGoogleEndpoint(endpoint);
                  widget.gs.setKey(keyCtrl.text);
                  widget.gs.setAiModel(modelCtrl.text);
                  Navigator.pop(context);
                },
        child: Text(mt('Сохранить', 'Save', 'Зберегти')),
      ),
    ],
  );
}
