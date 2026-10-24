import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/market/device_catalog.dart';
import '../../core/market/market_strings.dart';
import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/repair/repair_session.dart';
import '../../core/repair/device_profile.dart';
import '../../core/repair/repair_strings.dart';
import '../shell.dart';
import '../widgets.dart';
import 'workbench_geometry.dart';
import 'workbench_painter.dart';
import 'photo_anatomy.dart';
import 'device_lab.dart';
import 'tool_artwork.dart';

IconData repairToolIcon(RepairTool tool) => switch (tool) {
  RepairTool.hand => Icons.pan_tool_alt_outlined,
  RepairTool.driver => Icons.hardware_outlined,
  RepairTool.heater => Icons.air,
  RepairTool.suction => Icons.radio_button_checked,
  RepairTool.spudger => Icons.format_color_reset_outlined,
  RepairTool.tweezers => Icons.content_cut,
  RepairTool.meter => Icons.speed_outlined,
  RepairTool.solvent => Icons.water_drop_outlined,
  RepairTool.pick => Icons.change_history,
  RepairTool.adhesive => Icons.album_outlined,
};

class RepairBench extends StatefulWidget {
  final String orderId;
  const RepairBench({super.key, required this.orderId});
  @override
  State<RepairBench> createState() => _RepairBenchState();
}

class _RepairBenchState extends State<RepairBench> {
  bool _started = false, _error = false;
  String? _feedback;
  final GlobalKey<WorkbenchViewState> _sceneKey = GlobalKey();
  final ScrollController _toolScroll = ScrollController();
  int _lastToolStep = -1;
  double _lastToolWidth = 0;

  @override
  void dispose() {
    _toolScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      context.read<GameState>().startWorkbench(widget.orderId);
      _started = true;
    }
  }

  void _exit() => context.read<Shell>().open('repair');
  void _inspect(RepairSession s) => showDeviceLab(
    context,
    s,
    () => context.read<GameState>().saveRepairDevice(widget.orderId),
  );
  void _act(
    String target,
    RepairGesture gesture, {
    String? destination,
    int heldMs = 0,
  }) {
    final gs = context.read<GameState>();
    final result = gs.repairAction(
      widget.orderId,
      target,
      gesture,
      destination: destination,
      heldMs: heldMs,
    );
    if (!mounted) return;
    setState(() {
      _feedback = result.message;
      _error =
          result.outcome == RepairOutcome.mistake ||
          result.outcome == RepairOutcome.blocked;
    });
    if (gs.haptics) {
      if (result.accepted) HapticFeedback.selectionClick();
      if (result.outcome == RepairOutcome.mistake) {
        HapticFeedback.mediumImpact();
      }
    }
    if (result.message == 'r_use_shutdown' || result.message == 'r_use_boot') {
      _inspect(gs.repairs[widget.orderId]!);
    }
    if (result.message == 'r_missing_part') {
      showDialog<void>(
        context: context,
        builder:
            (c) => AlertDialog(
              title: Text('need_part'.tr),
              content: Text(rt('r_missing_part')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(c);
                    context.read<Shell>().open('shop');
                  },
                  child: Text('go_shop'.tr),
                ),
              ],
            ),
      );
    }
  }

  void _help() => showDialog<void>(
    context: context,
    builder:
        (c) => AlertDialog(
          title: Text(rt('r_help')),
          content: SingleChildScrollView(child: Text(rt('r_help_body'))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
  );
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = gs.repairs[widget.orderId];
    if (s == null) {
      return AppPage(title: 'repair'.tr, child: Empty('no_orders'.tr));
    }
    final matching = gs.orders.where((o) => o.id == widget.orderId);
    final device =
        matching.isEmpty
            ? (deviceFor(s.device)?.name ?? s.device)
            : matching.first.device;
    final cat = services[s.service]!.cat;
    final quality = (1 - .12 * s.mistakes * (gs.insured ? .5 : 1)).clamp(
      .4,
      1.0,
    );
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: ThemeData.dark(
          useMaterial3: true,
        ).textTheme.apply(fontFamily: 'Roboto'),
        colorScheme: const ColorScheme.dark(
          primary: benchBlue,
          secondary: benchGreen,
          surface: benchInk,
        ),
      ),
      child: CallbackShortcuts(
        bindings: {
          for (var i = 0; i < RepairTool.values.length; i++)
            SingleActivator(
              [
                LogicalKeyboardKey.digit1,
                LogicalKeyboardKey.digit2,
                LogicalKeyboardKey.digit3,
                LogicalKeyboardKey.digit4,
                LogicalKeyboardKey.digit5,
                LogicalKeyboardKey.digit6,
                LogicalKeyboardKey.digit7,
                LogicalKeyboardKey.digit8,
                LogicalKeyboardKey.digit9,
                LogicalKeyboardKey.digit0,
              ][i],
            ): () {
              _sceneKey.currentState?.cancelInteraction();
              gs.selectRepairTool(widget.orderId, RepairTool.values[i]);
            },
          const SingleActivator(LogicalKeyboardKey.keyH):
              () => gs.toggleRepairHints(widget.orderId),
          const SingleActivator(LogicalKeyboardKey.escape): _exit,
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: benchInk,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/repair/workshop.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .22),
                          Colors.black.withValues(alpha: .16),
                          Colors.black.withValues(alpha: .72),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final sidebar = c.maxWidth >= 1000 && c.maxHeight >= 620;
                      final short = c.maxHeight < 520;
                      return Column(
                        children: [
                          _header(gs, s, c.maxWidth),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (sidebar)
                                  SizedBox(
                                    width: 274,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        0,
                                        12,
                                      ),
                                      child: _glass(
                                        child: SingleChildScrollView(
                                          child: _task(
                                            s,
                                            device,
                                            quality,
                                            expanded: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      if (!sidebar)
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            12,
                                            short ? 0 : 6,
                                            12,
                                            0,
                                          ),
                                          child: _glass(
                                            padding: EdgeInsets.all(
                                              short ? 8 : 12,
                                            ),
                                            child: _task(
                                              s,
                                              device,
                                              quality,
                                              compact: short,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: WorkbenchView(
                                                key: _sceneKey,
                                                session: s,
                                                device: device,
                                                onAction: _act,
                                                onInspect: () => _inspect(s),
                                              ),
                                            ),
                                            Positioned(
                                              right: 12,
                                              top: 10,
                                              child: _glass(
                                                padding: const EdgeInsets.all(
                                                  3,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: '−',
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed:
                                                          () => _sceneKey
                                                              .currentState
                                                              ?.changeZoom(-.3),
                                                      icon: const Icon(
                                                        Icons.remove,
                                                        size: 19,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: '1:1',
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed:
                                                          () =>
                                                              _sceneKey
                                                                  .currentState
                                                                  ?.resetView(),
                                                      icon: const Icon(
                                                        Icons
                                                            .center_focus_strong,
                                                        size: 19,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: '+',
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed:
                                                          () => _sceneKey
                                                              .currentState
                                                              ?.changeZoom(.3),
                                                      icon: const Icon(
                                                        Icons.add,
                                                        size: 19,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                          ),
                          if (!short)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _feedback == null
                                          ? rt('r_saved')
                                          : rt(_feedback!),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            _error
                                                ? const Color(0xFFFFBA91)
                                                : Colors.white70,
                                      ),
                                    ),
                                  ),
                                  if (cat != null)
                                    Text(
                                      '${rt('r_in_stock')}: ${s.training ? '∞' : (gs.parts[cat] ?? 0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: benchGreen,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          _tools(gs, s, compact: short),
                        ],
                      );
                    },
                  ),
                ),
                if (s.finished)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 410),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _glass(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 64,
                                      color: benchGreen,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'finish_ok'.tr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      s.training
                                          ? rt('r_training_done')
                                          : '${'reward'.tr}: ${money(s.reward ?? 0)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: benchGreen,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${'mistakes'.tr}: ${s.mistakes}  ·  ${rt('r_quality')}: ${(quality * 100).round()}%',
                                    ),
                                    if (s.training)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          rt('r_no_reward'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _inspect(s),
                                          icon: const Icon(Icons.smartphone),
                                          label: Text(
                                            mt(
                                              'Проверить телефон',
                                              'Inspect phone',
                                              'Перевірити телефон',
                                            ),
                                          ),
                                        ),
                                        if (s.training)
                                          OutlinedButton(
                                            onPressed: () {
                                              gs.resetPractice();
                                              setState(() => _feedback = null);
                                            },
                                            child: Text(rt('r_again')),
                                          ),
                                        FilledButton(
                                          onPressed: _exit,
                                          child: Text(rt('r_exit')),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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

  Widget _header(GameState gs, RepairSession s, double width) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
    child: Row(
      children: [
        _glass(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Row(
            children: [
              IconButton(
                tooltip: rt('r_exit'),
                onPressed: _exit,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              if (width > 400)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tech',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: 'Life',
                          style: TextStyle(
                            color: benchBlue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 25, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            s.training ? rt('r_training') : rt('r_live'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
        ),
        _glass(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Text(
            money(gs.balance),
            style: const TextStyle(
              color: benchGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: rt('r_help'),
          onPressed: _help,
          icon: const Icon(Icons.help_outline, size: 22),
        ),
        IconButton(
          key: const ValueKey('device_inspect'),
          tooltip: mt('Осмотр и ОС', 'Inspect device OS', 'Огляд та ОС'),
          onPressed: () => _inspect(s),
          icon: const Icon(Icons.smartphone_rounded, size: 22),
        ),
        if (width >= 400)
          IconButton(
            tooltip: 'shop'.tr,
            onPressed: () => context.read<Shell>().open('shop'),
            icon: const Icon(Icons.storefront_outlined, size: 22),
          ),
      ],
    ),
  );

  Widget _task(
    RepairSession s,
    String device,
    double quality, {
    bool expanded = false,
    bool compact = false,
  }) {
    final current = s.current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Row(
            children: [
              const Icon(Icons.track_changes, size: 16, color: benchBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$device · ${rt('r_step')} ${math.min(s.index + 1, s.steps.length)}/${s.steps.length}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
              if (!expanded)
                Text(
                  '${(s.progress * 100).round()}%',
                  style: const TextStyle(color: benchGreen, fontSize: 11),
                ),
            ],
          ),
        if (!compact) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                current == null ? 'finish_ok'.tr : rt(current.titleKey),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 14 : 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (compact)
              Text(
                '  ${math.min(s.index + 1, s.steps.length)}/${s.steps.length}',
                style: const TextStyle(fontSize: 11, color: benchGreen),
              ),
          ],
        ),
        if (s.hints && current != null)
          Padding(
            padding: EdgeInsets.only(top: compact ? 3 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  ToolArtwork(current.tool, size: 34),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    rt(current.hintKey),
                    maxLines: expanded ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: const Color(0xFFC4D3DD),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (current != null &&
            (current.id == 'power_off' || current.id == 'test'))
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: FilledButton.icon(
              key: const ValueKey('device_inspect_hint'),
              onPressed: () => _inspect(s),
              icon: const Icon(Icons.smartphone, size: 17),
              label: Text(
                mt('Осмотр и ОС', 'Inspect device OS', 'Огляд та ОС'),
                style: TextStyle(fontSize: compact ? 11 : 13),
              ),
            ),
          ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: s.progress,
            minHeight: 4,
            color: benchGreen,
            backgroundColor: Colors.white10,
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 18),
          Text(
            '${'mistakes'.tr}: ${s.mistakes}   ·   ${(quality * 100).round()}%',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ...s.steps
              .asMap()
              .entries
              .where(
                (e) => e.key >= math.max(0, s.index - 1) && e.key < s.index + 5,
              )
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        e.key < s.index
                            ? Icons.check_circle
                            : e.key == s.index
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 17,
                        color:
                            e.key < s.index
                                ? benchGreen
                                : e.key == s.index
                                ? benchBlue
                                : Colors.white30,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          rt(e.value.titleKey),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                e.key == s.index
                                    ? Colors.white
                                    : Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 14),
          Text(
            rt('r_parts_note'),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _tools(GameState gs, RepairSession s, {required bool compact}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (_lastToolStep != s.index || _lastToolWidth != screenWidth) {
      _lastToolStep = s.index;
      _lastToolWidth = screenWidth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_toolScroll.hasClients) return;
        final width = compact ? 64.0 : 80.0;
        final target =
            (s.current?.tool ?? s.tool).index * width +
            width / 2 -
            _toolScroll.position.viewportDimension / 2;
        _toolScroll.animateTo(
          target.clamp(0.0, _toolScroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    }
    return Container(
      margin: EdgeInsets.fromLTRB(10, compact ? 3 : 8, 10, 8),
      decoration: BoxDecoration(
        color: benchInk.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: compact ? 62 : 84,
              child: ListView(
                controller: _toolScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(5),
                children: [
                  for (final tool in RepairTool.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message:
                            '${(tool.index + 1) % 10} · ${rt('r_tool_${tool.name}')}',
                        child: InkWell(
                          key: ValueKey('tool_${tool.name}'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            _sceneKey.currentState?.cancelInteraction();
                            gs.selectRepairTool(widget.orderId, tool);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: compact ? 60 : 76,
                            decoration: BoxDecoration(
                              color:
                                  s.tool == tool
                                      ? benchBlue.withValues(alpha: .18)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    s.tool == tool
                                        ? benchBlue
                                        : s.hints && s.current?.tool == tool
                                        ? benchGreen
                                        : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ToolArtwork(tool, size: compact ? 27 : 42),
                                const SizedBox(height: 4),
                                Text(
                                  rt('r_tool_${tool.name}'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 9 : 10,
                                    color:
                                        s.tool == tool
                                            ? Colors.white
                                            : Colors.white54,
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
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: rt('r_hints'),
                onPressed: () => gs.toggleRepairHints(widget.orderId),
                icon: Icon(
                  s.hints ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: s.hints ? const Color(0xFFF1CC75) : Colors.white54,
                  size: compact ? 21 : 24,
                ),
              ),
              if (!compact)
                Text(
                  rt('r_hints'),
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _glass({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: benchInk.withValues(alpha: .93),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
      ],
    ),
    child: child,
  );
}

typedef WorkbenchAction =
    void Function(
      String target,
      RepairGesture gesture, {
      String? destination,
      int heldMs,
    });

class WorkbenchView extends StatefulWidget {
  final RepairSession session;
  final String device;
  final WorkbenchAction onAction;
  final VoidCallback? onInspect;
  const WorkbenchView({
    super.key,
    required this.session,
    required this.device,
    required this.onAction,
    this.onInspect,
  });
  @override
  State<WorkbenchView> createState() => WorkbenchViewState();
}

class WorkbenchViewState extends State<WorkbenchView>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: RepairSession.holdDurationMs),
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed && _pressed != null) {
      _committed = true;
      widget.onAction(
        _pressed!,
        RepairGesture.hold,
        heldMs:
            widget.session.heatingStep
                ? RepairSession.heatDurationMs
                : RepairSession.holdDurationMs,
      );
    }
  });
  final Set<int> _pointers = {};
  Size _viewport = Size.zero;
  WorkbenchGeometry _geometry = WorkbenchGeometry(true);
  String? _pressed, _drag;
  Offset? _down, _dragPosition;
  Offset _dragAnchor = Offset.zero,
      _pan = Offset.zero,
      _pinchScene = Offset.zero;
  double _zoom = 1, _pinchStart = 1;
  bool _committed = false, _pinching = false, _moved = false;
  PhotoAnatomy? _photo;
  String? _photoId;
  WorkbenchPainter get _painter => WorkbenchPainter(
    geometry: _geometry,
    session: widget.session,
    device: widget.device,
    zoom: _zoom,
    pan: _pan,
    pulse: _pulse.value,
    hold: _hold.value,
    holdingTarget: _hold.isAnimating ? _pressed : null,
    dragTarget: _drag,
    dragPosition: _dragPosition,
    photo: _photo,
  );
  @override
  void dispose() {
    _pulse.dispose();
    _hold.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WorkbenchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session)) cancelInteraction();
    _loadPhoto();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPhoto();
  }

  void _loadPhoto() {
    final id = profileFor(widget.session.device).id;
    if (_photoId != id) {
      _photoId = id;
      _photo = null;
      PhotoAnatomy.load(id).then((value) {
        if (mounted && _photoId == id) setState(() => _photo = value);
      });
    }
  }

  void cancelInteraction() {
    _hold.reset();
    _pressed = _drag = null;
    _dragPosition = _down = null;
    _committed = false;
    _moved = false;
    if (mounted) setState(() {});
  }

  void resetView() => setState(() {
    _zoom = 1;
    _pan = Offset.zero;
  });
  void changeZoom(double delta) => setState(() {
    _zoom = (_zoom + delta).clamp(1, 2.8);
    _limitPan();
  });
  void _limitPan() {
    final x = _viewport.width * (_zoom - 1) * .65,
        y = _viewport.height * (_zoom - 1) * .65;
    _pan = Offset(_pan.dx.clamp(-x, x), _pan.dy.clamp(-y, y));
  }

  void _pointerDown(PointerDownEvent e) {
    _pointers.add(e.pointer);
    if (_pointers.length > 1) {
      cancelInteraction();
      return;
    }
    _down = e.localPosition;
    _committed = false;
    _moved = false;
    final p = _painter.fromLocal(e.localPosition, _viewport);
    _pressed = _geometry.hit(
      p,
      widget.session,
      _painter.fit(_viewport) * _zoom,
    );
    if (_pressed != null) {
      _dragAnchor = p - _geometry.rect(_pressed!, widget.session).center;
    }
    final step = widget.session.current;
    if (step != null &&
        step.gesture == RepairGesture.hold &&
        step.targets.contains(_pressed) &&
        !widget.session.targetDone(_pressed!) &&
        widget.session.tool == step.tool) {
      _hold.duration = Duration(
        milliseconds:
            widget.session.heatingStep
                ? RepairSession.heatDurationMs
                : RepairSession.holdDurationMs,
      );
      _hold.forward(from: 0);
    }
    setState(() {});
  }

  void _pointerMove(PointerMoveEvent e) {
    if (_pointers.length != 1 || _down == null) return;
    final distance = (e.localPosition - _down!).distance;
    if (distance > 12) {
      _moved = true;
      _hold.reset();
    }
    final step = widget.session.current;
    if (distance > 6 &&
        _pressed != null &&
        step?.gesture == RepairGesture.drag &&
        step!.targets.contains(_pressed)) {
      setState(() {
        _drag = _pressed;
        _dragPosition =
            _painter.fromLocal(e.localPosition, _viewport) - _dragAnchor;
      });
    } else if (_pressed == null && _zoom > 1) {
      setState(() {
        _pan += e.delta;
        _limitPan();
      });
    }
  }

  void _pointerUp(PointerUpEvent e) {
    final target = _pressed;
    if (!_moved &&
        !_committed &&
        target == 'screen' &&
        widget.session.tool == RepairTool.hand &&
        !widget.session.isOpen &&
        widget.onInspect != null) {
      _pointers.remove(e.pointer);
      cancelInteraction();
      widget.onInspect!();
      return;
    }
    if (_pointers.length == 1 && !_committed && target != null) {
      if (widget.session.heatingStep && !_moved && _hold.value > 0) {
        widget.onAction(
          target,
          RepairGesture.hold,
          heldMs: (_hold.value * RepairSession.heatDurationMs).round(),
        );
      } else if (_drag != null && _dragPosition != null) {
        widget.onAction(
          target,
          RepairGesture.drag,
          destination: _geometry.dropZone(_dragPosition!, widget.session),
        );
      } else if (!_moved) {
        widget.onAction(target, RepairGesture.tap);
      }
    }
    _pointers.remove(e.pointer);
    if (_pointers.isEmpty) {
      _pinching = false;
      cancelInteraction();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = c.biggest;
      if (_viewport != size) {
        _viewport = size;
        _pan = Offset.zero;
        _zoom = 1;
      }
      _geometry = WorkbenchGeometry(
        size.width / size.height > 1.16,
        device: widget.session.device,
      );
      return Semantics(
        label:
            '${rt('r_workbench')}. ${widget.session.current == null ? '' : rt(widget.session.current!.hintKey)}',
        child: MouseRegion(
          cursor:
              _drag == null
                  ? SystemMouseCursors.precise
                  : SystemMouseCursors.grabbing,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: (e) {
              _pointers.remove(e.pointer);
              cancelInteraction();
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleUpdate: (d) {
                if (d.pointerCount < 2) return;
                if (!_pinching) {
                  _pinchScene = _painter.fromLocal(
                    d.localFocalPoint,
                    _viewport,
                  );
                  _pinchStart = _zoom;
                  _pinching = true;
                }
                setState(() {
                  _zoom = (_pinchStart * d.scale).clamp(1, 2.8);
                  _pan =
                      d.localFocalPoint -
                      _viewport.center(Offset.zero) -
                      (_pinchScene - _geometry.size.center(Offset.zero)) *
                          (_painter.fit(_viewport) * _zoom);
                  _limitPan();
                });
              },
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _hold]),
                  builder:
                      (context, _) =>
                          CustomPaint(painter: _painter, size: c.biggest),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
