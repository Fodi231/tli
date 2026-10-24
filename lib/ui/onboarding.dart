import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_info.dart';
import '../core/game_state.dart';
import '../core/market/market_strings.dart';
import '../core/theme.dart';
import 'ios_components.dart';
import 'liquid_surface.dart';
import 'shell.dart';
import 'widgets.dart';

String? profileNameError(String value) => switch (GameState.validatePlayerName(
  value,
)) {
  'short' => mt(
    'Введи имя: минимум 2 символа',
    'Enter a name with at least 2 characters',
    'Введи ім’я: щонайменше 2 символи',
  ),
  'long' => mt(
    'В имени должно быть не больше 24 символов',
    'Use no more than 24 characters',
    'В імені має бути не більше 24 символів',
  ),
  'characters' => mt(
    'Убери переносы строк и служебные символы',
    'Remove line breaks and control characters',
    'Прибери переноси рядків і службові символи',
  ),
  _ => null,
};

class GameOverview extends StatelessWidget {
  const GameOverview({super.key});
  @override
  Widget build(BuildContext context) {
    final p = IosColors.of(context);
    final features = [
      (
        Icons.chat_bubble_outline_rounded,
        const Color(0xFF3478F6),
        mt('Находи выгодное', 'Find a good deal', 'Знаходь вигідне'),
        mt(
          'Выбирай технику в ТехМаркете и торгуйся в переписке.',
          'Browse TechMarket and negotiate with sellers.',
          'Обирай техніку в ТехМаркеті й торгуйся в листуванні.',
        ),
      ),
      (
        Icons.build_outlined,
        const Color(0xFF9B62DF),
        mt('Ремонтируй сам', 'Repair it yourself', 'Ремонтуй сам'),
        mt(
          'Проверяй устройства, подбирай инструменты и меняй детали.',
          'Inspect devices, choose tools and replace components.',
          'Перевіряй пристрої, обирай інструменти й міняй деталі.',
        ),
      ),
      (
        Icons.trending_up_rounded,
        const Color(0xFF159B7A),
        mt('Развивай мастерскую', 'Grow your workshop', 'Розвивай майстерню'),
        mt(
          'Выполняй заказы, учись и продавай восстановленную технику.',
          'Complete orders, learn skills and sell repaired devices.',
          'Виконуй замовлення, навчайся й продавай відновлену техніку.',
        ),
      ),
      (
        Icons.account_balance_wallet_outlined,
        const Color(0xFF7950E9),
        mt('Управляй деньгами', 'Manage your money', 'Керуй грошима'),
        mt(
          'Следи за расходами, картой и накоплениями в Luma.',
          'Track expenses, your card and savings in Luma.',
          'Стеж за витратами, карткою й заощадженнями в Luma.',
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mt('Как устроена игра', 'Your life in TechLife', 'Як влаштована гра'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 12),
        LiquidSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < features.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: features[i].$2.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          features[i].$1,
                          color: features[i].$2,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              features[i].$3,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              features[i].$4,
                              style: TextStyle(
                                color: p.secondary,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < features.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    color: p.separator.withValues(alpha: .65),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          mt(
            'Прогресс сохраняется на этом устройстве. Резервную копию можно выгрузить в настройках ТехМаркета.',
            'Progress is saved on this device. Export a backup in TechMarket settings.',
            'Прогрес зберігається на цьому пристрої. Резервну копію можна експортувати в налаштуваннях ТехМаркету.',
          ),
          style: TextStyle(color: p.secondary, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  int _step = 0, _avatar = 0;
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _setStep(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = value);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _next() async {
    if (_step == 0) {
      _setStep(1);
      return;
    }
    if (!_form.currentState!.validate() || _saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    final gs = context.read<GameState>();
    final shell = context.read<Shell>();
    final ok = await gs.createCharacter(_name.text, _avatar);
    if (ok) {
      shell.close();
      shell.unlock();
      return;
    }
    if (mounted) {
      setState(() => _saving = false);
      toast(
        context,
        mt(
          'Не удалось сохранить персонажа. Попробуй ещё раз.',
          'Could not save your character. Please try again.',
          'Не вдалося зберегти персонажа. Спробуй ще раз.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final p = IosColors.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: IosBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        if (_step > 0)
                          IconButton(
                            key: const ValueKey('onboarding_back'),
                            onPressed: _saving ? null : () => _setStep(0),
                            tooltip: mt('Назад', 'Back', 'Назад'),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                        Text(
                          'TechLife',
                          style: TextStyle(
                            color: p.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          tooltip: mt('Язык', 'Language', 'Мова'),
                          initialValue: g.lang,
                          onSelected: g.setLang,
                          itemBuilder:
                              (_) => const [
                                PopupMenuItem(
                                  value: 'ru',
                                  child: Text('Русский'),
                                ),
                                PopupMenuItem(
                                  value: 'en',
                                  child: Text('English'),
                                ),
                                PopupMenuItem(
                                  value: 'uk',
                                  child: Text('Українська'),
                                ),
                              ],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  size: 18,
                                  color: p.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  g.lang.toUpperCase(),
                                  style: TextStyle(
                                    color: p.blue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: p.blue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('onboarding_scroll'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child:
                          _step == 0
                              ? _welcome(context)
                              : _registration(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: LiquidSurface(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 2; i++)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 5,
                                  ),
                                  width: i == _step ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        i == _step
                                            ? p.blue
                                            : p.secondary.withValues(
                                              alpha: .25,
                                            ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const ValueKey('onboarding_continue'),
                              onPressed: _saving ? null : _next,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 52),
                              ),
                              child:
                                  _saving
                                      ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _step == 0
                                                  ? mt(
                                                    'Продолжить',
                                                    'Continue',
                                                    'Продовжити',
                                                  )
                                                  : mt(
                                                    'Начать играть',
                                                    'Start playing',
                                                    'Почати грати',
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 19,
                                          ),
                                        ],
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
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    final p = IosColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: p.blue.withValues(alpha: .16),
                      blurRadius: 35,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 112,
                    height: 112,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                mt(
                  'Добро пожаловать\nв TechLife',
                  'Welcome to\nTechLife',
                  'Ласкаво просимо\nдо TechLife',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.08,
                  letterSpacing: -1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mt(
                  'Покупай. Ремонтируй. Продавай.',
                  'Buy. Repair. Resell.',
                  'Купуй. Ремонтуй. Продавай.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.secondary, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.blue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mt(
                    'СИМУЛЯТОР МАСТЕРСКОЙ',
                    'WORKSHOP SIMULATOR',
                    'СИМУЛЯТОР МАЙСТЕРНІ',
                  ),
                  style: TextStyle(
                    color: p.blue,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          mt(
            'Начни с небольшой суммы и преврати первую удачную покупку в своё дело. От состояния техники и твоих решений зависит прибыль.',
            'Start small and turn your first good deal into a business. Your profit depends on the device and the choices you make.',
            'Почни з невеликої суми й перетвори першу вдалу купівлю на власну справу. Прибуток залежить від стану техніки й твоїх рішень.',
          ),
          style: TextStyle(color: p.secondary, fontSize: 14, height: 1.55),
        ),
        const SizedBox(height: 25),
        const GameOverview(),
        const SizedBox(height: 15),
        Center(
          child: Text(
            'TechLife $kAppVersion',
            style: TextStyle(color: p.secondary, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _registration(BuildContext context) {
    final g = context.read<GameState>();
    final p = IosColors.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mt('Это твоя история', 'Make it your story', 'Це твоя історія'),
            style: const TextStyle(
              fontSize: 31,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            mt(
              'Создай персонажа и открой свою первую мастерскую.',
              'Create a character and start your first workshop.',
              'Створи персонажа й відкрий свою першу майстерню.',
            ),
            style: TextStyle(color: p.secondary, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 28),
          Center(
            child: ProfileAvatar(name: _name.text, index: _avatar, size: 96),
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < profileColors.length; i++)
                  Semantics(
                    key: ValueKey('onboarding_avatar_$i'),
                    label: mt(
                      'Цвет аватара ${i + 1}',
                      'Avatar colour ${i + 1}',
                      'Колір аватара ${i + 1}',
                    ),
                    selected: _avatar == i,
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() => _avatar = i),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: profileColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 3,
                            color: _avatar == i ? p.label : Colors.transparent,
                          ),
                        ),
                        child:
                            _avatar == i
                                ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                                : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            mt('Имя персонажа', 'Character name', 'Ім’я персонажа'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('character_name'),
            controller: _name,
            maxLength: 24,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F\x7F]')),
            ],
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _next(),
            validator: (value) => profileNameError(value ?? ''),
            decoration: InputDecoration(
              hintText: mt(
                'Как тебя зовут?',
                'What is your name?',
                'Як тебе звати?',
              ),
            ),
          ),
          const SizedBox(height: 16),
          LiquidSurface(
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: p.blue,
                  size: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mt(
                          'Стартовый капитал',
                          'Starting balance',
                          'Стартовий капітал',
                        ),
                        style: TextStyle(color: p.secondary, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        money(g.balance),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 17, color: p.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mt(
                    'Это локальный профиль. Почта и пароль не нужны. Имя и аватар можно изменить в настройках.',
                    'This is a local profile. No email or password needed. Change your name and avatar in Settings.',
                    'Це локальний профіль. Пошта й пароль не потрібні. Ім’я та аватар можна змінити в налаштуваннях.',
                  ),
                  style: TextStyle(
                    color: p.secondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
