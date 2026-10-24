import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/game_state.dart';
import '../../core/models.dart';
import '../shell.dart';
import '../widgets.dart' show toast;
import '../liquid_surface.dart';
import '../luma/luma_card.dart';

String lt(String ru, String en, String uk) => lumaText(ru, en, uk);
String usd(num n) =>
    '\$ ${n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ')}';

ThemeData _bankTheme() => ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.fromSeed(
    seedColor: lumaPurple,
    brightness: Brightness.light,
    surface: const Color(0xFFFAF8FF),
  ),
  textTheme: ThemeData.light().textTheme.apply(
    fontFamily: 'Roboto',
    bodyColor: lumaInk,
    displayColor: lumaInk,
  ),
  dividerColor: const Color(0xFFECE8F5),
  useMaterial3: true,
);

class BankApp extends StatefulWidget {
  const BankApp({super.key});
  @override
  State<BankApp> createState() => _BankAppState();
}

class _BankAppState extends State<BankApp> {
  int tab = 0, filter = 0, days = 10;
  String page = '', selected = 'classic', search = '';
  bool hide = false, consent = false, creditConsent = false;
  double credit = 1000;
  GameState get g => context.read<GameState>();
  void go(String p) => setState(() => page = p);
  void tell(String text) => toast(context, text);
  String get failed => lt(
    'Недостаточно средств, карта заморожена или превышен лимит.',
    'Insufficient funds, frozen card or daily limit exceeded.',
    'Недостатньо коштів, картку заморожено або перевищено ліміт.',
  );
  void done(bool ok) {
    if (ok) {
      tell(lt('Готово', 'Done', 'Готово'));
    } else {
      tell(failed);
    }
  }

  Widget title(String text, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
          ),
        ),
        if (action != null) action,
      ],
    ),
  );
  Widget box(Widget child, {EdgeInsets? padding}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: LiquidSurface(
      light: true,
      tint: const Color(0xFFFEFCFF),
      radius: 22,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    ),
  );
  Widget muted(String t) =>
      Text(t, style: const TextStyle(color: lumaMuted, fontSize: 13));
  Widget circle(IconData icon, VoidCallback onTap, {double size = 46}) =>
      SizedBox(
        width: size,
        height: size,
        child: IconButton(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: lumaPurple.withValues(alpha: .055),
            side: const BorderSide(color: Colors.white),
            shape: const CircleBorder(),
            foregroundColor: lumaPurple,
          ),
          icon: Icon(icon, size: size * .48),
        ),
      );
  Widget primary(String text, VoidCallback? action, {bool outline = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: action,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              backgroundColor:
                  outline ? Colors.white.withValues(alpha: .35) : lumaPurple,
              foregroundColor: outline ? lumaPurple : Colors.white,
              side:
                  outline
                      ? BorderSide(color: lumaPurple.withValues(alpha: .3))
                      : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
  Widget row(
    IconData icon,
    String label,
    VoidCallback? tap, {
    String? sub,
    Widget? trailing,
  }) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lumaPurple.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: lumaPurple, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: muted(sub),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          trailing ??
              (tap == null
                  ? const SizedBox()
                  : const Icon(Icons.chevron_right, color: lumaPurple)),
        ],
      ),
    ),
  );
  Widget section(String label, {VoidCallback? all}) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -.4,
            ),
          ),
        ),
        if (all != null)
          TextButton(onPressed: all, child: Text(lt('Все', 'All', 'Усі'))),
      ],
    ),
  );
  Widget balance(double amount, {String? label}) => Padding(
    padding: const EdgeInsets.fromLTRB(5, 20, 5, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        muted(
          label ??
              lt(
                'Доступно на карте',
                'Available on card',
                'Доступно на картці',
              ),
        ),
        Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hide ? '••••••' : usd(amount),
                  style: const TextStyle(
                    fontSize: 43,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            circle(
              hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              () => setState(() => hide = !hide),
              size: 36,
            ),
          ],
        ),
      ],
    ),
  );
  Widget card({bool business = false, bool demo = false, String? design}) =>
      LumaCard(
        design: design ?? g.luma.style,
        holder:
            business
                ? 'TECHLIFE SERVICE'
                : g.playerName.isEmpty
                ? 'TECHLIFE MASTER'
                : g.playerName,
        business: business,
        demo: demo,
      );
  Widget actions(List<(IconData, String, VoidCallback)> list) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in list)
          Expanded(
            child: Column(
              children: [
                circle(a.$1, a.$3, size: 55),
                const SizedBox(height: 7),
                Text(
                  a.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final theme = _bankTheme();
    return Theme(
      data: theme,
      child: ColoredBox(
        color: const Color(0xFFF8F6FD),
        child: LayoutBuilder(
          builder:
              (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.6,
                        colors: [Color(0xFFF1EAFE), Color(0xFFFCFAFF)],
                      ),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      textStyle: theme.textTheme.bodyMedium,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(5, 3, 14, 4),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: lt('Назад', 'Back', 'Назад'),
                                  onPressed: () {
                                    if (page.isNotEmpty) {
                                      go('');
                                    } else {
                                      context.read<Shell>().close();
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: lumaInk,
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/icon/luma.jpg',
                                    width: 35,
                                    height: 42,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Luma',
                                  style: TextStyle(
                                    fontSize: 29,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.2,
                                    color: lumaInk,
                                  ),
                                ),
                                const Spacer(),
                                circle(
                                  Icons.notifications_none_rounded,
                                  () => go('notifications'),
                                  size: 36,
                                ),
                                const SizedBox(width: 10),
                                circle(
                                  Icons.person_outline_rounded,
                                  () => go('profile'),
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              key: ValueKey(
                                'luma_${gs.luma.opened ? tab : 'welcome'}_$page',
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    constraints.maxWidth < 350 ? 14 : 20,
                                vertical: 8,
                              ),
                              child: _content(gs),
                            ),
                          ),
                          if (gs.luma.opened && page.isEmpty) _navigation(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _content(GameState gs) {
    if (page == 'notifications') return _notifications();
    if (page == 'profile') return _profile();
    if (!gs.luma.opened) return _welcome();
    return switch (page) {
      'manage' => _manage(),
      'design' => _designs(),
      'details' => _details(),
      'history' => _history(),
      'schedule' => _schedule(),
      _ => switch (tab) {
        0 => _home(),
        1 => _payments(),
        2 => _savings(),
        3 => _credits(),
        _ => _business(),
      },
    };
  }

  Widget _navigation() {
    final labels = [
      lt('Главная', 'Home', 'Головна'),
      lt('Платежи', 'Payments', 'Платежі'),
      lt('Накопления', 'Savings', 'Заощадження'),
      lt('Кредиты', 'Loans', 'Кредити'),
      lt('Бизнес', 'Business', 'Бізнес'),
    ];
    const icons = [
      Icons.home_rounded,
      Icons.credit_card_rounded,
      Icons.savings_outlined,
      Icons.trending_up_rounded,
      Icons.work_outline_rounded,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 9),
      child: LiquidSurface(
        light: true,
        tint: const Color(0xFFF9F5FF),
        radius: 29,
        padding: const EdgeInsets.all(5),
        child: Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: InkWell(
                key: ValueKey('luma_tab_$i'),
                onTap:
                    () => setState(() {
                      tab = i;
                      search = '';
                    }),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 1,
                  ),
                  decoration: BoxDecoration(
                    color:
                        tab == i
                            ? lumaPurple.withValues(alpha: .10)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        color: tab == i ? lumaPurple : lumaMuted,
                        size: 23,
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          style: TextStyle(
                            color: tab == i ? lumaPurple : lumaMuted,
                            fontSize: 9,
                            fontWeight:
                                tab == i ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(
        lt(
          'Твоя первая карта Luma',
          'Your first Luma card',
          'Твоя перша картка Luma',
        ),
      ),
      muted(
        lt(
          'Для покупок, продаж и развития сервиса',
          'For purchases, sales and growing your workshop',
          'Для покупок, продажів та розвитку сервісу',
        ),
      ),
      const SizedBox(height: 24),
      card(demo: true, design: selected),
      const SizedBox(height: 24),
      for (final v in [
        lt(
          'Открытие и обслуживание — \$ 0',
          'Opening and maintenance — \$ 0',
          'Відкриття й обслуговування — \$ 0',
        ),
        lt('Мгновенные переводы', 'Instant transfers', 'Миттєві перекази'),
        lt(
          'Оплата покупок в ТехМаркете',
          'Pay for TechMarket purchases',
          'Оплата покупок у ТехМаркеті',
        ),
      ])
        row(Icons.check_rounded, v, null),
      const SizedBox(height: 14),
      box(
        row(
          Icons.toll_outlined,
          lt('Валюта счёта', 'Account currency', 'Валюта рахунку'),
          null,
          sub: 'USD · ${lt('Доллары', 'Dollars', 'Долари')}',
        ),
      ),
      section(
        lt(
          'Выбрать дизайн карты',
          'Choose a card design',
          'Обрати дизайн картки',
        ),
      ),
      _styleChoices(freeOnly: true),
      _LumaConsent(
        contentPadding: EdgeInsets.zero,
        value: consent,
        onChanged: (v) => setState(() => consent = v!),
        title: Text(
          lt(
            'Принимаю условия обслуживания',
            'I accept the service terms',
            'Приймаю умови обслуговування',
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      muted(
        lt(
          'Карта использует текущий баланс TechLife. Открытие не добавляет денег.',
          'The card uses your existing TechLife balance. Opening it does not add money.',
          'Картка використовує поточний баланс TechLife. Відкриття не додає грошей.',
        ),
      ),
      primary(
        lt(
          'Открыть карту бесплатно',
          'Open a free card',
          'Відкрити картку безкоштовно',
        ),
        consent
            ? () {
              g.openLumaCard(selected);
              setState(() {
                page = '';
              });
            }
            : null,
      ),
      const SizedBox(height: 12),
    ],
  );
  Widget _home() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(
        lt('Мои карты', 'My cards', 'Мої картки'),
        action: circle(
          Icons.add,
          () => tell(
            lt(
              'Личная карта уже открыта. Бизнес-карта — во вкладке «Бизнес».',
              'Your personal card is open. Find your business card in Business.',
              'Особисту картку вже відкрито. Бізнес-картка — у вкладці «Бізнес».',
            ),
          ),
          size: 40,
        ),
      ),
      GestureDetector(onTap: () => go('manage'), child: card()),
      const SizedBox(height: 12),
      Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: lumaPurple,
            shape: BoxShape.circle,
          ),
        ),
      ),
      balance(g.balance),
      if (g.luma.frozen)
        box(
          row(
            Icons.ac_unit,
            lt('Карта заморожена', 'Card is frozen', 'Картку заморожено'),
            () => go('manage'),
          ),
        ),
      actions([
        (Icons.add, lt('Пополнить', 'Add money', 'Поповнити'), _topUp),
        (
          Icons.arrow_forward,
          lt('Перевести', 'Transfer', 'Переказати'),
          () => _transfer(),
        ),
        (
          Icons.receipt_long_outlined,
          lt('Реквизиты', 'Details', 'Реквізити'),
          () => go('details'),
        ),
        (Icons.more_horiz, lt('Ещё', 'More', 'Ще'), () => go('manage')),
      ]),
      box(
        row(
          Icons.settings_outlined,
          lt('Управление картой', 'Manage card', 'Керування карткою'),
          () => go('manage'),
          sub: lt(
            'Лимиты, безопасность, настройки',
            'Limits, security, settings',
            'Ліміти, безпека, налаштування',
          ),
        ),
      ),
      box(
        row(
          Icons.palette_outlined,
          lt('Изменить дизайн', 'Change design', 'Змінити дизайн'),
          () {
            selected = g.luma.style;
            go('design');
          },
        ),
      ),
      section(
        lt('История операций', 'Transaction history', 'Історія операцій'),
        all: () => go('history'),
      ),
      _transactions(g.txns.take(5).toList()),
    ],
  );
  Widget _transactions(List<Txn> txns) {
    if (txns.isEmpty) {
      return box(
        row(
          Icons.receipt_long_outlined,
          lt(
            'Здесь появятся твои операции',
            'Your transactions will appear here',
            'Тут з’являться твої операції',
          ),
          null,
        ),
      );
    }
    return box(
      Column(
        children: [
          for (var i = 0; i < txns.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            row(
              txns[i].amount >= 0
                  ? Icons.south_east_rounded
                  : Icons.shopping_bag_outlined,
              txns[i].title,
              null,
              sub:
                  '${txns[i].time.day.toString().padLeft(2, '0')}.${txns[i].time.month.toString().padLeft(2, '0')} · ${txns[i].time.hour.toString().padLeft(2, '0')}:${txns[i].time.minute.toString().padLeft(2, '0')}',
              trailing: Text(
                '${txns[i].amount >= 0 ? '+' : '-'}${usd(txns[i].amount.abs())}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      txns[i].amount >= 0 ? const Color(0xFF159F7B) : lumaInk,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(lt('История операций', 'Transaction history', 'Історія операцій')),
      _transactions(g.txns),
    ],
  );
  Widget _payments() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(lt('Платежи', 'Payments', 'Платежі')),
      TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: lt(
            'Получатель или услуга',
            'Recipient or service',
            'Одержувач або послуга',
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: .65),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => search = v.toLowerCase()),
      ),
      const SizedBox(height: 12),
      box(
        row(
          Icons.credit_card,
          'Luma ·· 2048',
          () => go('manage'),
          sub: hide ? '••••' : usd(g.balance),
        ),
      ),
      _two(
        box(
          row(
            Icons.credit_card,
            lt('По номеру карты', 'Card number', 'За номером картки'),
            () => _transfer(cardNumber: true),
            sub: lt(
              'Перевод на карту',
              'Transfer to a card',
              'Переказ на картку',
            ),
          ),
        ),
        box(
          row(
            Icons.swap_horiz,
            lt('Между счетами', 'Own accounts', 'Між рахунками'),
            _betweenAccounts,
            sub: lt(
              'Личный / Бизнес',
              'Personal / Business',
              'Особистий / Бізнес',
            ),
          ),
        ),
      ),
      if (g.luma.recent.isNotEmpty) ...[
        section(
          lt('Недавние переводы', 'Recent transfers', 'Нещодавні перекази'),
        ),
        box(
          Column(
            children: [
              for (final r in g.luma.recent.where(
                (r) => r.recipient.toLowerCase().contains(search),
              ))
                row(
                  Icons.person_outline,
                  r.recipient,
                  () => _transfer(recipient: r.recipient),
                  sub: usd(r.amount),
                ),
            ],
          ),
        ),
      ],
      section(lt('Оплатить', 'Pay', 'Сплатити')),
      box(
        Column(
          children: [
            if (_matches(
              lt(
                'Заказы и покупки',
                'Orders and purchases',
                'Замовлення та покупки',
              ),
            ))
              row(
                Icons.shopping_bag_outlined,
                lt(
                  'Заказы и покупки',
                  'Orders and purchases',
                  'Замовлення та покупки',
                ),
                () => context.read<Shell>().open('market'),
                sub: lt('ТехМаркет', 'TechMarket', 'ТехМаркет'),
              ),
            if (_matches(lt('Поставщики', 'Suppliers', 'Постачальники')))
              row(
                Icons.apartment,
                lt('Поставщики', 'Suppliers', 'Постачальники'),
                () => context.read<Shell>().open('shop'),
                sub: lt(
                  'Запчасти и материалы',
                  'Parts and supplies',
                  'Запчастини й матеріали',
                ),
              ),
            if (_matches(lt('Налоги', 'Taxes', 'Податки')))
              row(
                Icons.receipt_long_outlined,
                lt('Налоги', 'Taxes', 'Податки'),
                () => _payTax(),
                sub: usd(g.taxDue),
              ),
            if (_matches(lt('Страхование', 'Insurance', 'Страхування')))
              row(
                Icons.shield_outlined,
                lt('Страхование', 'Insurance', 'Страхування'),
                g.insured ? null : () => _insure(),
                sub: g.insured ? lt('Активно', 'Active', 'Активне') : usd(200),
              ),
          ],
        ),
      ),
      section(lt('Шаблоны', 'Templates', 'Шаблони')),
      box(
        Column(
          children: [
            for (final t in g.luma.templates.where(
              (t) => _matches(t.recipient),
            ))
              row(
                Icons.receipt_long_outlined,
                t.recipient,
                () => _confirm(
                  t.recipient,
                  usd(t.amount),
                  () => g.transferLuma(t.recipient, t.amount),
                  requirePin: true,
                ),
                sub: usd(t.amount),
                trailing: IconButton(
                  tooltip: lt(
                    'Удалить шаблон',
                    'Delete template',
                    'Видалити шаблон',
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed:
                      () => _confirm(
                        lt(
                          'Удалить шаблон?',
                          'Delete template?',
                          'Видалити шаблон?',
                        ),
                        t.recipient,
                        () {
                          g.deleteLumaTemplate(t.recipient);
                          return true;
                        },
                      ),
                ),
              ),
            row(
              Icons.add,
              lt('Создать шаблон', 'Create template', 'Створити шаблон'),
              () => _transfer(template: true),
            ),
          ],
        ),
      ),
    ],
  );
  bool _matches(String s) => search.isEmpty || s.toLowerCase().contains(search);
  Widget _two(Widget a, Widget b) => LayoutBuilder(
    builder:
        (context, c) =>
            c.maxWidth < 360
                ? Column(children: [a, b])
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: a),
                    const SizedBox(width: 10),
                    Expanded(child: b),
                  ],
                ),
  );
  Widget _savings() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(
        lt('Накопления', 'Savings', 'Заощадження'),
        action: circle(Icons.add, _newGoal, size: 40),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE6DBFF), Color(0xFFCDB8FC)],
          ),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lt('Всего накоплено', 'Total saved', 'Усього накопичено')),
            const SizedBox(height: 12),
            Text(
              hide ? '••••' : usd(g.luma.saved + g.luma.deposited + g.invested),
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      for (final goal in g.luma.goals)
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(
                Icons.track_changes_rounded,
                goal.name,
                null,
                sub:
                    '${usd(goal.amount)} ${lt('из', 'of', 'з')} ${usd(goal.target)}',
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (goal.amount / goal.target).clamp(0, 1),
                  minHeight: 9,
                  backgroundColor: const Color(0xFFECE5FC),
                  color: lumaPurple,
                ),
              ),
              const SizedBox(height: 8),
              muted('${(goal.amount / goal.target * 100).round()}%'),
              _two(
                primary(
                  lt('Пополнить', 'Add money', 'Поповнити'),
                  () => _amount(goal.name, (a) => g.moveLumaGoal(goal.id, a)),
                ),
                primary(
                  lt('Снять', 'Withdraw', 'Зняти'),
                  () => _amount(
                    goal.name,
                    (a) => g.moveLumaGoal(goal.id, a, withdraw: true),
                  ),
                  outline: true,
                ),
              ),
            ],
          ),
        ),
      if (g.luma.goals.isEmpty)
        box(
          row(
            Icons.track_changes,
            lt(
              'Создай первую цель',
              'Create your first goal',
              'Створи першу ціль',
            ),
            _newGoal,
            sub: lt(
              'Например, новое оборудование',
              'For example, new equipment',
              'Наприклад, нове обладнання',
            ),
          ),
        ),
      box(
        row(
          Icons.sync,
          lt('Автопополнение', 'Auto save', 'Автопоповнення'),
          null,
          sub: lt(
            '10% доходов в первую незавершённую цель',
            '10% of income to the first unfinished goal',
            '10% доходів у першу незавершену ціль',
          ),
          trailing: Switch(
            value: g.luma.autoSave,
            onChanged: (v) => g.updateLumaSettings(autoSave: v),
          ),
        ),
      ),
      section(lt('Вклады', 'Deposits', 'Вклади')),
      box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(
              Icons.savings_outlined,
              lt('Luma Вклад', 'Luma Deposit', 'Luma Вклад'),
              null,
            ),
            const Text(
              '5%',
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w700),
            ),
            muted(
              lt(
                'За 30 игровых дней · от \$ 100\nВыплата в конце срока на личный счёт',
                'Over 30 game days · from \$ 100\nPaid to your personal account at maturity',
                'За 30 ігрових днів · від \$ 100\nВиплата на особистий рахунок наприкінці строку',
              ),
            ),
            primary(
              lt('Открыть вклад', 'Open deposit', 'Відкрити вклад'),
              () => _amount(
                lt(
                  'Открыть вклад · минимум \$ 100',
                  'Open deposit · min \$ 100',
                  'Відкрити вклад · мінімум \$ 100',
                ),
                g.openLumaDeposit,
              ),
            ),
          ],
        ),
      ),
      for (final d in g.luma.deposits)
        box(
          row(
            Icons.savings_outlined,
            usd(d.principal),
            null,
            sub:
                '${lt('Выплата', 'Payout', 'Виплата')}: ${usd(cents(d.principal * 1.05))} · ${lt('день', 'day', 'день')} ${d.dueDay}',
          ),
        ),
      if (g.invested > 0)
        box(
          row(
            Icons.history,
            lt(
              'Прежние инвестиции',
              'Legacy investments',
              'Попередні інвестиції',
            ),
            () => _confirm(
              lt(
                'Снять инвестиции',
                'Withdraw investments',
                'Зняти інвестиції',
              ),
              usd(g.invested),
              () {
                g.withdrawInvest();
                return true;
              },
            ),
            sub: usd(g.invested),
          ),
        ),
      box(
        row(
          Icons.add,
          lt(
            'Новая цель накоплений',
            'New savings goal',
            'Нова ціль заощаджень',
          ),
          _newGoal,
        ),
      ),
      _timeNote(),
    ],
  );
  Widget _credits() {
    final interest = LumaBank.creditInterest(credit, days),
        total = cents(credit + interest);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title(lt('Кредиты', 'Loans', 'Кредити')),
        muted(
          lt(
            'На покупки и развитие сервиса',
            'For purchases and workshop growth',
            'На покупки та розвиток сервісу',
          ),
        ),
        const SizedBox(height: 16),
        if (g.loan > 0)
          box(
            Column(
              children: [
                row(
                  Icons.description_outlined,
                  lt('Активный кредит', 'Active loan', 'Активний кредит'),
                  () => go('schedule'),
                  sub:
                      '${lt('Осталось', 'Remaining', 'Залишилось')}: ${usd(g.loan)}',
                ),
                if (g.luma.missedPayments > 0)
                  Text(
                    lt(
                      'Есть пропущенные платежи',
                      'There are missed payments',
                      'Є пропущені платежі',
                    ),
                    style: const TextStyle(color: Colors.red),
                  ),
                primary(
                  lt('Погасить', 'Repay', 'Погасити'),
                  () => _amount(
                    lt(
                      'Погашение кредита',
                      'Loan repayment',
                      'Погашення кредиту',
                    ),
                    g.repayLuma,
                  ),
                ),
                primary(
                  lt('График платежей', 'Payment schedule', 'Графік платежів'),
                  () => go('schedule'),
                  outline: true,
                ),
              ],
            ),
          )
        else
          box(
            row(
              Icons.description_outlined,
              lt(
                'У тебя нет активных кредитов',
                'You have no active loans',
                'У тебе немає активних кредитів',
              ),
              null,
            ),
          ),
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lt('Кредит Luma', 'Luma Loan', 'Кредит Luma'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              muted(lt('Сумма кредита', 'Loan amount', 'Сума кредиту')),
              Text(
                usd(credit),
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Slider(
                value: credit,
                min: 100,
                max: 10000,
                divisions: 99,
                onChanged: (v) => setState(() => credit = v.roundToDouble()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [muted(usd(100)), muted(usd(10000))],
              ),
              section(lt('Срок', 'Term', 'Строк')),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in [5, 10, 20])
                    ChoiceChip(
                      label: Text('$d ${lt('дней', 'days', 'днів')}'),
                      selected: days == d,
                      onSelected: (_) => setState(() => days = d),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _summary(
                lt('Сумма кредита', 'Principal', 'Сума кредиту'),
                usd(credit),
              ),
              _summary(
                lt(
                  'Проценты за срок',
                  'Interest for term',
                  'Відсотки за строк',
                ),
                usd(interest),
              ),
              const Divider(),
              _summary(
                lt(
                  'Всего к возврату',
                  'Total to repay',
                  'Усього до повернення',
                ),
                usd(total),
              ),
              _summary(
                lt('Платёж в день', 'Daily payment', 'Платіж на день'),
                usd(cents(total / days)),
              ),
              _LumaConsent(
                contentPadding: EdgeInsets.zero,
                value: creditConsent,
                onChanged: (v) => setState(() => creditConsent = v!),
                title: Text(
                  lt(
                    'Принимаю условия кредита',
                    'I accept the loan terms',
                    'Приймаю умови кредиту',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              primary(
                lt('Оформить кредит', 'Take a loan', 'Оформити кредит'),
                creditConsent && g.loan == 0
                    ? () => _confirm(
                      lt('Оформить кредит', 'Take a loan', 'Оформити кредит'),
                      '${usd(credit)} ${usd(total)} · $days ${lt('дней', 'days', 'днів')}',
                      () => g.borrowLuma(credit, days),
                    )
                    : null,
              ),
              primary(
                lt(
                  'Посмотреть график платежей',
                  'View payment schedule',
                  'Переглянути графік платежів',
                ),
                () => go('schedule'),
                outline: true,
              ),
            ],
          ),
        ),
        _timeNote(),
      ],
    );
  }

  Widget _summary(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: muted(label)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  Widget _schedule() {
    final active = g.loan > 0 && g.luma.creditDays > 0;
    final count = active ? g.luma.creditDays : days;
    final total =
        active ? g.loan : cents(credit + LumaBank.creditInterest(credit, days));
    final daily = active ? g.luma.creditDaily : cents(total / count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title(lt('График платежей', 'Payment schedule', 'Графік платежів')),
        if (g.loan > 0 && !active)
          box(
            Text(
              lt(
                'Прежний кредит без графика. Его можно погасить любой суммой во вкладке «Кредиты».',
                'Your legacy loan has no schedule. Repay any amount from Loans.',
                'Попередній кредит без графіка. Погашай будь-яку суму у вкладці «Кредити».',
              ),
            ),
          )
        else
          box(
            Column(
              children: [
                for (var i = 0; i < count; i++)
                  _summary(
                    '${lt('День', 'Day', 'День')} ${(active ? g.luma.creditDueDay : g.luma.day + 1) + i}',
                    usd(
                      i == count - 1
                          ? cents(max(0, total - daily * (count - 1)))
                          : daily,
                    ),
                  ),
              ],
            ),
          ),
        _timeNote(),
      ],
    );
  }

  Widget _timeNote() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: muted(
      lt(
        'День ${g.luma.day} · 1 игровой день = 10 минут активной игры. Вне игры время не идёт. Проценты по кредиту фиксированы; при нехватке денег платёж остаётся просроченным.',
        'Day ${g.luma.day} · 1 game day = 10 minutes of active play. Time pauses outside the game. Loan interest is fixed; unpaid instalments remain overdue.',
        'День ${g.luma.day} · 1 ігровий день = 10 хвилин активної гри. Поза грою час не йде. Відсотки фіксовані; несплачені платежі залишаються простроченими.',
      ),
    ),
  );
  Widget _business() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(lt('Бизнес-счёт', 'Business account', 'Бізнес-рахунок')),
      box(
        row(
          Icons.work_outline,
          lt('Мой сервис', 'My workshop', 'Мій сервіс'),
          null,
          sub:
              g.luma.businessOpened
                  ? lt('Счёт активен', 'Account active', 'Рахунок активний')
                  : lt(
                    'Отдельный счёт для сервиса',
                    'A separate account for your workshop',
                    'Окремий рахунок для сервісу',
                  ),
        ),
      ),
      if (!g.luma.businessOpened)
        primary(
          lt(
            'Открыть бизнес-счёт бесплатно',
            'Open a free business account',
            'Відкрити бізнес-рахунок безкоштовно',
          ),
          g.openLumaBusiness,
        )
      else ...[
        card(business: true),
        balance(
          g.luma.business,
          label: lt(
            'Доступно бизнесу',
            'Available to business',
            'Доступно бізнесу',
          ),
        ),
        actions([
          (
            Icons.add,
            lt('Пополнить', 'Add money', 'Поповнити'),
            () => _amount(
              lt(
                'С личного счёта',
                'From personal account',
                'З особистого рахунку',
              ),
              (a) => g.moveLumaBusiness(a),
            ),
          ),
          (
            Icons.arrow_forward,
            lt('Перевести', 'Transfer', 'Переказати'),
            () => _transfer(business: true),
          ),
          (
            Icons.swap_horiz,
            lt('На личный', 'To personal', 'На особистий'),
            () => _amount(
              lt(
                'На личный счёт',
                'To personal account',
                'На особистий рахунок',
              ),
              (a) => g.moveLumaBusiness(a, withdraw: true),
            ),
          ),
        ]),
        box(
          row(
            Icons.receipt_long_outlined,
            lt('Реквизиты', 'Account details', 'Реквізити'),
            () => _showDetails(business: true),
          ),
        ),
        section(
          lt(
            'За последние 7 дней',
            'Over the last 7 days',
            'За останні 7 днів',
          ),
        ),
        _two(
          box(
            _summary(
              lt('Поступления', 'Money in', 'Надходження'),
              usd(_businessTotal(true)),
            ),
          ),
          box(
            _summary(
              lt('Расходы', 'Expenses', 'Витрати'),
              usd(_businessTotal(false)),
            ),
          ),
        ),
        section(
          lt('Операции бизнеса', 'Business transactions', 'Операції бізнесу'),
        ),
        _transactions(g.luma.businessTxns),
        box(
          row(
            Icons.info_outline,
            lt(
              'Средства сервиса отдельно',
              'Workshop funds are separate',
              'Кошти сервісу окремо',
            ),
            null,
            sub: lt(
              'Переведи деньги с личного счёта, затем плати поставщикам и сотрудникам.',
              'Move money from your personal account to pay suppliers and staff.',
              'Переказуй кошти з особистого рахунку для оплати постачальникам і працівникам.',
            ),
          ),
        ),
      ],
    ],
  );
  double _businessTotal(bool income) => g.luma.businessTxns
      .where(
        (t) =>
            t.time.isAfter(DateTime.now().subtract(const Duration(days: 7))) &&
            (income ? t.amount > 0 : t.amount < 0),
      )
      .fold(0.0, (s, t) => s + t.amount.abs());
  Widget _manage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(lt('Карта Luma', 'Luma card', 'Картка Luma')),
      card(),
      const SizedBox(height: 16),
      Center(
        child: Text(
          g.luma.frozen
              ? lt('Карта заморожена', 'Card frozen', 'Картку заморожено')
              : lt('Карта активна', 'Card active', 'Картка активна'),
          style: TextStyle(
            color: g.luma.frozen ? lumaPurple : const Color(0xFF0EB58B),
          ),
        ),
      ),
      balance(g.balance),
      _two(
        primary(
          lt('Реквизиты', 'Details', 'Реквізити'),
          () => go('details'),
          outline: true,
        ),
        primary(lt('Изменить дизайн', 'Change design', 'Змінити дизайн'), () {
          selected = g.luma.style;
          go('design');
        }, outline: true),
      ),
      box(
        Column(
          children: [
            row(
              Icons.ac_unit,
              lt('Заморозить карту', 'Freeze card', 'Заморозити картку'),
              null,
              trailing: Switch(
                value: g.luma.frozen,
                onChanged: (v) => g.updateLumaSettings(frozen: v),
              ),
            ),
            const Divider(height: 1),
            row(
              Icons.shopping_bag_outlined,
              lt(
                'Покупки в интернете',
                'Online purchases',
                'Покупки в інтернеті',
              ),
              null,
              trailing: Switch(
                value: g.luma.online,
                onChanged: (v) => g.updateLumaSettings(online: v),
              ),
            ),
            const Divider(height: 1),
            row(
              Icons.tune,
              lt('Лимиты', 'Limits', 'Ліміти'),
              _limit,
              sub:
                  '${usd(g.luma.dailyLimit)} / ${lt('день', 'day', 'день')} · ${lt('использовано', 'used', 'використано')} ${usd(g.luma.spentToday)}',
            ),
            const Divider(height: 1),
            row(
              Icons.verified_user_outlined,
              lt('Изменить PIN-код', 'Change PIN', 'Змінити PIN-код'),
              _pin,
            ),
            const Divider(height: 1),
            row(
              Icons.receipt_long_outlined,
              lt('Выписка', 'Statement', 'Виписка'),
              () => go('history'),
            ),
          ],
        ),
      ),
      box(
        row(
          Icons.info_outline,
          lt('Обслуживание карты', 'Card maintenance', 'Обслуговування картки'),
          null,
          trailing: Text(
            usd(0),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      primary(
        lt('Закрыть карту', 'Close card', 'Закрити картку'),
        () => _confirm(
          lt('Закрыть карту?', 'Close card?', 'Закрити картку?'),
          lt(
            'Баланс сохранится. Сначала погаси кредит, закрой вклады и переведи накопления и бизнес-средства на личный счёт.',
            'Your balance is preserved. First repay loans, let deposits mature and withdraw savings and business funds.',
            'Баланс збережеться. Спочатку погаси кредит, дочекайся завершення вкладів та виведи заощадження й бізнес-кошти.',
          ),
          () {
            final ok = g.closeLumaCard();
            if (ok) {
              setState(() {
                page = '';
                consent = false;
              });
            }
            return ok;
          },
        ),
        outline: true,
      ),
    ],
  );
  Widget _designs() {
    final style = lumaStyles.firstWhere((s) => s.id == selected);
    final owned = g.luma.ownedStyles.contains(style.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title(lt('Дизайн карты', 'Card design', 'Дизайн картки')),
        card(design: selected),
        const SizedBox(height: 15),
        _summary(
          style.name,
          owned ? lt('Доступно', 'Owned', 'Доступно') : usd(style.price),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < 3; i++)
              ChoiceChip(
                label: Text(
                  [
                    lt('Все', 'All', 'Усі'),
                    lt('Бесплатные', 'Free', 'Безкоштовні'),
                    lt('Платные', 'Paid', 'Платні'),
                  ][i],
                ),
                selected: filter == i,
                onSelected: (_) => setState(() => filter = i),
              ),
          ],
        ),
        const SizedBox(height: 15),
        _styleChoices(),
        box(
          _summary(
            lt('Баланс карты', 'Card balance', 'Баланс картки'),
            hide ? '••••' : usd(g.balance),
          ),
        ),
        primary(
          g.luma.style == selected
              ? lt('Текущий дизайн', 'Current design', 'Поточний дизайн')
              : owned
              ? lt('Применить дизайн', 'Apply design', 'Застосувати дизайн')
              : lt(
                'Купить за ${usd(style.price)}',
                'Buy for ${usd(style.price)}',
                'Купити за ${usd(style.price)}',
              ),
          g.luma.style == selected
              ? null
              : () => _confirm(
                style.name,
                owned
                    ? lt(
                      'Применить дизайн?',
                      'Apply this design?',
                      'Застосувати дизайн?',
                    )
                    : lt(
                      'Разовая оплата ${usd(style.price)}',
                      'One-time payment ${usd(style.price)}',
                      'Одноразова оплата ${usd(style.price)}',
                    ),
                () => g.buyLumaStyle(selected),
              ),
        ),
        muted(
          lt(
            'Дизайн не меняет условия карты. Купленный дизайн остаётся доступным.',
            'Design does not change card terms. Purchased designs remain available.',
            'Дизайн не змінює умови картки. Придбані дизайни залишаються доступними.',
          ),
        ),
      ],
    );
  }

  Widget _styleChoices({bool freeOnly = false}) {
    final list =
        lumaStyles
            .where(
              (s) =>
                  freeOnly
                      ? s.price == 0
                      : filter == 1
                      ? s.price == 0
                      : filter == 2
                      ? s.price > 0
                      : true,
            )
            .toList();
    return LayoutBuilder(
      builder:
          (context, c) => Wrap(
            spacing: 12,
            runSpacing: 14,
            children: [
              for (final s in list)
                SizedBox(
                  width: (c.maxWidth - 12) / 2,
                  child: GestureDetector(
                    key: ValueKey('luma_style_${s.id}'),
                    onTap: () => setState(() => selected = s.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color:
                                  selected == s.id
                                      ? lumaPurple
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: LumaCard(
                            design: s.id,
                            mini: true,
                            demo: freeOnly,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        muted(
                          s.price == 0
                              ? lt('Бесплатно', 'Free', 'Безкоштовно')
                              : g.luma.ownedStyles.contains(s.id)
                              ? lt('Куплено', 'Owned', 'Придбано')
                              : usd(s.price),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(lt('Реквизиты карты', 'Card details', 'Реквізити картки')),
      box(
        Column(
          children: [
            _summary(
              lt('Владелец', 'Holder', 'Власник'),
              g.playerName.isEmpty ? 'TECHLIFE MASTER' : g.playerName,
            ),
            _summary(lt('Карта', 'Card', 'Картка'), '•••• 2048'),
            _summary(lt('Срок действия', 'Expires', 'Строк дії'), '12/30'),
            _summary(lt('Валюта', 'Currency', 'Валюта'), 'USD'),
            _summary(lt('Счёт', 'Account', 'Рахунок'), 'LUMA-PERSONAL-2048'),
          ],
        ),
      ),
      primary(
        lt('Скопировать реквизиты', 'Copy details', 'Скопіювати реквізити'),
        () {
          Clipboard.setData(
            const ClipboardData(text: 'Luma · LUMA-PERSONAL-2048 · USD'),
          );
          tell(lt('Скопировано', 'Copied', 'Скопійовано'));
        },
      ),
      muted(
        lt(
          'Реквизиты действуют внутри TechLife.',
          'These details work inside TechLife.',
          'Реквізити діють усередині TechLife.',
        ),
      ),
    ],
  );
  Widget _notifications() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(lt('Уведомления Luma', 'Luma notifications', 'Сповіщення Luma')),
      for (final n in g.notifications.where((n) => n.type == 'bank'))
        box(Text(n.body)),
      if (!g.notifications.any((n) => n.type == 'bank'))
        box(
          row(
            Icons.notifications_none,
            lt(
              'Пока нет уведомлений',
              'No notifications yet',
              'Поки немає сповіщень',
            ),
            null,
          ),
        ),
    ],
  );
  Widget _profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title(lt('Профиль', 'Profile', 'Профіль')),
      box(
        row(
          Icons.person_outline,
          g.playerName.isEmpty
              ? lt('Мастер', 'Master', 'Майстер')
              : g.playerName,
          null,
          sub: 'Luma · TechLife',
        ),
      ),
      box(
        row(
          Icons.verified_user_outlined,
          lt('Кредитная история', 'Credit history', 'Кредитна історія'),
          null,
          sub:
              '${lt('Пропущено платежей', 'Missed payments', 'Пропущено платежів')}: ${g.luma.missedPayments}',
        ),
      ),
      _timeNote(),
    ],
  );
  Future<T?> _showDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) => showDialog<T>(
    context: context,
    builder: (c) => Theme(data: _bankTheme(), child: builder(c)),
  );
  Future<T?> _showModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool showDragHandle = false,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: showDragHandle,
    backgroundColor: const Color(0xFFF8F6FD),
    builder:
        (c) => Theme(
          data: _bankTheme(),
          child: DefaultTextStyle(
            style: _bankTheme().textTheme.bodyMedium!,
            child: builder(c),
          ),
        ),
  );
  Future<void> _confirm(
    String title,
    String body,
    bool Function() action, {
    bool requirePin = false,
  }) async {
    final ok = await _showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(lt('Отмена', 'Cancel', 'Скасувати')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(lt('Подтвердить', 'Confirm', 'Підтвердити')),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    if (requirePin && g.luma.pinHash.isNotEmpty) {
      final pin = TextEditingController();
      final entered = await _showDialog<String>(
        context: context,
        builder:
            (c) => AlertDialog(
              title: Text(lt('Введи PIN-код', 'Enter PIN', 'Введи PIN-код')),
              content: TextField(
                controller: pin,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(lt('Отмена', 'Cancel', 'Скасувати')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, pin.text),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      if (!mounted || entered == null) return;
      if (!g.verifyLumaPin(entered)) {
        tell(lt('Неверный PIN-код', 'Incorrect PIN', 'Неправильний PIN-код'));
        return;
      }
    }
    if (mounted) done(action());
  }

  Future<void> _amount(String title, bool Function(double) action) async {
    final input = TextEditingController();
    final value = await _showDialog<double>(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, update) => AlertDialog(
                  title: Text(title),
                  content: TextField(
                    autofocus: true,
                    controller: input,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => update(() {}),
                    decoration: InputDecoration(
                      labelText: lt('Сумма, USD', 'Amount, USD', 'Сума, USD'),
                      prefixText: '\$ ',
                      helperText: lt(
                        'До 2 знаков после запятой',
                        'Up to 2 decimal places',
                        'До 2 знаків після коми',
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(lt('Отмена', 'Cancel', 'Скасувати')),
                    ),
                    FilledButton(
                      onPressed:
                          _parseAmount(input.text) == null
                              ? null
                              : () =>
                                  Navigator.pop(c, _parseAmount(input.text)),
                      child: Text(lt('Продолжить', 'Continue', 'Продовжити')),
                    ),
                  ],
                ),
          ),
    );
    // Controllers live until the dialog route finishes its closing animation.
    if (value != null && mounted) {
      await _confirm(title, usd(value), () => action(value));
    }
  }

  double? _parseAmount(String s) {
    s = s.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(s)) return null;
    final n = double.tryParse(s);
    return n != null && n.isFinite && n > 0 ? n : null;
  }

  Future<void> _transfer({
    String recipient = '',
    bool business = false,
    bool cardNumber = false,
    bool template = false,
  }) async {
    final name = TextEditingController(text: recipient),
        amount = TextEditingController();
    final result = await _showDialog<(String, double)>(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder: (c, update) {
              final n = name.text.trim(), a = _parseAmount(amount.text);
              final valid =
                  (cardNumber
                      ? RegExp(r'^\d{16}$').hasMatch(n.replaceAll(' ', ''))
                      : n.isNotEmpty && n.length <= 80) &&
                  a != null;
              return AlertDialog(
                title: Text(
                  template
                      ? lt(
                        'Создать шаблон',
                        'Create template',
                        'Створити шаблон',
                      )
                      : lt('Перевести', 'Transfer', 'Переказати'),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        keyboardType:
                            cardNumber
                                ? TextInputType.number
                                : TextInputType.text,
                        maxLength: cardNumber ? 19 : 80,
                        onChanged: (_) => update(() {}),
                        decoration: InputDecoration(
                          labelText:
                              cardNumber
                                  ? lt(
                                    'Номер карты · 16 цифр',
                                    'Card number · 16 digits',
                                    'Номер картки · 16 цифр',
                                  )
                                  : lt('Получатель', 'Recipient', 'Одержувач'),
                        ),
                      ),
                      TextField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => update(() {}),
                        decoration: InputDecoration(
                          labelText: lt(
                            'Сумма, USD',
                            'Amount, USD',
                            'Сума, USD',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      muted(
                        lt(
                          'Перевод спишет деньги. Отменить его нельзя.',
                          'This transfer will debit funds and cannot be reversed.',
                          'Переказ спише кошти. Скасувати його неможливо.',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(lt('Отмена', 'Cancel', 'Скасувати')),
                  ),
                  FilledButton(
                    onPressed: valid ? () => Navigator.pop(c, (n, a)) : null,
                    child: Text(lt('Продолжить', 'Continue', 'Продовжити')),
                  ),
                ],
              );
            },
          ),
    );
    if (result != null && mounted) {
      await _confirm(
        result.$1,
        usd(result.$2),
        () =>
            template
                ? g.saveLumaTemplate(result.$1, result.$2)
                : g.transferLuma(result.$1, result.$2, fromBusiness: business),
        requirePin: !template,
      );
    }
  }

  Future<void> _newGoal() async {
    final name = TextEditingController(), amount = TextEditingController();
    final result = await _showDialog<(String, double)>(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, update) => AlertDialog(
                  title: Text(lt('Новая цель', 'New goal', 'Нова ціль')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        maxLength: 60,
                        onChanged: (_) => update(() {}),
                        decoration: InputDecoration(
                          labelText: lt('Название', 'Name', 'Назва'),
                        ),
                      ),
                      TextField(
                        controller: amount,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => update(() {}),
                        decoration: InputDecoration(
                          labelText: lt(
                            'Цель, USD',
                            'Target, USD',
                            'Ціль, USD',
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(lt('Отмена', 'Cancel', 'Скасувати')),
                    ),
                    FilledButton(
                      onPressed:
                          name.text.trim().isNotEmpty &&
                                  _parseAmount(amount.text) != null
                              ? () => Navigator.pop(c, (
                                name.text,
                                _parseAmount(amount.text)!,
                              ))
                              : null,
                      child: Text(lt('Создать', 'Create', 'Створити')),
                    ),
                  ],
                ),
          ),
    );
    if (result != null && mounted) done(g.createLumaGoal(result.$1, result.$2));
  }

  void _topUp() {
    _showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (c) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lt('Пополнить карту', 'Add money', 'Поповнити картку'),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  lt(
                    'Деньги поступают от продажи техники и выполнения ремонтов. Можно также перевести средства с бизнес-счёта или снять накопления.',
                    'Earn money by selling devices and completing repairs. You can also withdraw savings or transfer business funds.',
                    'Гроші надходять від продажу техніки й виконання ремонтів. Також можна зняти заощадження або переказати бізнес-кошти.',
                  ),
                ),
                primary(
                  lt('Из накоплений', 'From savings', 'Із заощаджень'),
                  () {
                    Navigator.pop(c);
                    setState(() => tab = 2);
                  },
                ),
                primary(
                  lt(
                    'С бизнес-счёта',
                    'From business account',
                    'Із бізнес-рахунку',
                  ),
                  () {
                    Navigator.pop(c);
                    _amount(
                      lt(
                        'На личный счёт',
                        'To personal account',
                        'На особистий рахунок',
                      ),
                      (a) => g.moveLumaBusiness(a, withdraw: true),
                    );
                  },
                  outline: true,
                ),
              ],
            ),
          ),
    );
  }

  void _betweenAccounts() {
    _showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (c) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                primary(
                  lt('Личный Бизнес', 'Personal Business', 'Особистий Бізнес'),
                  () {
                    Navigator.pop(c);
                    _amount('Luma Business', (a) => g.moveLumaBusiness(a));
                  },
                ),
                primary(
                  lt('Бизнес Личный', 'Business Personal', 'Бізнес Особистий'),
                  () {
                    Navigator.pop(c);
                    _amount(
                      'Luma',
                      (a) => g.moveLumaBusiness(a, withdraw: true),
                    );
                  },
                  outline: true,
                ),
              ],
            ),
          ),
    );
  }

  void _showDetails({bool business = false}) {
    _showDialog<void>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(lt('Реквизиты', 'Account details', 'Реквізити')),
            content: const SelectableText(
              'Luma Business\nTECHLIFE SERVICE\nLUMA-BUSINESS-6082\nUSD',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _limit() => _amount(
    lt(
      'Лимит в день · \$ 1–100 000',
      'Daily limit · \$ 1–100,000',
      'Ліміт на день · \$ 1–100 000',
    ),
    (a) {
      if (a < 1 || a > 100000) return false;
      g.updateLumaSettings(limit: a);
      return true;
    },
  );
  Future<void> _pin() async {
    final pin = TextEditingController();
    final result = await _showDialog<String>(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, update) => AlertDialog(
                  title: Text(lt('Новый PIN-код', 'New PIN', 'Новий PIN-код')),
                  content: TextField(
                    controller: pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => update(() {}),
                    decoration: InputDecoration(
                      helperText: lt(
                        '4 цифры. Не используй настоящий банковский PIN.',
                        '4 digits. Do not use a real bank PIN.',
                        '4 цифри. Не використовуй справжній банківський PIN.',
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(lt('Отмена', 'Cancel', 'Скасувати')),
                    ),
                    FilledButton(
                      onPressed:
                          pin.text.length == 4
                              ? () => Navigator.pop(c, pin.text)
                              : null,
                      child: Text(lt('Сохранить', 'Save', 'Зберегти')),
                    ),
                  ],
                ),
          ),
    );
    if (result != null && mounted) {
      g.updateLumaSettings(pin: result);
      tell(lt('PIN изменён', 'PIN updated', 'PIN змінено'));
    }
  }

  void _payTax() => _confirm(
    lt('Оплатить налоги', 'Pay taxes', 'Сплатити податки'),
    usd(g.taxDue),
    () {
      if (g.taxDue <= 0 || g.balance < g.taxDue) return false;
      g.payTaxes();
      return true;
    },
  );
  void _insure() => _confirm(
    lt('Оформить страховку', 'Buy insurance', 'Оформити страхування'),
    usd(200),
    g.buyInsurance,
  );
}

class _LumaConsent extends StatelessWidget {
  final EdgeInsetsGeometry? contentPadding;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget? title;
  const _LumaConsent({
    this.contentPadding,
    this.value,
    this.onChanged,
    this.title,
  });
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: CheckboxListTile(
      contentPadding: contentPadding,
      value: value,
      onChanged: onChanged,
      title: title,
    ),
  );
}
