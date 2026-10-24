import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/admin_auth.dart';
import '../../core/ai_service.dart';
import '../../core/app_info.dart';
import '../../core/app_log.dart';
import '../../core/catalog.dart';
import '../../core/game_state.dart';
import '../../core/theme.dart';
import '../widgets.dart';

/// Admin screens are intentionally Russian-only (developer tools).

// ====================================================================== login
class AdminLogin extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onDone;
  const AdminLogin({super.key, required this.onBack, required this.onDone});
  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final ctrl = TextEditingController();
  bool hide = true;
  String? error;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && AdminAuth.lockSeconds >= 0) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (AdminAuth.lockSeconds > 0) return;
    if (AdminAuth.login(ctrl.text)) {
      ctrl.clear();
      widget.onDone();
    } else {
      setState(
        () =>
            error =
                AdminAuth.lockSeconds > 0
                    ? 'Слишком много попыток. Подождите.'
                    : 'Неверный пароль',
      );
      ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = AdminAuth.lockSeconds;
    return AppPage(
      title: 'Админ-панель',
      onBack: widget.onBack,
      child: ListView(
        children: [
          const SizedBox(height: 24),
          const Center(
            child: Icon(Icons.admin_panel_settings, size: 64, color: C.accent),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Доступ только по паролю',
              style: TextStyle(color: IosColors.of(context).secondary),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: ctrl,
            obscureText: hide,
            enableSuggestions: false,
            autocorrect: false,
            enabled: lock == 0,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Пароль',
              filled: true,
              fillColor: IosColors.of(context).surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(hide ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => hide = !hide),
              ),
            ),
          ),
          if (error != null || lock > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                lock > 0 ? 'Вход заблокирован на $lock с' : error!,
                style: const TextStyle(color: C.red),
              ),
            ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: lock > 0 ? null : _submit,
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}

// ====================================================================== panel
class AdminPanel extends StatefulWidget {
  final VoidCallback onBack;
  const AdminPanel({super.key, required this.onBack});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int tab = 0;
  String logFilter = 'all';
  final balanceCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  final ckeyCtrl = TextEditingController();
  final cmodelCtrl = TextEditingController();
  bool testing = false;
  String? testResult;
  bool testOk = false;

  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    modelCtrl.text = gs.aiModel;
    urlCtrl.text = gs.aiCustomUrl;
    ckeyCtrl.text = gs.aiCustomKey;
    cmodelCtrl.text = gs.aiCustomModel;
  }

  @override
  void dispose() {
    balanceCtrl.dispose();
    modelCtrl.dispose();
    urlCtrl.dispose();
    ckeyCtrl.dispose();
    cmodelCtrl.dispose();
    super.dispose();
  }

  Widget _btn(String label, VoidCallback? onTap, {Color? color}) =>
      FilledButton.tonal(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: color,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  Widget _field(TextEditingController c, String hint, {bool obscure = false}) =>
      TextField(
        controller: c,
        obscureText: obscure,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: IosColors.of(context).inset,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );

  Widget _kv(String k, String v, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            k,
            style: TextStyle(
              color: IosColors.of(context).secondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Text(v, style: TextStyle(fontSize: 12, color: color))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Админ-панель',
      onBack: widget.onBack,
      actions: [
        TextButton(
          onPressed: () {
            AdminAuth.logout();
            widget.onBack();
          },
          child: const Text('Выйти', style: TextStyle(color: C.red)),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Логи')),
                ButtonSegment(value: 1, label: Text('Игра')),
                ButtonSegment(value: 2, label: Text('ИИ')),
              ],
              selected: {tab},
              onSelectionChanged: (s) => setState(() => tab = s.first),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: tab == 0 ? _logs() : (tab == 1 ? _tools() : _ai())),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ logs
  Widget _logs() {
    return ListenableBuilder(
      listenable: AppLog.I,
      builder: (context, _) {
        final all = AppLog.I.entries;
        final list =
            all.where((e) {
              switch (logFilter) {
                case 'error':
                  return e.level == 'error' || e.level == 'warn';
                case 'all':
                  return true;
                default:
                  return e.source == logFilter;
              }
            }).toList();
        return Column(
          children: [
            ChipRow(
              ids: const ['all', 'error', 'ai', 'game', 'net', 'map', 'admin'],
              selected: logFilter,
              label:
                  (id) =>
                      {
                        'all': 'Все',
                        'error': 'Ошибки',
                        'ai': 'ИИ',
                        'game': 'Игра',
                        'net': 'Сеть',
                        'map': 'Карта',
                        'admin': 'Админ',
                      }[id]!,
              onSelect: (id) => setState(() => logFilter = id),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${list.length} из ${all.length}',
                  style: TextStyle(
                    color: IosColors.of(context).secondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Копировать'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: AppLog.I.dump()),
                    );
                    if (context.mounted) toast(context, 'Лог скопирован');
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Очистить'),
                  onPressed: AppLog.I.clear,
                ),
              ],
            ),
            Expanded(
              child:
                  list.isEmpty
                      ? const Empty('Записей нет')
                      : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder:
                            (_, __) =>
                                const Divider(height: 1, color: Colors.white12),
                        itemBuilder: (_, i) {
                          final e = list[i];
                          final color =
                              e.level == 'error'
                                  ? C.red
                                  : (e.level == 'warn'
                                      ? C.orange
                                      : IosColors.of(context).secondary);
                          final t = e.time;
                          String two(int v) => v.toString().padLeft(2, '0');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: SelectableText.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 12),
                                children: [
                                  TextSpan(
                                    text:
                                        '${two(t.hour)}:${two(t.minute)}:${two(t.second)} ',
                                    style: TextStyle(
                                      color: IosColors.of(context).secondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '[${e.source}] ',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: e.message),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------------- tools
  Widget _tools() {
    final gs = context.watch<GameState>();
    final g = context.read<GameState>();
    return ListView(
      children: [
        _section('Деньги и репутация', [
          Text(
            'Баланс: ${money(gs.balance)}   Репутация: ${gs.reputation.toStringAsFixed(2)}',
            style: TextStyle(
              color: IosColors.of(context).secondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _btn('+\$1 000', () => g.adminAddMoney(1000)),
              _btn('+\$10 000', () => g.adminAddMoney(10000)),
              _btn('+\$100 000', () => g.adminAddMoney(100000)),
              _btn('-\$500', () => g.adminAddMoney(-500), color: C.red),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Установить баланс',
                    isDense: true,
                    filled: true,
                    fillColor: IosColors.of(context).inset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _btn('OK', () {
                final v = double.tryParse(
                  balanceCtrl.text.replaceAll(',', '.'),
                );
                if (v == null) {
                  toast(context, 'Введите число');
                  return;
                }
                g.adminSetBalance(v);
                balanceCtrl.clear();
              }),
            ],
          ),
          Slider(
            value: gs.reputation.clamp(1.0, 5.0).toDouble(),
            min: 1,
            max: 5,
            divisions: 40,
            label: gs.reputation.toStringAsFixed(1),
            onChanged: g.adminSetReputation,
          ),
        ]),
        _section('Мир', [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _btn('+3 заказа', () => g.adminSpawnOrders(3)),
              _btn('Новая сделка', g.adminSpawnDeal),
              _btn('Шаг экономики', g.adminTick),
              _btn('Запчасти +3', () => g.adminGiveParts(3)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Телепорт в город (бесплатно)',
            style: TextStyle(
              color: IosColors.of(context).secondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < cities.length; i++)
                ChoiceChip(
                  label: Text(cities[i].name(gs.lang)),
                  selected: gs.cityIndex == i,
                  onSelected: (_) => g.flyTo(i, free: true),
                ),
            ],
          ),
        ]),
        _section('Прогресс', [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _btn('Пройти все курсы', g.adminUnlockCourses),
              _btn('Обнулить долги и налоги', g.adminClearDebts),
            ],
          ),
        ]),
        _section('Сохранение', [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _btn('Копировать JSON', () async {
                await Clipboard.setData(ClipboardData(text: g.exportSave()));
                if (mounted) toast(context, 'Сохранение скопировано');
              }),
              _btn('Импорт из буфера', () async {
                final d = await Clipboard.getData(Clipboard.kTextPlain);
                final ok = d?.text != null && g.importSave(d!.text!);
                if (mounted) {
                  toast(
                    context,
                    ok ? 'Импортировано' : 'Не удалось (см. логи)',
                  );
                }
              }),
            ],
          ),
        ]),
        _section('О приложении', [
          _kv('Версия', '$kAppName $kAppVersion'),
          _kv('Язык', gs.lang),
          _kv('Тема', ['системная', 'светлая', 'тёмная'][gs.themeMode]),
        ]),
      ],
    );
  }

  // -------------------------------------------------------------------- ai
  Widget _ai() {
    final gs = context.watch<GameState>();
    final g = context.read<GameState>();
    final key = gs.aiKey;
    final source =
        gs.geminiKey.isNotEmpty
            ? 'введён в настройках'
            : (gs.hasBuiltInKey ? 'встроен при сборке' : 'нет');
    return ListView(
      children: [
        _section('Состояние', [
          _kv('Ключ', source, color: key.isEmpty ? C.red : null),
          _kv('Тип ключа', AiService.keyKind(key)),
          _kv('Длина ключа', key.isEmpty ? '—' : '${key.length} символов'),
          _kv('Модель', AiService.modelFor(key)),
          _kv(
            'Сеть',
            gs.online
                ? 'онлайн'
                : (gs.forceOffline ? 'имитация офлайна (админ)' : 'нет сети'),
            color: gs.online ? IosColors.of(context).green : C.red,
          ),
          _kv('Последний ответ', gs.lastAiMs == 0 ? '—' : '${gs.lastAiMs} мс'),
          _kv(
            'Последняя ошибка',
            gs.lastAiError ?? 'нет',
            color: gs.lastAiError == null ? null : C.red,
          ),
        ]),
        _section('Проверка', [
          Row(
            children: [
              FilledButton.icon(
                onPressed:
                    testing
                        ? null
                        : () async {
                          setState(() {
                            testing = true;
                            testResult = null;
                          });
                          final r = await g.adminTestAi();
                          if (!mounted) return;
                          setState(() {
                            testing = false;
                            testOk = r.ok;
                            testResult =
                                r.ok
                                    ? 'OK, ${r.ms} мс:\n${r.text}'
                                    : 'ОШИБКА:\n${r.error}';
                          });
                        },
                icon:
                    testing
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.network_check),
                label: Text(testing ? 'Проверяю…' : 'Проверить ИИ'),
              ),
            ],
          ),
          if (testResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText(
                testResult!,
                style: TextStyle(
                  fontSize: 12,
                  color: testOk ? IosColors.of(context).green : C.red,
                ),
              ),
            ),
          if (!testOk && AiService.fixUrl != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Google пишет, что нужный API выключен в проекте ключа. Скопируйте ссылку, откройте её в браузере, нажмите «Включить» (Enable), подождите 2–5 минут и проверьте снова. Либо создайте ключ AIza… на aistudio.google.com/apikey — он работает без этого шага.',
              style: TextStyle(fontSize: 12, color: C.orange),
            ),
            const SizedBox(height: 6),
            SelectableText(
              AiService.fixUrl!,
              style: const TextStyle(fontSize: 11, color: C.accent),
            ),
            const SizedBox(height: 6),
            _btn('Скопировать ссылку', () {
              Clipboard.setData(ClipboardData(text: AiService.fixUrl!));
              toast(context, 'Скопировано');
            }),
          ],
        ]),
        _section('Свой ИИ-провайдер (OpenAI-совместимый)', [
          Text(
            'Если ключ Google не работает, подставьте любой бесплатный сервис, например Groq или OpenRouter. Пустой адрес = использовать Google. Ключ хранится только на этом устройстве.',
            style: TextStyle(
              fontSize: 12,
              color: IosColors.of(context).secondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final pr in aiPresets)
                ActionChip(
                  label: Text(pr.name, style: const TextStyle(fontSize: 11)),
                  onPressed:
                      () => setState(() {
                        urlCtrl.text = pr.url;
                        cmodelCtrl.text = pr.model;
                      }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _field(urlCtrl, 'Адрес API (…/v1)'),
          const SizedBox(height: 6),
          _field(ckeyCtrl, 'API-ключ', obscure: true),
          const SizedBox(height: 6),
          _field(cmodelCtrl, 'Модель'),
          const SizedBox(height: 8),
          Row(
            children: [
              _btn('Сохранить', () {
                g.setAiProvider(urlCtrl.text, ckeyCtrl.text, cmodelCtrl.text);
                toast(context, 'Сохранено');
              }),
              const SizedBox(width: 8),
              _btn('Вернуть Google', () {
                urlCtrl.clear();
                ckeyCtrl.clear();
                cmodelCtrl.clear();
                g.setAiProvider('', '', '');
                toast(context, 'Провайдер Google');
              }, color: C.red),
            ],
          ),
        ]),
        _section('Модель', [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: modelCtrl,
                  decoration: InputDecoration(
                    hintText: 'пусто = по умолчанию',
                    isDense: true,
                    filled: true,
                    fillColor: IosColors.of(context).inset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _btn('OK', () {
                g.setAiModel(modelCtrl.text);
                toast(context, 'Сохранено');
              }),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in [
                'gemini-2.5-flash',
                'gemini-2.5-flash-lite',
                'gemini-flash-latest',
                'gemini-2.0-flash',
              ])
                ActionChip(
                  label: Text(m, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    modelCtrl.text = m;
                    g.setAiModel(m);
                  },
                ),
            ],
          ),
        ]),
        _section('Сеть', [
          Row(
            children: [
              const Expanded(child: Text('Имитировать «нет интернета»')),
              Switch.adaptive(
                value: gs.forceOffline,
                onChanged: g.setForceOffline,
                activeTrackColor: IosColors.of(context).green,
              ),
            ],
          ),
        ]),
      ],
    );
  }
}
