import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/market/device_catalog.dart';
import '../../core/market/market_strings.dart';
import '../../core/repair/repair_session.dart';
import '../../core/repair/device_runtime.dart';

Future<void> showDeviceLab(
  BuildContext context,
  RepairSession session,
  VoidCallback onChanged,
) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: false,
  transitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (_, a, b) => DeviceLab(session: session, onChanged: onChanged),
  transitionBuilder:
      (_, a, b, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: .94,
            end: 1,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
);

class DeviceLab extends StatefulWidget {
  final RepairSession session;
  final VoidCallback onChanged;
  const DeviceLab({super.key, required this.session, required this.onChanged});
  @override
  State<DeviceLab> createState() => _DeviceLabState();
}

class _DeviceLabState extends State<DeviceLab> {
  late final Timer timer;
  late final TextEditingController notes;
  final GlobalKey _liveScreen = GlobalKey();
  ui.Image? _foldImage;
  DeviceRuntime get r => widget.session.runtime;
  DeviceSpec get spec => deviceFor(widget.session.device) ?? deviceCatalog[2];
  bool get apple => spec.apple;
  Color get accent =>
      apple
          ? const Color(0xFF0A84FF)
          : spec.brand == 'HUAWEI'
          ? const Color(0xFFED6B5E)
          : const Color(0xFF9CCBFF);
  bool get batteryConnected =>
      !widget.session.batteryDisconnected &&
      !(widget.session.service == 'battery' && widget.session.partRemoved);
  bool get displayConnected =>
      !(widget.session.service == 'display' && widget.session.partRemoved) &&
      !(widget.session.isOpen &&
          !widget.session.done('part_on') &&
          widget.session.done('part_off') &&
          !spec.id.startsWith('galaxy'));
  int overlayMs = 0;
  bool calling = false;
  Offset? touchStart;
  double slide = 0;
  @override
  void initState() {
    super.initState();
    r.resume(
      apple: apple,
      bootMs: spec.bootMs,
      batteryConnected: batteryConnected,
    );
    notes = TextEditingController(text: r.note);
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final before = r.power;
      final transitioned = r.advance(
        100,
        apple: apple,
        bootMs: spec.bootMs,
        batteryConnected: batteryConnected,
      );
      if (overlayMs > 0) overlayMs -= 100;
      if (transitioned || before != r.power) widget.onChanged();
      if (mounted &&
          (r.transitioning ||
              r.pressed.isNotEmpty ||
              overlayMs > 0 ||
              r.stopwatchRunning ||
              transitioned ||
              before != r.power)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    r.enterBackground();
    notes.dispose();
    _foldImage?.dispose();
    r.pressed.clear();
    super.dispose();
  }

  void change(VoidCallback action) {
    setState(action);
    widget.onChanged();
  }

  void open(DevicePage p) => change(() => r.open(p));
  void press(String id) {
    change(() => r.press(id));
    if (id != 'side') setState(() => overlayMs = 1400);
  }

  void release(String id) {
    change(() => r.release(id));
  }

  bool folding = false;
  void fold() {
    if (widget.session.isOpen || folding) return;
    folding = true;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) setState(() => folding = false);
    });
    final boundary = _liveScreen.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary && !boundary.debugNeedsPaint) {
      boundary.toImage(pixelRatio: .8).then((img) {
        if (!mounted) {
          img.dispose();
          return;
        }
        setState(() {
          _foldImage?.dispose();
          _foldImage = img;
        });
      });
    }
    change(() => r.setFold((r.foldStage + 1) % spec.panels, spec.panels));
  }

  String tr(String ru, String en, String uk) => mt(ru, en, uk);
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
      ),
      child: Material(
        color: const Color(0xFF0C131C),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('device_close'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spec.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${spec.system} · ${r.power == DevicePower.off
                                ? tr('Выключен', 'Powered off', 'Вимкнено')
                                : r.power == DevicePower.booting
                                ? tr('Загрузка', 'Starting', 'Завантаження')
                                : r.power == DevicePower.shuttingDown
                                ? tr('Выключение', 'Shutting down', 'Вимкнення')
                                : tr('Осмотр устройства', 'Device inspection', 'Огляд пристрою')}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (spec.panels > 1)
                      IconButton(
                        key: const ValueKey('fold_button'),
                        tooltip: tr(
                          'Раскрыть / сложить',
                          'Unfold / fold',
                          'Розкрити / скласти',
                        ),
                        onPressed: widget.session.isOpen ? null : fold,
                        icon: Icon(
                          r.foldStage == 0
                              ? Icons.unfold_more
                              : Icons.unfold_less,
                          color: accent,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder:
                      (context, c) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 2.4,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: r.foldStage.toDouble(),
                              ),
                              duration: const Duration(milliseconds: 850),
                              curve: Curves.easeInOutCubic,
                              builder: (context, stage, _) {
                                const height = 620.0;
                                final panel = height * spec.closedAspect;
                                final width = panel * (1 + stage);
                                return FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: width + 64,
                                    height: height + 8,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: 32,
                                          top: 0,
                                          width: width,
                                          height: height,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    apple ? 35 : 24,
                                                  ),
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFFD8DDE2),
                                                  Color(0xFF485260),
                                                  Color(0xFF9DA7AF),
                                                  Color(0xFF303C49),
                                                ],
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black87,
                                                  blurRadius: 28,
                                                  offset: Offset(0, 20),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(7),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    apple ? 29 : 19,
                                                  ),
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: RepaintBoundary(
                                                      key: _liveScreen,
                                                      child: _screen(),
                                                    ),
                                                  ),
                                                  if (stage > 0)
                                                    for (
                                                      var i = 1;
                                                      i < spec.panels;
                                                      i++
                                                    )
                                                      if (stage > i - 1)
                                                        Positioned(
                                                          left: panel * i - 7,
                                                          top: 0,
                                                          bottom: 0,
                                                          width: 14,
                                                          child: IgnorePointer(
                                                            child: DecoratedBox(
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    Colors
                                                                        .transparent,
                                                                    Colors.black.withValues(
                                                                      alpha:
                                                                          .2 +
                                                                          (1 -
                                                                                  (stage -
                                                                                          i +
                                                                                          1)
                                                                                      .clamp(0, 1)) *
                                                                              .35,
                                                                    ),
                                                                    Colors.white
                                                                        .withValues(
                                                                          alpha:
                                                                              .05,
                                                                        ),
                                                                    Colors
                                                                        .transparent,
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                  if (stage > 0 &&
                                                      (stage - stage.floor())
                                                              .abs() >
                                                          .01)
                                                    Positioned(
                                                      right: 0,
                                                      top: 0,
                                                      bottom: 0,
                                                      width:
                                                          panel *
                                                              (1 -
                                                                  (stage -
                                                                      stage
                                                                          .floor())) *
                                                              .45 +
                                                          1,
                                                      child: IgnorePointer(
                                                        child: DecoratedBox(
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                Colors
                                                                    .transparent,
                                                                Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          .46,
                                                                    ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (stage > .001 &&
                                                      (stage - stage.round())
                                                              .abs() >
                                                          .001)
                                                    Positioned.fill(
                                                      child: IgnorePointer(
                                                        child: CustomPaint(
                                                          painter: _FoldMotion(
                                                            stage,
                                                            panel,
                                                            spec.panels,
                                                            _foldImage,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 4,
                                          top: 110,
                                          child: _hardware('up', Icons.add, 60),
                                        ),
                                        Positioned(
                                          left: 4,
                                          top: 187,
                                          child: _hardware(
                                            'down',
                                            Icons.remove,
                                            60,
                                          ),
                                        ),
                                        Positioned(
                                          right: 3,
                                          top: 140,
                                          child: _hardware(
                                            'side',
                                            Icons.power_settings_new,
                                            88,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (apple && r.lit)
                      _outsideControl(
                        'power_chord',
                        Icons.power_settings_new,
                        tr(
                          'Боковая + громкость',
                          'Side + volume',
                          'Бічна + гучність',
                        ),
                        () => open(DevicePage.power),
                        hold: true,
                      ),
                    if (!r.lit && r.power == DevicePower.off)
                      _outsideControl(
                        'device_boot',
                        Icons.power_settings_new,
                        tr(
                          'Удержать для включения',
                          'Hold to power on',
                          'Утримати для ввімкнення',
                        ),
                        () => change(
                          () => r.boot(batteryConnected: batteryConnected),
                        ),
                        hold: true,
                      ),
                    if (spec.panels > 1 && !widget.session.isOpen)
                      _outsideControl(
                        'fold_control',
                        Icons.tablet_mac,
                        spec.panels == 3
                            ? '${r.foldStage + 1}/3 · ${tr('Раскрыть', 'Unfold', 'Розкрити')}'
                            : r.foldStage == 0
                            ? tr('Раскрыть', 'Unfold', 'Розкрити')
                            : tr('Сложить', 'Fold', 'Скласти'),
                        fold,
                      ),
                    if (r.lit)
                      _outsideControl(
                        'device_home',
                        Icons.home_outlined,
                        tr('Домой', 'Home', 'Додому'),
                        () => change(r.unlock),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                child: Text(
                  !batteryConnected
                      ? tr(
                        'Аккумулятор отсоединён. Подключите его перед включением.',
                        'Battery disconnected. Reconnect it before starting.',
                        'Акумулятор від’єднано. Під’єднай перед ввімкненням.',
                      )
                      : !displayConnected
                      ? tr(
                        'Дисплей отсоединён. Завершите сборку.',
                        'Display disconnected. Complete reassembly.',
                        'Дисплей від’єднано. Заверши збирання.',
                      )
                      : tr(
                        'Свайп вниз от верхнего края — быстрые настройки. Свайп вверх — разблокировка.',
                        'Swipe down from the top for quick settings. Swipe up to unlock.',
                        'Свайп униз від верхнього краю — швидкі налаштування. Свайп угору — розблокування.',
                      ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outsideControl(
    String key,
    IconData icon,
    String label,
    VoidCallback action, {
    bool hold = false,
  }) => Tooltip(
    message:
        hold
            ? tr('Удерживайте кнопку', 'Hold the button', 'Утримуй кнопку')
            : label,
    child: InkWell(
      key: ValueKey(key),
      onTap: hold ? null : action,
      onLongPress: hold ? action : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF23303D),
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ),
  );
  Widget _hardware(String id, IconData icon, double height) => Listener(
    key: ValueKey('hardware_$id'),
    onPointerDown: (_) => press(id),
    onPointerUp: (_) => release(id),
    onPointerCancel: (_) => release(id),
    child: Semantics(
      label: id,
      button: true,
      child: Container(
        width: 29,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                r.pressed.contains(id)
                    ? [const Color(0xFF365C73), const Color(0xFF142333)]
                    : [const Color(0xFFABB5C1), const Color(0xFF56616D)],
          ),
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: const Color(0xFF121C28), size: 18),
      ),
    ),
  );

  Widget _screen() {
    if (!displayConnected ||
        !batteryConnected ||
        r.power == DevicePower.off ||
        r.power == DevicePower.asleep) {
      return Container(
        key: const ValueKey('screen_dark'),
        color: Colors.black,
        child:
            r.power == DevicePower.asleep
                ? GestureDetector(
                  onTap: () => change(() => r.power = DevicePower.on),
                  behavior: HitTestBehavior.opaque,
                )
                : null,
      );
    }
    if (r.transitioning) {
      return Container(
        key: ValueKey('screen_${r.power.name}'),
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.power == DevicePower.booting) _bootLogo(),
              if (r.power == DevicePower.shuttingDown || !apple)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    final isLight = [
      DevicePage.settings,
      DevicePage.photos,
      DevicePage.notes,
      DevicePage.browser,
      DevicePage.dialer,
      DevicePage.diagnostics,
    ].contains(r.page);
    return Listener(
      key: const ValueKey('device_screen'),
      onPointerDown: (e) => touchStart = e.localPosition,
      onPointerUp: (e) {
        final delta = e.localPosition - (touchStart ?? e.localPosition);
        if ((touchStart?.dy ?? 999) < 76 && delta.dy > 55) {
          open(DevicePage.controls);
        } else if (delta.dy < -65 && r.page == DevicePage.lock) {
          change(r.unlock);
        }
      },
      child: Theme(
        data:
            isLight
                ? ThemeData.light(useMaterial3: true).copyWith(
                  textTheme: ThemeData.light().textTheme.apply(
                    fontFamily: 'Roboto',
                  ),
                )
                : ThemeData.dark(useMaterial3: true).copyWith(
                  textTheme: ThemeData.dark().textTheme.apply(
                    fontFamily: 'Roboto',
                  ),
                ),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1)),
          child: Stack(
            children: [
              Positioned.fill(child: _wallpaper()),
              Column(
                children: [
                  _status(isLight),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(r.page),
                        child: _page(),
                      ),
                    ),
                  ),
                  if (r.page != DevicePage.power && r.page != DevicePage.lock)
                    GestureDetector(
                      key: const ValueKey('os_home_gesture'),
                      onTap: () => change(r.unlock),
                      onVerticalDragEnd: (_) => change(r.unlock),
                      child: Container(
                        height: 23,
                        color:
                            isLight
                                ? const Color(0xFFF7F9FC)
                                : Colors.transparent,
                        alignment: Alignment.center,
                        child: Container(
                          width: 90,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isLight ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (overlayMs > 0)
                Positioned(
                  left: 10,
                  top: 110,
                  child: Container(
                    width: 35,
                    height: 120,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: LinearProgressIndicator(
                              value: r.volume,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          r.volume == 0 ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              if (r.brightness < .65)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: (.65 - r.brightness) * .6,
                      ),
                    ),
                  ),
                ),
              if (widget.session.service == 'display' &&
                  !widget.session.newPartInstalled)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _CrackPainter()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bootLogo() =>
      apple
          ? SizedBox(
            width: 55,
            height: 65,
            child: CustomPaint(painter: _AppleMark()),
          )
          : Text(
            spec.brand == 'Samsung'
                ? 'SAMSUNG'
                : spec.brand == 'HUAWEI'
                ? 'HUAWEI'
                : 'G',
            style: TextStyle(
              color: Colors.white,
              fontSize: spec.brand == 'Google' ? 54 : 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          );
  Widget _wallpaper() => Image.asset(
    apple
        ? 'assets/wallpapers/blue.jpg'
        : spec.brand == 'HUAWEI'
        ? 'assets/wallpapers/peach.jpg'
        : 'assets/wallpapers/teal.jpg',
    fit: BoxFit.cover,
  );
  Widget _status(bool light) => Container(
    height: 43,
    padding: const EdgeInsets.fromLTRB(18, 8, 12, 0),
    color: light ? const Color(0xFFF7F9FC) : Colors.transparent,
    child: Row(
      children: [
        Text(
          _time(),
          style: TextStyle(
            color: light ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (apple && spec.id == 'iphone15pro')
          Container(
            width: 66,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
          )
        else
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        const Spacer(),
        GestureDetector(
          key: const ValueKey('open_controls'),
          onTap: () => open(DevicePage.controls),
          child: Row(
            children: [
              Icon(
                r.airplane
                    ? Icons.airplanemode_active
                    : r.cellular
                    ? Icons.signal_cellular_alt
                    : Icons.signal_cellular_off,
                color: light ? Colors.black : Colors.white,
                size: 15,
              ),
              if (r.wifi)
                Icon(
                  Icons.wifi,
                  color: light ? Colors.black : Colors.white,
                  size: 17,
                ),
              const SizedBox(width: 4),
              Text(
                '${r.battery}',
                style: TextStyle(
                  color: light ? Colors.black : Colors.white,
                  fontSize: 11,
                ),
              ),
              Icon(
                Icons.battery_5_bar,
                color: light ? Colors.black : Colors.white,
                size: 17,
              ),
            ],
          ),
        ),
      ],
    ),
  );
  String _time() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  Widget _page() => switch (r.page) {
    DevicePage.lock => _lock(),
    DevicePage.home => _home(),
    DevicePage.controls => _controls(),
    DevicePage.power => _power(),
    DevicePage.settings => _settings(),
    DevicePage.camera => _camera(),
    DevicePage.photos => _photos(),
    DevicePage.calculator => _calculator(),
    DevicePage.notes => _notes(),
    DevicePage.clock => _clock(),
    DevicePage.browser => _browser(),
    DevicePage.dialer => _dialer(),
    DevicePage.diagnostics => _diagnostics(),
  };
  Widget _lock() => GestureDetector(
    key: const ValueKey('lock_unlock'),
    onVerticalDragEnd: (d) {
      if ((d.primaryVelocity ?? 0) < 0) change(r.unlock);
    },
    onDoubleTap: () => change(r.unlock),
    child: Column(
      children: [
        const SizedBox(height: 50),
        Icon(
          apple ? Icons.lock_open_rounded : Icons.lock_outline,
          size: 25,
          color: Colors.white70,
        ),
        const SizedBox(height: 12),
        Text(
          _time(),
          style: TextStyle(
            fontSize: apple ? 76 : 68,
            fontWeight: apple ? FontWeight.w300 : FontWeight.w500,
            color: Colors.white,
            letterSpacing: -3,
          ),
        ),
        Text(
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _roundIcon(
              Icons.flashlight_on,
              () => change(() => r.flashlight = !r.flashlight),
              active: r.flashlight,
            ),
            _roundIcon(Icons.camera_alt, () => open(DevicePage.camera)),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          tr('Смахните вверх', 'Swipe up to unlock', 'Проведи вгору'),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 18),
      ],
    ),
  );
  Widget _roundIcon(IconData icon, VoidCallback tap, {bool active = false}) =>
      IconButton(
        onPressed: tap,
        style: IconButton.styleFrom(
          backgroundColor: active ? Colors.white : Colors.white24,
          foregroundColor: active ? Colors.black : Colors.white,
          padding: const EdgeInsets.all(15),
        ),
        icon: Icon(icon, size: 22),
      );
  Widget _home() {
    final apps = <({DevicePage page, IconData icon, String name, Color color})>[
      (
        page: DevicePage.dialer,
        icon: Icons.call,
        name: tr('Телефон', 'Phone', 'Телефон'),
        color: const Color(0xFF23BB63),
      ),
      (
        page: DevicePage.camera,
        icon: Icons.camera_alt,
        name: tr('Камера', 'Camera', 'Камера'),
        color: const Color(0xFF8895A1),
      ),
      (
        page: DevicePage.photos,
        icon: Icons.photo_library,
        name: tr('Фото', 'Photos', 'Фото'),
        color: const Color(0xFFEA9569),
      ),
      (
        page: DevicePage.settings,
        icon: Icons.settings,
        name: tr('Настройки', 'Settings', 'Налаштування'),
        color: const Color(0xFF65798B),
      ),
      (
        page: DevicePage.calculator,
        icon: Icons.calculate,
        name: tr('Калькулятор', 'Calculator', 'Калькулятор'),
        color: const Color(0xFFE99B30),
      ),
      (
        page: DevicePage.notes,
        icon: Icons.note_alt,
        name: tr('Заметки', 'Notes', 'Нотатки'),
        color: const Color(0xFFD4B23F),
      ),
      (
        page: DevicePage.clock,
        icon: Icons.access_time_filled,
        name: tr('Часы', 'Clock', 'Годинник'),
        color: const Color(0xFF1D2530),
      ),
      (
        page: DevicePage.browser,
        icon: Icons.public,
        name: apple ? 'Safari' : tr('Браузер', 'Browser', 'Браузер'),
        color: const Color(0xFF418EC9),
      ),
      (
        page: DevicePage.diagnostics,
        icon: Icons.monitor_heart,
        name: tr('Диагностика', 'Diagnostics', 'Діагностика'),
        color: const Color(0xFF8D69C6),
      ),
    ];
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(18, 22, 18, 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Color(0xFFFFE082), size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.system,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '22°  ·  ${tr('Ясно', 'Clear', 'Ясно')}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: r.foldStage > 0 ? 6 : 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 4,
              mainAxisExtent: 88,
            ),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final a = apps[i];
              return InkWell(
                key: ValueKey('os_app_${a.page.name}'),
                onTap: () => open(a.page),
                child: Column(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(a.color, Colors.white, .2)!,
                            a.color,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(apple ? 14 : 22),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(a.icon, color: Colors.white, size: 29),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(14, 5, 14, 8),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _roundIcon(Icons.call, () => open(DevicePage.dialer)),
              _roundIcon(Icons.public, () => open(DevicePage.browser)),
              _roundIcon(Icons.camera_alt, () => open(DevicePage.camera)),
              _roundIcon(Icons.settings, () => open(DevicePage.settings)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controls() => Container(
    color: const Color(0xE11B2A45),
    child: ListView(
      padding: const EdgeInsets.all(17),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                apple
                    ? tr(
                      'Пункт управления',
                      'Control Center',
                      'Пункт керування',
                    )
                    : tr(
                      'Быстрые настройки',
                      'Quick settings',
                      'Швидкі налаштування',
                    ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            InkWell(
              key: const ValueKey('controls_power'),
              onLongPress: () => open(DevicePage.power),
              onTap: apple ? null : () => open(DevicePage.power),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.power_settings_new,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _toggle(
              'wifi',
              Icons.wifi,
              'Wi-Fi',
              r.wifi,
              () => change(() => r.wifi = !r.wifi),
            ),
            _toggle(
              'cellular',
              Icons.signal_cellular_alt,
              tr('Сотовые данные', 'Mobile data', 'Стільникові дані'),
              r.cellular && !r.airplane,
              () => change(() => r.setCellular(!r.cellular)),
            ),
            _toggle(
              'bluetooth',
              Icons.bluetooth,
              'Bluetooth',
              r.bluetooth,
              () => change(() => r.bluetooth = !r.bluetooth),
            ),
            _toggle(
              'airplane',
              Icons.airplanemode_active,
              tr('Авиарежим', 'Airplane mode', 'Авіарежим'),
              r.airplane,
              () => change(() => r.setAirplane(!r.airplane)),
            ),
            _toggle(
              'flashlight',
              Icons.flashlight_on,
              tr('Фонарик', 'Flashlight', 'Ліхтарик'),
              r.flashlight,
              () => change(() => r.flashlight = !r.flashlight),
            ),
            _toggle(
              'silent',
              r.silent ? Icons.volume_off : Icons.volume_up,
              tr('Без звука', 'Silent', 'Без звуку'),
              r.silent,
              () => change(() => r.silent = !r.silent),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _glassSlider(
          'os_brightness',
          Icons.brightness_6,
          tr('Яркость', 'Brightness', 'Яскравість'),
          r.brightness,
          (v) => change(() => r.brightness = v.clamp(.1, 1)),
        ),
        const SizedBox(height: 12),
        _glassSlider(
          'os_volume',
          Icons.volume_up,
          tr('Громкость', 'Volume', 'Гучність'),
          r.volume,
          (v) => change(() => r.volume = v),
        ),
        const SizedBox(height: 18),
        Text(
          tr(
            'Удерживайте значок питания для выключения.',
            'Hold the power icon to shut down.',
            'Утримуй значок живлення для вимкнення.',
          ),
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        TextButton(
          onPressed: () => change(r.unlock),
          child: Text(tr('Закрыть', 'Close', 'Закрити')),
        ),
      ],
    ),
  );
  Widget _toggle(
    String key,
    IconData icon,
    String label,
    bool selected,
    VoidCallback action,
  ) => InkWell(
    key: ValueKey('os_$key'),
    onTap: action,
    borderRadius: BorderRadius.circular(23),
    child: Container(
      width: 125,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected ? accent : Colors.white12,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: selected ? Colors.black87 : Colors.white, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              color: selected ? Colors.black87 : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            selected ? tr('Вкл.', 'On', 'Увімк.') : tr('Выкл.', 'Off', 'Вимк.'),
            style: TextStyle(
              color: selected ? Colors.black54 : Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _glassSlider(
    String key,
    IconData icon,
    String label,
    double value,
    ValueChanged<double> changed,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 3),
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        Slider(
          key: ValueKey(key),
          value: value,
          onChanged: changed,
          activeColor: Colors.white,
          inactiveColor: Colors.white24,
        ),
      ],
    ),
  );
  Widget _power() => Container(
    color: const Color(0xED172336),
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 55),
        if (apple)
          LayoutBuilder(
            builder:
                (context, c) => GestureDetector(
                  key: const ValueKey('shutdown_slider'),
                  onHorizontalDragUpdate:
                      (d) => setState(
                        () =>
                            slide = (slide + d.delta.dx / (c.maxWidth - 58))
                                .clamp(0, 1),
                      ),
                  onHorizontalDragEnd: (_) {
                    if (slide > .86) {
                      change(r.shutDown);
                    }
                    setState(() => slide = 0);
                  },
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: Text(
                            tr('выключите', 'slide to power off', 'вимкніть'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(-1 + slide * 2, 0),
                          child: Container(
                            width: 57,
                            height: 57,
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.power_settings_new,
                              color: Colors.redAccent,
                              size: 29,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        if (!apple)
          FilledButton.icon(
            key: const ValueKey('android_power_off'),
            onPressed: () => change(r.shutDown),
            icon: const Icon(Icons.power_settings_new),
            label: Text(tr('Выключить', 'Power off', 'Вимкнути')),
          ),
        const SizedBox(height: 20),
        if (!apple)
          OutlinedButton.icon(
            onPressed: () => change(r.restart),
            icon: const Icon(Icons.restart_alt),
            label: Text(tr('Перезагрузить', 'Restart', 'Перезавантажити')),
          ),
        const Spacer(),
        _roundIcon(Icons.close, () => change(r.unlock)),
        const SizedBox(height: 8),
        Text(
          tr('Отменить', 'Cancel', 'Скасувати'),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 35),
      ],
    ),
  );
  Widget _lightPage(String title, List<Widget> children) => Material(
    color: const Color(0xFFF7F9FC),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 16, 9),
          child: Row(
            children: [
              IconButton(
                onPressed: () => change(r.unlock),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF142333),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: children,
          ),
        ),
      ],
    ),
  );
  Widget _settings() =>
      _lightPage(tr('Настройки', 'Settings', 'Налаштування'), [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: accent,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(spec.name),
          subtitle: Text('${spec.system} · ${spec.storage}'),
        ),
        const Divider(),
        SwitchListTile(
          key: const ValueKey('settings_wifi'),
          title: const Text('Wi-Fi'),
          value: r.wifi,
          onChanged: (v) => change(() => r.wifi = v),
        ),
        SwitchListTile(
          title: Text(tr('Сотовые данные', 'Mobile data', 'Стільникові дані')),
          value: r.cellular && !r.airplane,
          onChanged: r.airplane ? null : (v) => change(() => r.setCellular(v)),
        ),
        SwitchListTile(
          title: const Text('Bluetooth'),
          value: r.bluetooth,
          onChanged: (v) => change(() => r.bluetooth = v),
        ),
        SwitchListTile(
          title: Text(tr('Авиарежим', 'Airplane mode', 'Авіарежим')),
          value: r.airplane,
          onChanged: (v) => change(() => r.setAirplane(v)),
        ),
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: Text(
            tr('Экран и яркость', 'Display & brightness', 'Екран і яскравість'),
          ),
        ),
        Slider(
          value: r.brightness,
          min: .1,
          onChanged: (v) => change(() => r.brightness = v),
        ),
        ListTile(
          leading: const Icon(Icons.volume_up),
          title: Text(tr('Звук', 'Sound', 'Звук')),
        ),
        Slider(value: r.volume, onChanged: (v) => change(() => r.volume = v)),
        ListTile(
          leading: const Icon(Icons.battery_full),
          title: Text(
            '${tr('Аккумулятор', 'Battery', 'Акумулятор')} · ${r.battery}%',
          ),
          subtitle: Text(
            widget.session.service == 'battery' &&
                    !widget.session.newPartInstalled
                ? tr(
                  'Требуется обслуживание',
                  'Service recommended',
                  'Потрібне обслуговування',
                )
                : tr(
                  'Работает нормально',
                  'Normal operation',
                  'Працює нормально',
                ),
          ),
        ),
        const Divider(),
        Text(
          '${spec.screen}\n${spec.chip}\n${spec.storage}',
          style: const TextStyle(color: Color(0xFF536C7D), height: 1.8),
        ),
        TextButton(
          onPressed: () => open(DevicePage.power),
          child: Text(tr('Выключить', 'Shut down', 'Вимкнути')),
        ),
      ]);
  Widget _camera() => Container(
    color: Colors.black,
    child: Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.session.service != 'camera' ||
                  widget.session.newPartInstalled)
                Image.asset('assets/repair/workshop.jpg', fit: BoxFit.cover)
              else
                Center(
                  child: Text(
                    tr('Нет изображения', 'No image', 'Немає зображення'),
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
              const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    'PHOTO',
                    style: TextStyle(color: Colors.amber, letterSpacing: 3),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${r.photos}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => open(DevicePage.photos),
                icon: const Icon(Icons.photo_library, color: Colors.white),
              ),
              InkWell(
                key: const ValueKey('camera_capture'),
                onTap:
                    widget.session.service == 'camera' &&
                            !widget.session.newPartInstalled
                        ? null
                        : () => change(
                          () => r.photos = (r.photos + 1).clamp(0, 100),
                        ),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 5),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => change(r.unlock),
                icon: const Icon(Icons.home, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _photos() => _lightPage(tr('Фото', 'Photos', 'Фото'), [
    Text(
      '${tr('Снимки', 'Photos', 'Знімки')}: ${r.photos}',
      style: const TextStyle(fontSize: 18),
    ),
    const SizedBox(height: 15),
    if (r.photos == 0)
      Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          tr(
            'Сделайте снимок в Камере',
            'Take a photo in Camera',
            'Зроби знімок у Камері',
          ),
        ),
      ),
    if (r.photos > 0)
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < math.min(r.photos, 12); i++)
            InkWell(
              onTap:
                  () => showDialog<void>(
                    context: context,
                    builder:
                        (c) => Dialog(
                          child: Image.asset('assets/repair/workshop.jpg'),
                        ),
                  ),
              child: Image.asset(
                'assets/repair/workshop.jpg',
                width: 86,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    if (r.photos > 0)
      TextButton(
        onPressed: () => change(() => r.photos = 0),
        child: Text(tr('Удалить снимки', 'Delete photos', 'Видалити знімки')),
      ),
  ]);
  Widget _calculator() => Container(
    color: Colors.black,
    child: Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: FittedBox(
                child: Text(
                  r.calculator,
                  key: const ValueKey('calculator_value'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
        ),
        GridView(
          padding: const EdgeInsets.all(14),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 55,
          ),
          children: [
            for (final key in [
              'AC',
              '⌫',
              '÷',
              '×',
              '7',
              '8',
              '9',
              '−',
              '4',
              '5',
              '6',
              '+',
              '1',
              '2',
              '3',
              '=',
              '0',
              '.',
            ])
              InkWell(
                key: ValueKey('calc_$key'),
                onTap: () => change(() => r.calcKey(key)),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        ['÷', '×', '−', '+', '='].contains(key)
                            ? const Color(0xFFFF9F0A)
                            : const Color(0xFF343438),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    key,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
  Widget _notes() => _lightPage(tr('Заметки', 'Notes', 'Нотатки'), [
    TextField(
      key: const ValueKey('device_notes'),
      controller: notes,
      maxLines: 16,
      maxLength: 4000,
      onChanged: (v) => change(() => r.note = v),
      decoration: InputDecoration(
        hintText: tr(
          'Запишите результат проверки…',
          'Write your inspection notes…',
          'Запиши результат перевірки…',
        ),
        border: InputBorder.none,
      ),
    ),
  ]);
  Widget _clock() => Container(
    color: const Color(0xFF151D2A),
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 24),
        Text(
          _time(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 58,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          tr('Секундомер', 'Stopwatch', 'Секундомір'),
          style: const TextStyle(color: Colors.white60, fontSize: 18),
        ),
        const SizedBox(height: 20),
        Text(
          '${(r.stopwatchMs ~/ 60000).toString().padLeft(2, '0')}:${(r.stopwatchMs ~/ 1000 % 60).toString().padLeft(2, '0')}.${(r.stopwatchMs ~/ 100 % 10)}',
          style: const TextStyle(color: Colors.white, fontSize: 35),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed:
              () => change(() => r.stopwatchRunning = !r.stopwatchRunning),
          child: Text(
            r.stopwatchRunning
                ? tr('Стоп', 'Stop', 'Стоп')
                : tr('Старт', 'Start', 'Старт'),
          ),
        ),
        TextButton(
          onPressed:
              () => change(() {
                r.stopwatchRunning = false;
                r.stopwatchMs = 0;
              }),
          child: Text(tr('Сброс', 'Reset', 'Скинути')),
        ),
      ],
    ),
  );
  Widget
  _browser() => _lightPage(apple ? 'Safari' : tr('Браузер', 'Browser', 'Браузер'), [
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EAF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        r.network
            ? 'techlife.local/help'
            : tr('Нет подключения', 'No connection', 'Немає з’єднання'),
      ),
    ),
    const SizedBox(height: 20),
    if (!r.network)
      Text(
        tr(
          'Включите Wi-Fi или сотовые данные в быстрых настройках.',
          'Enable Wi-Fi or mobile data in quick settings.',
          'Увімкни Wi-Fi або стільникові дані у швидких налаштуваннях.',
        ),
      ),
    if (r.network) ...[
      Text(
        tr('Справочник мастера', 'Repair desk', 'Довідник майстра'),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      for (final row in [
        (
          tr('Перед разборкой', 'Before opening', 'Перед розбиранням'),
          tr(
            'Выключите телефон. После открытия сначала отключите все аккумуляторы.',
            'Power off the phone. After opening, disconnect all batteries first.',
            'Вимкни телефон. Після відкриття спочатку від’єднай усі акумулятори.',
          ),
        ),
        (
          tr(
            'Проверка после ремонта',
            'After repair',
            'Перевірка після ремонту',
          ),
          tr(
            'Проверьте изображение и касания, камеры и зарядку после сборки.',
            'Check the display, touch, cameras and charging after reassembly.',
            'Перевір зображення й дотики, камери та заряджання після збирання.',
          ),
        ),
      ])
        ExpansionTile(
          title: Text(row.$1),
          children: [
            Padding(padding: const EdgeInsets.all(14), child: Text(row.$2)),
          ],
        ),
    ],
  ]);
  Widget _dialer() => _lightPage(tr('Телефон', 'Phone', 'Телефон'), [
    Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        calling
            ? tr('Проверка связи…', 'Testing signal…', 'Перевірка зв’язку…')
            : r.dialed,
        style: const TextStyle(fontSize: 30),
        textAlign: TextAlign.center,
      ),
    ),
    GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.4,
      children: [
        for (final key in [
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8',
          '9',
          '*',
          '0',
          '#',
        ])
          TextButton(
            onPressed:
                () => change(
                  () =>
                      r.dialed = (r.dialed + key).substring(
                        0,
                        (r.dialed.length + 1).clamp(0, 20),
                      ),
                ),
            child: Text(key, style: const TextStyle(fontSize: 28)),
          ),
      ],
    ),
    Center(
      child: FilledButton.icon(
        onPressed: () => setState(() => calling = !calling),
        icon: Icon(calling ? Icons.call_end : Icons.call),
        label: Text(
          calling
              ? tr('Завершить', 'End', 'Завершити')
              : tr('Тест связи', 'Signal test', 'Тест зв’язку'),
        ),
      ),
    ),
    const SizedBox(height: 12),
    Text(
      r.cellular && !r.airplane
          ? tr(
            'Сигнал есть · тестовый вызов',
            'Signal available · test call',
            'Сигнал є · тестовий виклик',
          )
          : tr(
            'Нет сотовой сети',
            'No cellular service',
            'Немає стільникової мережі',
          ),
      textAlign: TextAlign.center,
    ),
    TextButton(
      onPressed: () => change(() => r.dialed = ''),
      child: Text(tr('Очистить', 'Clear', 'Очистити')),
    ),
  ]);
  Widget
  _diagnostics() => _lightPage(tr('Диагностика', 'Diagnostics', 'Діагностика'), [
    for (final item in [
      (
        Icons.touch_app,
        tr('Дисплей и касания', 'Display & touch', 'Дисплей і дотики'),
        'display',
      ),
      (Icons.camera_alt, tr('Камера', 'Camera', 'Камера'), 'camera'),
      (
        Icons.battery_charging_full,
        tr('Зарядка', 'Charging', 'Заряджання'),
        'port',
      ),
    ])
      ListTile(
        leading: Icon(item.$1),
        title: Text(item.$2),
        trailing: Icon(
          widget.session.service == item.$3 && !widget.session.newPartInstalled
              ? Icons.error_outline
              : Icons.check_circle,
          color:
              widget.session.service == item.$3 &&
                      !widget.session.newPartInstalled
                  ? Colors.orange
                  : Colors.teal,
        ),
        onTap:
            () => open(
              item.$3 == 'camera' ? DevicePage.camera : DevicePage.settings,
            ),
      ),
    ListTile(
      leading: const Icon(Icons.memory),
      title: Text(spec.chip),
      subtitle: Text(spec.storage),
    ),
    Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        tr(
          'Результат учитывает установленную деталь. Финальную проверку заказа выполните тестером на столе.',
          'Results reflect the installed part. Complete the order’s final tests with the bench tester.',
          'Результат враховує встановлену деталь. Фінальну перевірку замовлення виконай тестером на столі.',
        ),
        style: const TextStyle(color: Color(0xFF536C7D), height: 1.5),
      ),
    ),
  ]);
}

class _FoldMotion extends CustomPainter {
  final double stage, panel;
  final int panels;
  final ui.Image? image;
  _FoldMotion(this.stage, this.panel, this.panels, this.image);
  @override
  void paint(Canvas c, Size s) {
    final i = stage.floor() + 1;
    final t = stage - stage.floor();
    if (i >= panels || t < .001 || t > .999) return;
    final h = s.height,
        w = panel - 7,
        hinge = (panel * i - 7).clamp(0.0, s.width);
    final angle = math.pi * (1 - t),
        z = math.sin(angle) * w * (panels == 3 && i.isEven ? -1 : 1);
    final perspective = 1500 / (1500 + z);
    final end = hinge + w * math.cos(angle) * perspective,
        top = (h - h * perspective) / 2;
    final pts = [
      Offset(hinge, 0),
      Offset(end, top),
      Offset(end, h - top),
      Offset(hinge, h),
    ];
    final path = Path()..addPolygon(pts, true);
    c.drawShadow(path, Colors.black, .12 * w, false);
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF162C40),
            Color.lerp(const Color(0xFF6F889D), const Color(0xFF102136), t)!,
          ],
        ).createShader(
          Rect.fromLTWH(math.min(end, hinge), 0, (end - hinge).abs() + 1, h),
        ),
    );
    final img = image;
    if (img != null && math.cos(angle) >= 0 && (end - hinge).abs() > 2) {
      final iw = img.width.toDouble(), ih = img.height.toDouble();
      final uv =
          math.cos(angle) < 0
              ? [Offset(iw, 0), Offset.zero, Offset(0, ih), Offset(iw, ih)]
              : [
                Offset(iw * .5, 0),
                Offset(iw, 0),
                Offset(iw, ih),
                Offset(iw * .5, ih),
              ];
      c.save();
      c.clipPath(path);
      c.drawVertices(
        ui.Vertices(ui.VertexMode.triangleFan, pts, textureCoordinates: uv),
        BlendMode.srcOver,
        Paint()
          ..shader = ui.ImageShader(
            img,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().storage,
          )
          ..filterQuality = FilterQuality.high,
      );
      c.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: .18 * math.sin(angle).abs()),
      );
      c.restore();
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFB0BBC4),
    );
    c.drawLine(
      Offset(hinge, 3),
      Offset(hinge, h - 3),
      Paint()
        ..color = const Color(0xFF6C8394)
        ..strokeWidth = 5,
    );
    for (var k = 0; k < 14; k++) {
      final y = h * .1 + k * h * .057;
      c.drawLine(
        Offset(hinge - 2, y),
        Offset(hinge + 2, y + 6),
        Paint()
          ..color = Colors.white38
          ..strokeWidth = 1,
      );
    }
    if (t > .2 && t < .8) {
      c.drawLine(
        pts[1],
        pts[2],
        Paint()
          ..color = Colors.white.withValues(alpha: .45)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FoldMotion old) =>
      stage != old.stage || image != old.image;
}

class _AppleMark extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 60, s.height / 70);
    final p =
        Path()
          ..moveTo(31, 18)
          ..cubicTo(16, 8, 2, 21, 5, 37)
          ..cubicTo(7, 51, 16, 69, 25, 65)
          ..cubicTo(29, 62, 32, 62, 37, 65)
          ..cubicTo(46, 69, 55, 51, 57, 43)
          ..cubicTo(43, 38, 43, 26, 54, 20)
          ..cubicTo(46, 9, 36, 13, 31, 18)
          ..close();
    c.drawPath(p, Paint()..color = Colors.white);
    c.drawPath(
      Path()
        ..moveTo(30, 13)
        ..cubicTo(29, 4, 38, -2, 44, 0)
        ..cubicTo(45, 8, 37, 14, 30, 13),
      Paint()..color = Colors.white,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CrackPainter extends CustomPainter {
  const _CrackPainter();
  @override
  void paint(Canvas c, Size s) {
    final start = Offset(s.width * .34, s.height * .58);
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..strokeWidth = .8
          ..style = PaintingStyle.stroke;
    for (var i = 0; i < 9; i++) {
      final a = i * math.pi / 4.5;
      final end =
          start +
          Offset(math.cos(a) * s.width * .8, math.sin(a) * s.height * .6);
      c.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo((start.dx + end.dx) / 2 + 8, (start.dy + end.dy) / 2 - 8)
          ..lineTo(end.dx, end.dy),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
