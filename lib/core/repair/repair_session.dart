import 'device_profile.dart';

/// Deterministic repair rules. The scene sends physical actions, never a
/// "complete step" command. No Flutter dependency: saves and rules are portable.
enum RepairTool {
  hand,
  driver,
  heater,
  suction,
  spudger,
  tweezers,
  meter,
  solvent,
}

enum RepairGesture { tap, drag, hold }

enum RepairOutcome { accepted, mistake, ignored, blocked }

class RepairResult {
  final RepairOutcome outcome;
  final String message;
  const RepairResult(this.outcome, this.message);
  bool get accepted => outcome == RepairOutcome.accepted;
}

class RepairStep {
  final String id;
  final RepairTool tool;
  final RepairGesture gesture;
  final List<String> targets;
  final String? destination;
  final int turns;
  final String? caption;
  const RepairStep(
    this.id,
    this.tool,
    this.gesture,
    this.targets, {
    this.destination,
    this.turns = 1,
    this.caption,
  });
  String get titleKey => 'r_step_${caption ?? id}';
  String get hintKey => 'r_hint_${caption ?? id}';
}

bool supportsWorkbench(String device) {
  final d = device.toLowerCase();
  return d.contains('iphone') || d.contains('galaxy') || d.contains('pixel');
}

List<RepairStep> repairRecipe(String service, [String device = 'iphone13']) {
  final profile = profileFor(device);
  final shieldTargets = List.generate(profile.shieldScrews, (i) => 'shield_$i');
  final cableTargets = [
    'part_connector',
    if (profile.rearAccess && (service == 'port' || service == 'battery'))
      'interconnect_1',
  ];
  const test = RepairStep('test', RepairTool.meter, RepairGesture.hold, [
    'test_screen',
    'test_camera',
    'test_charge',
  ]);
  if (service == 'diag') return [test];
  final part =
      service == 'display'
          ? (profile.rearAccess ? 'front_display' : 'screen')
          : service;
  return [
    const RepairStep('diagnose', RepairTool.meter, RepairGesture.hold, [
      'screen',
    ]),
    const RepairStep('power_off', RepairTool.hand, RepairGesture.hold, [
      'power',
    ]),
    if (profile.frameScrews)
      const RepairStep('frame_out', RepairTool.driver, RepairGesture.tap, [
        'frame_0',
        'frame_1',
      ], turns: 3),
    const RepairStep('heat', RepairTool.heater, RepairGesture.hold, ['screen']),
    RepairStep(
      'open',
      RepairTool.suction,
      RepairGesture.drag,
      ['screen'],
      destination: 'display_park',
      caption: profile.rearAccess ? 'open_back' : null,
    ),
    RepairStep(
      'shield_screws_out',
      RepairTool.driver,
      RepairGesture.tap,
      shieldTargets,
      turns: 3,
    ),
    const RepairStep('shield_out', RepairTool.tweezers, RepairGesture.drag, [
      'shield',
    ], destination: 'parts_tray'),
    const RepairStep('battery_off', RepairTool.spudger, RepairGesture.tap, [
      'battery_connector',
    ]),
    RepairStep('part_off', RepairTool.spudger, RepairGesture.tap, cableTargets),
    if (profile.rearAccess && service == 'display') ...[
      const RepairStep('flip_front', RepairTool.hand, RepairGesture.tap, [
        'chassis',
      ]),
      const RepairStep('display_heat', RepairTool.heater, RepairGesture.hold, [
        'front_display',
      ]),
    ],
    if (service == 'battery')
      RepairStep(
        'adhesive_out',
        profile.adhesiveTabs == 0 ? RepairTool.solvent : RepairTool.tweezers,
        profile.adhesiveTabs == 0 ? RepairGesture.hold : RepairGesture.drag,
        profile.adhesiveTabs == 0
            ? ['adhesive_edge']
            : List.generate(profile.adhesiveTabs, (i) => 'adhesive_$i'),
        destination: profile.adhesiveTabs == 0 ? null : 'parts_tray',
        caption:
            profile.adhesiveTabs == 0
                ? 'adhesive_soften'
                : profile.rearAccess
                ? 'adhesive_handle'
                : null,
      ),
    if (service == 'camera' || service == 'port')
      RepairStep(
        'part_screws_out',
        RepairTool.driver,
        RepairGesture.tap,
        service == 'port'
            ? ['part_0', 'part_1', 'part_2']
            : ['part_0', 'part_1'],
        turns: 3,
      ),
    RepairStep('part_out', RepairTool.tweezers, RepairGesture.drag, [
      part,
    ], destination: 'old_tray'),
    RepairStep(
      'part_in',
      RepairTool.tweezers,
      RepairGesture.drag,
      ['new_part'],
      destination:
          service == 'display'
              ? (profile.rearAccess ? 'display_mount' : 'display_park')
              : part,
    ),
    if (service == 'camera' || service == 'port')
      RepairStep(
        'part_screws_in',
        RepairTool.driver,
        RepairGesture.tap,
        service == 'port'
            ? ['part_0', 'part_1', 'part_2']
            : ['part_0', 'part_1'],
        turns: 3,
      ),
    if (service == 'battery')
      const RepairStep('adhesive_in', RepairTool.hand, RepairGesture.hold, [
        'battery',
      ]),
    if (profile.rearAccess && service == 'display')
      const RepairStep('flip_back', RepairTool.hand, RepairGesture.tap, [
        'chassis',
      ]),
    RepairStep('part_on', RepairTool.spudger, RepairGesture.tap, cableTargets),
    const RepairStep('battery_on', RepairTool.spudger, RepairGesture.tap, [
      'battery_connector',
    ]),
    const RepairStep('shield_in', RepairTool.tweezers, RepairGesture.drag, [
      'stored_shield',
    ], destination: 'shield'),
    RepairStep(
      'shield_screws_in',
      RepairTool.driver,
      RepairGesture.tap,
      shieldTargets,
      turns: 3,
    ),
    RepairStep(
      'close',
      RepairTool.suction,
      RepairGesture.drag,
      ['screen'],
      destination: 'chassis',
      caption: profile.rearAccess ? 'close_back' : null,
    ),
    const RepairStep('seal', RepairTool.hand, RepairGesture.hold, ['screen']),
    if (profile.frameScrews)
      const RepairStep('frame_in', RepairTool.driver, RepairGesture.tap, [
        'frame_0',
        'frame_1',
      ], turns: 3),
    test,
  ];
}

class RepairSession {
  static const int schemaVersion = 2;
  static const String practiceId = '__practice__';
  static const int holdDurationMs = 1200;
  final String orderId;
  final String service;
  final String device;
  final bool training;
  late final List<RepairStep> steps = repairRecipe(service, device);
  int _index = 0;
  int mistakes = 0;
  final Map<String, int> _turns = {};
  RepairTool tool = RepairTool.hand;
  bool hints = true;
  bool partConsumed = false;
  double? reward;

  RepairSession(
    this.orderId,
    this.service, {
    this.training = false,
    this.device = 'iphone13',
  });

  int get index => _index;
  bool get finished => _index == steps.length;
  RepairStep? get current => finished ? null : steps[_index];
  double get progress =>
      finished
          ? 1
          : (_index +
                  _turns.values.fold<int>(0, (a, b) => a + b) /
                      (current!.targets.length * current!.turns)) /
              steps.length;
  bool done(String id) => steps.take(_index).any((s) => s.id == id);
  bool get frontFacing =>
      profileFor(device).rearAccess &&
      service == 'display' &&
      done('flip_front') &&
      !done('flip_back');
  bool get isOpen => done('open') && !done('close');
  bool get shieldRemoved => done('shield_out') && !done('shield_in');
  bool get batteryDisconnected => done('battery_off') && !done('battery_on');
  bool get partRemoved => done('part_out') && !done('part_in');
  bool get newPartInstalled => done('part_in');
  bool get powered => !done('power_off') || current?.id == 'test' || finished;
  int turnsFor(String target) => _turns[target] ?? 0;
  bool targetDone(String target) => turnsFor(target) >= (current?.turns ?? 1);

  RepairResult act(
    String target,
    RepairGesture gesture, {
    String? destination,
    int heldMs = 0,
    bool hasPart = true,
  }) {
    final step = current;
    if (step == null) {
      return const RepairResult(RepairOutcome.ignored, 'r_already_done');
    }
    if (!step.targets.contains(target)) return _mistake('r_wrong_order');
    if (targetDone(target)) {
      return const RepairResult(RepairOutcome.ignored, 'r_target_done');
    }
    if (tool != step.tool) return _mistake('r_wrong_tool');
    if (gesture != step.gesture) {
      // A tap on a draggable/holdable part teaches the gesture without a fine.
      return RepairResult(
        RepairOutcome.blocked,
        'r_gesture_${step.gesture.name}',
      );
    }
    if (gesture == RepairGesture.drag && destination != step.destination) {
      return const RepairResult(RepairOutcome.blocked, 'r_wrong_drop');
    }
    if (gesture == RepairGesture.hold && heldMs < holdDurationMs) {
      return const RepairResult(RepairOutcome.blocked, 'r_gesture_hold');
    }
    if (step.id == 'part_in' && !training && !hasPart) {
      return const RepairResult(RepairOutcome.blocked, 'r_missing_part');
    }
    _turns[target] = turnsFor(target) + 1;
    if (step.targets.every(targetDone)) {
      _index++;
      _turns.clear();
      return RepairResult(
        RepairOutcome.accepted,
        finished ? 'finish_ok' : 'r_step_done',
      );
    }
    return const RepairResult(RepairOutcome.accepted, 'r_action_done');
  }

  RepairResult _mistake(String message) {
    mistakes++;
    return RepairResult(RepairOutcome.mistake, message);
  }

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'order': orderId,
    'service': service,
    'device': device,
    'step': current?.id,
    'training': training,
    'index': _index,
    'mistakes': mistakes,
    'turns': Map<String, int>.of(_turns),
    'tool': tool.name,
    'hints': hints,
    'consumed': partConsumed,
    'reward': reward,
  };

  factory RepairSession.fromJson(Map<String, dynamic> json) {
    if (!const [1, schemaVersion].contains(json['v']) ||
        !const [
          'display',
          'battery',
          'camera',
          'port',
          'diag',
        ].contains(json['service'])) {
      throw const FormatException('Unsupported repair session');
    }
    final session = RepairSession(
      json['order'] as String,
      json['service'] as String,
      training: json['training'] == true,
      device: json['device'] as String? ?? 'iphone13',
    );
    session._index =
        (json['index'] as int).clamp(0, session.steps.length).toInt();
    if (json['v'] == 1 && json['device'] != null) {
      final oldSteps = repairRecipe(session.service);
      final oldIndex = (json['index'] as int).clamp(0, oldSteps.length);
      final id = oldIndex == oldSteps.length ? null : oldSteps[oldIndex].id;
      final match = session.steps.indexWhere((s) => s.id == id);
      session._index =
          id == null ? session.steps.length : (match >= 0 ? match : 2);
    }
    session.mistakes = (json['mistakes'] as int? ?? 0).clamp(0, 100000).toInt();
    final turns = json['turns'];
    if (turns is Map && session.current != null) {
      for (final target in session.current!.targets) {
        final value = turns[target];
        if (value is int) {
          session._turns[target] =
              value.clamp(0, session.current!.turns).toInt();
        }
      }
    }
    session.tool = RepairTool.values.firstWhere(
      (t) => t.name == json['tool'],
      orElse: () => RepairTool.hand,
    );
    session.hints = json['hints'] != false;
    session.partConsumed = json['consumed'] == true;
    session.reward = (json['reward'] as num?)?.toDouble();
    return session;
  }
}
