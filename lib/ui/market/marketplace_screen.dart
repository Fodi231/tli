import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/models.dart';
import '../../core/market/market_models.dart';
import '../../core/market/market_strings.dart';
import '../shell.dart';
import '../widgets.dart' show money;
import 'market_chat.dart';
import 'market_filters.dart';
import 'market_messages.dart';
import 'market_profile.dart';
import 'market_sell.dart';
import 'market_style.dart';
import 'photo_credit.dart';

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
  String? sellStockId;
  final search = TextEditingController(), savedSearch = TextEditingController();
  String category = 'all', savedFilter = 'all', sort = 'new';
  MarketFilter filter = const MarketFilter(),
      favoriteFilter = const MarketFilter();
  @override
  void dispose() {
    search.dispose();
    savedSearch.dispose();
    super.dispose();
  }

  void chat(Deal deal) {
    context.read<GameState>().markDealRead(deal);
    setState(() {
      dealId = deal.id;
      selected = null;
      tab = 3;
    });
  }

  void changeTab(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      tab = value;
      selected = null;
      dealId = null;
    });
  }

  void editListing(String stockId) => setState(() {
    sellStockId = stockId;
    tab = 2;
  });
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final deal = gs.deals.where((d) => d.id == dealId).firstOrNull;
    return Theme(
      data: marketTheme(),
      child: LayoutBuilder(
        builder:
            (context, viewport) => Material(
              color: const Color(0xFFF5FBFA),
              child: MarketBackground(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child:
                        deal != null
                            ? MarketChat(
                              deal: deal,
                              onBack: () => setState(() => dealId = null),
                            )
                            : selected != null
                            ? _detail(gs, selected!)
                            : Column(
                              children: [
                                if (viewport.maxHeight >= 260)
                                  MarketHeader(
                                    balance: gs.balance,
                                    onHome: () => context.read<Shell>().close(),
                                    onWallet:
                                        () =>
                                            context.read<Shell>().open('bank'),
                                  ),
                                Expanded(
                                  key: const ValueKey('market_active_page'),
                                  child: switch (tab) {
                                    0 => _browse(gs),
                                    1 => _favorites(gs),
                                    2 => MarketSell(
                                      key: ValueKey(
                                        'sell_${sellStockId ?? 'default'}',
                                      ),
                                      initialStockId: sellStockId,
                                      onListed: chat,
                                      onBrowse: () => changeTab(0),
                                      onDraftSaved: () => changeTab(4),
                                    ),
                                    3 => MarketMessages(
                                      onChat: chat,
                                      onBrowse: () => changeTab(0),
                                    ),
                                    _ => MarketProfile(
                                      onChat: chat,
                                      onEdit: editListing,
                                      onSell: () => changeTab(2),
                                    ),
                                  },
                                ),
                                if (viewport.maxHeight >= 260)
                                  MarketBottomBar(
                                    index: tab,
                                    unread: gs.unreadMarketMessages,
                                    onChanged: changeTab,
                                  ),
                              ],
                            ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _searchField(
    TextEditingController controller, {
    required bool saved,
  }) => Row(
    children: [
      Expanded(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0D2E6068),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            key: ValueKey(saved ? 'favorites_search' : 'market_search'),
            controller: controller,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText:
                  saved
                      ? mt(
                        'Поиск в избранном',
                        'Search saved listings',
                        'Пошук в обраному',
                      )
                      : mt('Найти технику', 'Find a device', 'Знайти техніку'),
              prefixIcon: const Icon(Icons.search, color: marketDeep, size: 25),
              suffixIcon:
                  controller.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: mt('Очистить', 'Clear', 'Очистити'),
                        icon: const Icon(Icons.close, size: 19),
                        onPressed: () {
                          controller.clear();
                          setState(() {});
                        },
                      ),
              fillColor: const Color(0xCCEBF4F5),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 48,
        height: 50,
        child: MarketSurface(
          radius: 17,
          padding: EdgeInsets.zero,
          shadow: true,
          child: IconButton(
            key: ValueKey(saved ? 'favorites_filters' : 'market_filters'),
            tooltip: mt('Фильтры', 'Filters', 'Фільтри'),
            onPressed: () async {
              final result = await editMarketFilters(
                context,
                saved ? favoriteFilter : filter,
              );
              if (result != null && mounted) {
                setState(() {
                  if (saved) {
                    favoriteFilter = result;
                  } else {
                    filter = result;
                  }
                });
              }
            },
            icon: Badge(
              isLabelVisible: (saved ? favoriteFilter : filter).active,
              backgroundColor: marketBlue,
              child: const Icon(Icons.tune_rounded, color: marketDeep),
            ),
          ),
        ),
      ),
    ],
  );

  List<MarketListing> _matching(GameState gs, {bool saved = false}) {
    final query = (saved ? savedSearch : search).text.toLowerCase().trim();
    final listings =
        marketListings
            .where(
              (l) =>
                  !gs.purchasedListings.contains(l.id) &&
                  (!saved || gs.favorites.contains(l.id)) &&
                  (saved || category == 'all' || category == 'smartphones') &&
                  (saved ? favoriteFilter : filter).accepts(l) &&
                  (!saved ||
                      savedFilter == 'all' ||
                      (savedFilter == 'drop'
                          ? gs.favoritePriceDropped(l)
                          : l.damaged)) &&
                  ('${l.device.name} ${l.device.facts} ${l.color} ${l.seller}'
                      .toLowerCase()
                      .contains(query)),
            )
            .toList();
    if (sort != 'new') {
      listings.sort(
        (a, b) =>
            sort == 'cheap'
                ? a.price.compareTo(b.price)
                : b.price.compareTo(a.price),
      );
    }
    return listings;
  }

  Widget _sort() => PopupMenuButton<String>(
    tooltip: mt('Сортировать', 'Sort', 'Сортувати'),
    onSelected: (value) => setState(() => sort = value),
    itemBuilder:
        (_) => [
          PopupMenuItem(
            value: 'new',
            child: Text(mt('Сначала новые', 'Newest first', 'Спочатку нові')),
          ),
          PopupMenuItem(
            value: 'cheap',
            child: Text(
              mt('Сначала дешевле', 'Lowest price', 'Спочатку дешевші'),
            ),
          ),
          PopupMenuItem(
            value: 'expensive',
            child: Text(
              mt('Сначала дороже', 'Highest price', 'Спочатку дорожчі'),
            ),
          ),
        ],
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: marketGray.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EBEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sort == 'new'
                ? mt('Сначала новые', 'Newest first', 'Спочатку нові')
                : sort == 'cheap'
                ? mt('Дешевле', 'Lowest price', 'Дешевші')
                : mt('Дороже', 'Highest price', 'Дорожчі'),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more, size: 17),
        ],
      ),
    ),
  );

  Widget _browse(GameState gs) {
    final list = _matching(gs);
    return CustomScrollView(
      key: const PageStorageKey('market_catalog_scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchField(search, saved: false),
                const SizedBox(height: 9),
                MarketPills(
                  children: [
                    for (final c in [
                      'all',
                      'smartphones',
                      'laptops',
                      'consoles',
                    ])
                      MarketPill(
                        c == 'all'
                            ? mt('Всё', 'All', 'Усе')
                            : c == 'smartphones'
                            ? mt('Смартфоны', 'Phones', 'Смартфони')
                            : c == 'laptops'
                            ? mt('Ноутбуки', 'Laptops', 'Ноутбуки')
                            : mt('Консоли', 'Consoles', 'Консолі'),
                        key: ValueKey('category_$c'),
                        selected: category == c,
                        onTap: () => setState(() => category = c),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _hero(),
                const SizedBox(height: 13),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 7,
                  children: [
                    Text(
                      mt('Для тебя', 'For you', 'Для тебе'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    _sort(),
                  ],
                ),
                if (filter.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: TextButton.icon(
                      onPressed:
                          () => setState(() => filter = const MarketFilter()),
                      icon: const Icon(Icons.close, size: 15),
                      label: Text(
                        mt(
                          'Сбросить фильтры',
                          'Reset filters',
                          'Скинути фільтри',
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: MarketEmpty(
              icon: Icons.search_off_rounded,
              title: mt(
                'Пока ничего не найдено',
                'No listings found',
                'Поки нічого не знайдено',
              ),
              subtitle:
                  category == 'laptops' || category == 'consoles'
                      ? mt(
                        'В этой категории пока нет объявлений. Загляни в смартфоны.',
                        'No listings in this category yet. Explore phones.',
                        'У цій категорії поки немає оголошень. Переглянь смартфони.',
                      )
                      : mt(
                        'Попробуй другое название или измени фильтры.',
                        'Try another query or change the filters.',
                        'Спробуй іншу назву або зміни фільтри.',
                      ),
              action: mt('Показать всё', 'Show all', 'Показати все'),
              onAction:
                  () => setState(() {
                    category = 'all';
                    filter = const MarketFilter();
                    search.clear();
                  }),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverLayoutBuilder(
              builder: (context, box) {
                final columns =
                    box.crossAxisExtent > 920
                        ? 4
                        : box.crossAxisExtent > 630
                        ? 3
                        : 2;
                final width =
                    (box.crossAxisExtent - (columns - 1) * 10) / columns;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    mainAxisExtent:
                        width / 1.03 +
                        123 * MediaQuery.textScalerOf(context).scale(1),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _card(gs, list[i]),
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

  Widget _hero() => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003C43), Color(0xFF007F86)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),
        ),
        Positioned.fill(
          left: 100,
          child: Image.asset(
            'assets/market/banner_devices.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF003F46),
                  Color(0xE600454B),
                  Color(0x00003D45),
                ],
                stops: [0, .44, .8],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mt(
                        'Вторая жизнь\nтехники',
                        'A second life\nfor tech',
                        'Друге життя\nтехніки',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mt(
                        'Находи выгодные предложения',
                        'Find your next great deal',
                        'Знаходь вигідні пропозиції',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFD3F4ED),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(flex: 4, child: SizedBox(height: 114)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _card(GameState gs, MarketListing l) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: ValueKey('listing_${l.id}'),
      onTap: () => setState(() => selected = l),
      borderRadius: BorderRadius.circular(18),
      child: MarketSurface(
        radius: 18,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.03,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DevicePhoto(l.deviceId),
                    Positioned(
                      top: 3,
                      right: 3,
                      child: IconButton(
                        tooltip:
                            gs.favorites.contains(l.id)
                                ? mt(
                                  'Убрать из избранного',
                                  'Remove from saved',
                                  'Прибрати з обраного',
                                )
                                : mt(
                                  'В избранное',
                                  'Save listing',
                                  'До обраного',
                                ),
                        onPressed: () => gs.toggleFavorite(l.id),
                        icon: Icon(
                          gs.favorites.contains(l.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              gs.favorites.contains(l.id)
                                  ? marketBlue
                                  : marketText,
                          size: 23,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 7,
                      left: 7,
                      right: 7,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: MarketTag(
                          l.damaged
                              ? mt('Под ремонт', 'For repair', 'Для ремонту')
                              : mt('Б/у', 'Used', 'Б/в'),
                          repair: l.damaged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.device.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    money(l.price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l.damaged
                        ? faultText(l.fault)
                        : '${faultText(null)} · ${l.device.storage}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: marketMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _favorites(GameState gs) {
    final saved =
        marketListings
            .where(
              (l) =>
                  gs.favorites.contains(l.id) &&
                  !gs.purchasedListings.contains(l.id),
            )
            .toList();
    final list = _matching(gs, saved: true);
    return CustomScrollView(
      key: const PageStorageKey('market_saved_scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarketHeading(
                  mt('Избранное', 'Saved', 'Обране'),
                  mt(
                    'Сохранённая техника всегда под рукой',
                    'Your favorite finds, always close',
                    'Збережена техніка завжди під рукою',
                  ),
                ),
                _searchField(savedSearch, saved: true),
                const SizedBox(height: 9),
                MarketPills(
                  children: [
                    MarketPill(
                      '${mt('Все', 'All', 'Усі')} · ${saved.length}',
                      selected: savedFilter == 'all',
                      onTap: () => setState(() => savedFilter = 'all'),
                    ),
                    MarketPill(
                      '${mt('Подешевело', 'Price drops', 'Подешевшало')} · ${saved.where(gs.favoritePriceDropped).length}',
                      selected: savedFilter == 'drop',
                      onTap: () => setState(() => savedFilter = 'drop'),
                    ),
                    MarketPill(
                      '${mt('Под ремонт', 'For repair', 'Для ремонту')} · ${saved.where((l) => l.damaged).length}',
                      selected: savedFilter == 'repair',
                      onTap: () => setState(() => savedFilter = 'repair'),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 3, 6),
                  decoration: BoxDecoration(
                    color: marketMint.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: marketDeep,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mt(
                            'Сообщим, если цена снизится',
                            'Notify me about price drops',
                            'Повідомимо, якщо ціна знизиться',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: marketDeep,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: .75,
                        child: Switch(
                          key: const ValueKey('favorite_price_alerts'),
                          value: gs.favoritePriceAlerts,
                          onChanged: gs.setFavoritePriceAlerts,
                          activeThumbColor: marketBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: MarketEmpty(
              icon: Icons.favorite_border,
              title:
                  saved.isEmpty
                      ? mt(
                        'Здесь будут любимые находки',
                        'Keep your favorite finds here',
                        'Тут будуть улюблені знахідки',
                      )
                      : mt(
                        'Нет подходящих объявлений',
                        'No matching listings',
                        'Немає відповідних оголошень',
                      ),
              subtitle: mt(
                'Нажми на сердечко в каталоге, чтобы сохранить устройство.',
                'Tap a heart in the catalog to save a device.',
                'Натисни сердечко в каталозі, щоб зберегти пристрій.',
              ),
              action: mt(
                'Найти ещё технику',
                'Find more devices',
                'Знайти ще техніку',
              ),
              onAction: () => changeTab(0),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverList.builder(
              itemCount: list.length,
              itemBuilder:
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _savedCard(gs, list[i]),
                  ),
            ),
          ),
        if (list.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
            sliver: SliverToBoxAdapter(
              child: OutlinedButton.icon(
                onPressed: () => changeTab(0),
                icon: const Icon(Icons.search),
                label: Text(
                  mt(
                    'Найти ещё технику',
                    'Find more devices',
                    'Знайти ще техніку',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _savedCard(GameState gs, MarketListing l) => LayoutBuilder(
    builder:
        (context, box) => MarketSurface(
          padding: const EdgeInsets.all(7),
          radius: 20,
          child: InkWell(
            onTap: () => setState(() => selected = l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: (box.maxWidth * .33).clamp(90, 180),
                  height: 154,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: DevicePhoto(l.deviceId),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                l.device.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => gs.toggleFavorite(l.id),
                                tooltip: mt(
                                  'Убрать из избранного',
                                  'Remove from saved',
                                  'Прибрати з обраного',
                                ),
                                icon: const Icon(
                                  Icons.favorite,
                                  color: marketBlue,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (gs.favoritePriceDropped(l)) ...[
                          MarketTag(
                            mt('Цена снижена', 'Price reduced', 'Ціну знижено'),
                          ),
                          const SizedBox(height: 5),
                        ],
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 7,
                          children: [
                            Text(
                              money(l.price),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (gs.favoritePriceDropped(l))
                              Text(
                                money(gs.favoriteReferencePrices[l.id]!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: marketMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${l.device.storage} · ${faultText(l.fault)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: marketMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            MarketAvatar(l.seller, size: 23),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                l.seller,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: marketMuted,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC23D),
                              size: 14,
                            ),
                            Text(
                              l.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: () => setState(() => selected = l),
                            child: Text(
                              mt('Подробнее', 'View listing', 'Докладніше'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );

  Widget _detail(GameState gs, MarketListing l) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() => selected = null),
              tooltip: mt('Назад', 'Back', 'Назад'),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
            Expanded(
              child: Text(
                l.device.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => gs.toggleFavorite(l.id),
              icon: Icon(
                gs.favorites.contains(l.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: marketBlue,
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: DevicePhoto(l.deviceId),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              money(l.price),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            Text(
              '${l.device.name}, ${l.device.storage}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: MarketTag(
                l.damaged
                    ? mt('Под ремонт', 'For repair', 'Для ремонту')
                    : mt('Б/у', 'Used', 'Б/в'),
                repair: l.damaged,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l.city} · № ${l.id}',
              style: const TextStyle(color: marketMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            MarketSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mt('Характеристики', 'Specifications', 'Характеристики'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _spec(
                    mt('Процессор', 'Processor', 'Процесор'),
                    l.device.chip,
                  ),
                  _spec(mt('Экран', 'Display', 'Екран'), l.device.screen),
                  _spec(mt('Память', 'Storage', 'Пам’ять'), l.device.storage),
                  _spec(
                    mt('Батарея', 'Battery', 'Батарея'),
                    '${l.device.batteryMah} mAh',
                  ),
                  _spec(
                    mt('Состояние', 'Condition', 'Стан'),
                    faultText(l.fault),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              mt('Описание', 'Description', 'Опис'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 9),
            Text(
              marketDescription(l),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            MarketSurface(
              child: Row(
                children: [
                  MarketAvatar(l.seller, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.seller,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          mt(
                            'Частный продавец',
                            'Private seller',
                            'Приватний продавець',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: marketMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFC23D),
                    size: 19,
                  ),
                  Text(l.rating.toStringAsFixed(1)),
                ],
              ),
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
            const SizedBox(height: 15),
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
              final deal = gs.openMarketDeal(l.id);
              if (deal != null) chat(deal);
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

  Widget _spec(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: marketMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
