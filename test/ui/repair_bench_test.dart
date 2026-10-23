import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/ui/repair/repair_bench.dart';
import 'package:techlife/ui/repair/workbench_geometry.dart';
import 'package:techlife/ui/shell.dart';

void doStep(RepairSession s) {
  final step = s.current!;
  s.tool = step.tool;
  for (final target in step.targets) {
    while (s.current?.id == step.id && !s.targetDone(target)) {
      s.act(target, step.gesture, destination: step.destination, heldMs: 1200);
    }
  }
}

Widget benchApp(GameState gs, {GlobalKey? boundary, double textScale = 1}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: gs),
        ChangeNotifierProvider(create: (_) => Shell()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          textTheme: ThemeData.dark(
            useMaterial3: true,
          ).textTheme.apply(fontFamily: 'Roboto'),
        ),
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
        home: RepaintBoundary(
          key: boundary,
          child: const Scaffold(
            body: RepairBench(orderId: RepairSession.practiceId),
          ),
        ),
      ),
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  for (final dimensions in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1366, 768),
    const Size(320, 568),
  ]) {
    testWidgets('workbench fits $dimensions with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = dimensions;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gs = GameState();
      I18n.lang = 'uk';
      await tester.pumpWidget(benchApp(gs, textScale: 1.4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(WorkbenchView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      gs.dispose();
    });
  }
  testWidgets(
    'real pointer hold completes diagnosis and drag opens the device',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gs = GameState();
      I18n.lang = 'en';
      await tester.pumpWidget(benchApp(gs));
      await tester.pump();
      final s = gs.repairs[RepairSession.practiceId]!;
      final view = find.byType(WorkbenchView);
      Offset target(String id) {
        final size = tester.getSize(view);
        final g = WorkbenchGeometry(size.width / size.height > 1.16);
        final scale = math.min(
          size.width / g.size.width,
          size.height / g.size.height,
        );
        return tester.getTopLeft(view) +
            size.center(Offset.zero) +
            (g.rect(id, s).center - g.size.center(Offset.zero)) * scale;
      }

      gs.selectRepairTool(s.orderId, RepairTool.meter);
      await tester.pump();
      final pointer = await tester.startGesture(target('screen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(s.current!.id, 'diagnose');
      await tester.pump(const Duration(milliseconds: 650));
      await pointer.up();
      await tester.pump();
      expect(s.current!.id, 'power_off');
      while (s.current!.id != 'open') {
        doStep(s);
      }
      gs.selectRepairTool(s.orderId, RepairTool.suction);
      await tester.pump();
      final from = target('screen'), to = target('display_park');
      await tester.dragFrom(from, to - from);
      await tester.pump();
      expect(s.isOpen, isTrue);
      expect(s.mistakes, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      gs.dispose();
    },
  );
  testWidgets('capture real desktop and mobile workbench previews', (
    tester,
  ) async {
    final gs = GameState();
    I18n.lang = 'uk';
    final s = gs.startWorkbench(RepairSession.practiceId)!;
    while (s.current!.id != 'battery_off') {
      doStep(s);
    }
    s.tool = RepairTool.spudger;
    final boundary = GlobalKey();
    for (final entry
        in {
          'desktop': const Size(1366, 768),
          'mobile': const Size(390, 844),
        }.entries) {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(benchApp(gs, boundary: boundary));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('tool_spudger')).hitTestable(),
        findsOneWidget,
      );
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1.5);
        final bytes =
            (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
        final file = File('preview/repair_${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpWidget(const SizedBox());
    gs.dispose();
  });
}
