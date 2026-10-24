import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/admin_auth.dart';
import '../../core/game_state.dart';
import '../../core/models.dart';
import '../../core/market/device_catalog.dart';
import '../../core/market/market_models.dart';
import '../../core/market/market_strings.dart';
import '../shell.dart';
import '../widgets.dart' show money, toast;
import 'gemini_setup_dialog.dart';
import 'market_style.dart';

class MarketProfile extends StatefulWidget {
  final ValueChanged<Deal> onChat;
  final ValueChanged<String> onEdit;
  final VoidCallback onSell;
  const MarketProfile({
    super.key,
    required this.onChat,
    required this.onEdit,
    required this.onSell,
  });
  @override
  State<MarketProfile> createState() => _MarketProfileState();
}

class _MarketProfileState extends State<MarketProfile> {
  String filter = 'active';
  Future<void> sheet(String title, List<Widget> children) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF8FCFC),
        builder:
            (c) => Theme(
              data: marketTheme(),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(c).height * .82,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(c),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
      );
  void history(GameState gs) {
    final completed = gs.deals.where((d) => d.status == 'won').toList();
    sheet(mt('История сделок', 'Trade history', 'Історія угод'), [
      if (completed.isEmpty)
        MarketEmpty(
          icon: Icons.receipt_long_outlined,
          title: mt(
            'Всё ещё впереди',
            'Your story starts here',
            'Усе ще попереду',
          ),
          subtitle: mt(
            'Завершённые покупки и продажи появятся здесь.',
            'Completed purchases and sales will appear here.',
            'Завершені купівлі та продажі з’являться тут.',
          ),
        ),
      for (final d in completed)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 7),
          leading: Icon(
            d.kind == 'buy' ? Icons.shopping_bag_outlined : Icons.sell_outlined,
            color: marketBlue,
          ),
          title: Text(d.item),
          subtitle: Text(d.counterpart),
          trailing: Text(
            money(d.price),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
    ]);
  }

  void reputation(
    GameState gs,
  ) => sheet(mt('Репутация', 'Reputation', 'Репутація'), [
    const Icon(Icons.star_rounded, color: Color(0xFFFFC23D), size: 45),
    Text(
      '${gs.reputation.toStringAsFixed(1)} / 5',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 15),
    Text(
      mt(
        'На репутацию влияют завершённые ремонты и сделки. Аккуратная работа и выполненные договорённости помогают ей расти.',
        'Completed repairs and trades affect your reputation. Careful work and keeping your promises help it grow.',
        'На репутацію впливають завершені ремонти й угоди. Акуратна робота та виконані домовленості допомагають їй зростати.',
      ),
      style: const TextStyle(height: 1.5),
    ),
    const SizedBox(height: 15),
    Text(
      '${mt('Выполнено ремонтов', 'Repairs completed', 'Виконано ремонтів')}: ${gs.completedOrders}',
    ),
    Text(
      '${mt('Завершено сделок', 'Trades completed', 'Завершено угод')}: ${gs.deals.where((d) => d.status == 'won').length}',
    ),
  ]);
  void language(GameState gs) =>
      sheet(mt('Язык приложения', 'App language', 'Мова застосунку'), [
        for (final entry
            in {'ru': 'Русский', 'en': 'English', 'uk': 'Українська'}.entries)
          ListTile(
            title: Text(entry.value),
            selected: gs.lang == entry.key,
            selectedColor: marketBlue,
            trailing:
                gs.lang == entry.key
                    ? const Icon(Icons.check, color: marketBlue)
                    : null,
            onTap: () {
              gs.setLang(entry.key);
              Navigator.pop(context);
            },
          ),
      ]);
  void help(GameState gs) => sheet(mt('Помощь', 'Help', 'Допомога'), [
    Text(
      mt(
        'Покупай устройства в каталоге, договаривайся в сообщениях и подтверждай цену кнопкой сделки. Купленная техника появится в инвентаре.',
        'Find devices in the catalog, negotiate in messages, and confirm the trade with its button. Purchased devices appear in your inventory.',
        'Купуй пристрої в каталозі, домовляйся в повідомленнях і підтверджуй ціну кнопкою угоди. Придбана техніка з’явиться в інвентарі.',
      ),
      style: const TextStyle(height: 1.5),
    ),
    const SizedBox(height: 15),
    Text(
      mt(
        'Во вкладке «Продать» можно выбрать устройство, добавить фото и сохранить черновик. Состояние определяется устройством и выполненным ремонтом.',
        'In Sell, choose a device, add photos, and save a draft. Its condition follows the device and completed repairs.',
        'На вкладці «Продати» обери пристрій, додай фото та збережи чернетку. Стан визначається пристроєм і виконаним ремонтом.',
      ),
      style: const TextStyle(height: 1.5),
    ),
    const SizedBox(height: 15),
    Text(
      mt(
        'ИИ подключается автоматически. При недоступности сервиса используются помеченные игровые ответы.',
        'AI connects automatically. If the service is unavailable, the game uses marked fallback replies.',
        'ШІ підключається автоматично. Якщо сервіс недоступний, використовуються позначені ігрові відповіді.',
      ),
      style: const TextStyle(height: 1.5),
    ),
    const SizedBox(height: 15),
    OutlinedButton.icon(
      onPressed: () async {
        final result = await gs.adminTestAi();
        if (mounted) {
          toast(
            context,
            result.ok
                ? mt(
                  'Подключение работает',
                  'Connection successful',
                  'Підключення працює',
                )
                : mt(
                  'Сервис временно недоступен',
                  'Service temporarily unavailable',
                  'Сервіс тимчасово недоступний',
                ),
          );
        }
      },
      icon: const Icon(Icons.auto_awesome_outlined),
      label: Text(mt('Проверить ИИ', 'Check AI', 'Перевірити ШІ')),
    ),
  ]);
  Widget stat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: marketMuted),
        ),
      ],
    ),
  );
  String status(PlayerListing l) => switch (l.status) {
    'sold' => mt('Продано', 'Sold', 'Продано'),
    'paused' => mt('На паузе', 'Paused', 'На паузі'),
    'replaced' => mt('Обновлено', 'Replaced', 'Оновлено'),
    _ => mt('Активно', 'Active', 'Активне'),
  };
  Widget ownCard(GameState gs, PlayerListing l) {
    final item = gs.stock.where((s) => s.id == l.stockId).firstOrNull;
    final model =
        l.deviceId ??
        item?.deviceId ??
        deviceCatalog
            .where((d) => l.title.startsWith(d.name))
            .firstOrNull
            ?.id ??
        l.title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MarketSurface(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 86,
              height: 102,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child:
                    l.photos.isEmpty
                        ? DevicePhoto(model)
                        : ListingPhoto(l.photos.first, device: model),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      money(l.price),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    MarketTag(status(l)),
                    const SizedBox(height: 6),
                    Text(
                      '№ ${l.id}',
                      style: const TextStyle(fontSize: 10, color: marketMuted),
                    ),
                    if (l.status == 'active')
                      TextButton(
                        onPressed: () {
                          final d =
                              gs.deals
                                  .where(
                                    (d) =>
                                        d.stockId == l.stockId &&
                                        (d.status == 'open' ||
                                            d.status == 'agreed'),
                                  )
                                  .firstOrNull;
                          if (d != null) widget.onChat(d);
                        },
                        child: Text(
                          mt(
                            'К переписке',
                            'Open conversation',
                            'До листування',
                          ),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (item != null && !gs.stockUnderRepair(item.id))
              SizedBox(
                width: 36,
                height: 38,
                child: IconButton(
                  key: ValueKey('edit_listing_${l.id}'),
                  onPressed: () => widget.onEdit(l.stockId),
                  tooltip: mt(
                    'Изменить объявление',
                    'Edit listing',
                    'Змінити оголошення',
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: marketDeep,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final won = gs.deals.where((d) => d.status == 'won').toList();
    final closed =
        gs.deals.where((d) => d.status == 'won' || d.status == 'lost').length;
    final sold = won.where((d) => d.kind == 'sell').length,
        bought = won.where((d) => d.kind == 'buy').length;
    final active = gs.playerListings.where((l) => l.status == 'active').length;
    final soldListings =
        gs.playerListings.where((l) => l.status == 'sold').length;
    final list =
        gs.playerListings
            .where((l) => filter == 'all' || l.status == filter)
            .toList();
    final verified = gs.reputation >= 4.5 && won.length >= 5;
    final name =
        gs.playerName.isEmpty
            ? mt('Мастер', 'Master', 'Майстер')
            : gs.playerName;
    return ListView(
      key: const PageStorageKey('market_profile_scroll'),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      children: [
        MarketHeading(
          mt('Профиль', 'Profile', 'Профіль'),
          '',
          trailing: IconButton(
            tooltip: mt('Настройки игры', 'Game settings', 'Налаштування гри'),
            onPressed: () => context.read<Shell>().open('settings'),
            icon: const Icon(Icons.settings_outlined, color: marketDeep),
          ),
        ),
        MarketSurface(
          shadow: true,
          child: Column(
            children: [
              Row(
                children: [
                  MarketAvatar(name, size: 76, master: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: marketMint,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                verified
                                    ? Icons.verified
                                    : Icons.handyman_outlined,
                                color: marketBlue,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  verified
                                      ? mt(
                                        'Проверенный продавец',
                                        'Trusted seller',
                                        'Перевірений продавець',
                                      )
                                      : won.isEmpty
                                      ? mt(
                                        'Новый продавец',
                                        'New seller',
                                        'Новий продавець',
                                      )
                                      : mt(
                                        'Продавец ТехМаркета',
                                        'TechMarket seller',
                                        'Продавець ТехМаркету',
                                      ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: marketDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC23D),
                              size: 21,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              gs.reputation.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '· ${mt('репутация', 'reputation', 'репутація')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: marketMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 29),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stat('$sold', mt('Продано', 'Sold', 'Продано')),
                  stat('$bought', mt('Куплено', 'Bought', 'Придбано')),
                  stat(
                    closed == 0
                        ? '—'
                        : '${(won.length / closed * 100).round()}%',
                    mt('Успешных сделок', 'Successful trades', 'Успішних угод'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.read<Shell>().open('bank'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xFF003C43), Color(0xFF007D82)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mt('Баланс', 'Balance', 'Баланс'),
                          style: const TextStyle(
                            color: Color(0xFFAFD7D6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          money(gs.balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mt(
                            'Доступно для покупок',
                            'Available for purchases',
                            'Доступно для покупок',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .3),
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: Text(
                mt('Мои объявления', 'My listings', 'Мої оголошення'),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => filter = 'all'),
              child: Text(mt('Все ›', 'All ›', 'Усі ›')),
            ),
          ],
        ),
        MarketPills(
          children: [
            MarketPill(
              '${mt('Активные', 'Active', 'Активні')} · $active',
              selected: filter == 'active',
              onTap: () => setState(() => filter = 'active'),
            ),
            MarketPill(
              '${mt('Проданные', 'Sold', 'Продані')} · $soldListings',
              selected: filter == 'sold',
              onTap: () => setState(() => filter = 'sold'),
            ),
            MarketPill(
              '${mt('Черновики', 'Drafts', 'Чернетки')} · ${gs.marketDrafts.length}',
              key: const ValueKey('profile_drafts'),
              selected: filter == 'draft',
              onTap: () => setState(() => filter = 'draft'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filter == 'draft') ...[
          if (gs.marketDrafts.isEmpty) _noListings(),
          for (final draft in gs.marketDrafts.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MarketSurface(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: ValueKey('draft_${draft.stockId}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    Icons.edit_note_rounded,
                    color: marketBlue,
                    size: 30,
                  ),
                  title: Text(
                    draft.title.isEmpty
                        ? mt('Без названия', 'Untitled', 'Без назви')
                        : draft.title,
                  ),
                  subtitle: Text(
                    mt(
                      'Продолжить редактирование',
                      'Continue editing',
                      'Продовжити редагування',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onEdit(draft.stockId),
                ),
              ),
            ),
        ] else ...[
          if (list.isEmpty) _noListings(),
          for (final l in list) ownCard(gs, l),
        ],
        const SizedBox(height: 8),
        MarketSurface(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            children: [
              _row(
                Icons.receipt_long_outlined,
                mt('История сделок', 'Trade history', 'Історія угод'),
                () => history(gs),
              ),
              const Divider(height: 1),
              _row(
                Icons.star_outline_rounded,
                mt('Репутация', 'Reputation', 'Репутація'),
                () => reputation(gs),
              ),
              const Divider(height: 1),
              _row(
                Icons.language,
                mt('Язык приложения', 'App language', 'Мова застосунку'),
                () => language(gs),
                value:
                    gs.lang == 'en'
                        ? 'English'
                        : gs.lang == 'uk'
                        ? 'Українська'
                        : 'Русский',
              ),
              const Divider(height: 1),
              _row(
                Icons.help_outline_rounded,
                mt('Помощь', 'Help', 'Допомога'),
                () => help(gs),
              ),
            ],
          ),
        ),
        if (AdminAuth.unlocked) ...[
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed:
                () => showDialog<void>(
                  context: context,
                  builder:
                      (_) => Theme(
                        data: marketTheme(),
                        child: GeminiSetupDialog(gs: gs),
                      ),
                ),
            child: Text(
              mt(
                'Свой API · администратор',
                'Custom API · administrator',
                'Власний API · адміністратор',
              ),
            ),
          ),
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
        ],
      ],
    );
  }

  Widget _noListings() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: OutlinedButton.icon(
      onPressed: widget.onSell,
      icon: const Icon(Icons.add),
      label: Text(
        mt('Создать объявление', 'Create listing', 'Створити оголошення'),
      ),
    ),
  );
  Widget _row(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? value,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: marketDeep, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          if (value != null)
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: marketMuted),
              ),
            ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right, color: marketMuted, size: 20),
        ],
      ),
    ),
  );
}
