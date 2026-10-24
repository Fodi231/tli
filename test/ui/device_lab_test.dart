import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/market/device_catalog.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/core/repair/device_runtime.dart';
import 'package:techlife/ui/repair/device_lab.dart';
import 'package:techlife/ui/repair/photo_anatomy.dart';
import 'market_phone_test.dart' show capture, phoneApp;
import '../core/repair_session_test.dart' show performStep;
import 'package:techlife/ui/shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  void size(WidgetTester t, Size s) {
    t.view.physicalSize = s;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  testWidgets(
    'iPhone swipe, controls, long power, slider, off, held start and delayed boot',
    (t) async {
      size(t, const Size(390, 844));
      I18n.lang = 'ru';
      final s = RepairSession('ui', 'battery');
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: DeviceLab(session: s, onChanged: () {}),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      await capture(t, key, 'preview/09_ios_lock.png');
      final screen = find.byKey(const ValueKey('device_screen'));
      final rect = t.getRect(screen);
      await t.dragFrom(
        Offset(rect.right - 20, rect.top + 10),
        const Offset(0, 140),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(s.runtime.page, DevicePage.controls);
      await t.tap(find.byKey(const ValueKey('os_wifi')));
      await t.pump();
      expect(s.runtime.wifi, false);
      await t.tap(find.byKey(const ValueKey('os_airplane')));
      await t.pump();
      expect(s.runtime.cellular, false);
      await capture(t, key, 'preview/09_ios_controls.png');
      await t.longPress(find.byKey(const ValueKey('controls_power')));
      await t.pump(const Duration(milliseconds: 300));
      expect(s.runtime.page, DevicePage.power);
      await capture(t, key, 'preview/09_ios_power.png');
      final slider = t.getRect(find.byKey(const ValueKey('shutdown_slider')));
      await t.dragFrom(
        Offset(slider.left + 20, slider.center.dy),
        Offset(slider.width - 30, 0),
      );
      await t.pump();
      expect(s.runtime.power, DevicePower.shuttingDown);
      await t.pump(const Duration(milliseconds: 2300));
      expect(s.runtime.power, DevicePower.off);
      await t.longPress(find.byKey(const ValueKey('device_boot')));
      await t.pump();
      expect(s.runtime.power, DevicePower.booting);
      await capture(t, key, 'preview/09_ios_boot.png');
      await t.pump(const Duration(seconds: 10));
      expect(s.runtime.power, DevicePower.booting);
      await t.pump(const Duration(seconds: 3));
      expect(s.runtime.power, DevicePower.on);
      expect(s.runtime.wifi, false);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'physical volume+side works and calculator photos notes are functional',
    (t) async {
      size(t, const Size(390, 844));
      final s = RepairSession('ui2', 'battery');
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: DeviceLab(session: s, onChanged: () {}),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      final a = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('hardware_up'))),
        pointer: 1,
      );
      final b = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('hardware_side'))),
        pointer: 2,
      );
      await t.pump(const Duration(milliseconds: 1000));
      await a.up();
      await b.up();
      await t.pump();
      expect(s.runtime.page, DevicePage.power);
      await t.tap(find.byKey(const ValueKey('device_home')));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(const ValueKey('os_app_calculator')));
      await t.pump(const Duration(milliseconds: 300));
      for (final x in ['8', '÷', '2', '=']) {
        await t.tap(find.byKey(ValueKey('calc_$x')));
        await t.pump();
      }
      expect(s.runtime.calculator, '4');
      await t.tap(find.byKey(const ValueKey('device_home')));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(const ValueKey('os_app_camera')));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(const ValueKey('camera_capture')));
      await t.pump();
      expect(s.runtime.photos, 1);
      await t.tap(find.byKey(const ValueKey('device_home')));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(const ValueKey('os_app_notes')));
      await t.pump(const Duration(milliseconds: 300));
      await t.enterText(
        find.byKey(const ValueKey('device_notes')),
        'Проверено',
      );
      expect(s.runtime.note, 'Проверено');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final model in deviceCatalog.where((d) => d.panels > 1)) {
    testWidgets(
      'fold stages animate and every built-in page fits ${model.id}',
      (t) async {
        size(t, const Size(390, 844));
        final s = RepairSession('fold', 'battery', device: model.id);
        final key = GlobalKey();
        await t.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: key,
              child: DeviceLab(session: s, onChanged: () {}),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 300));
        await capture(t, key, 'preview/09_${model.id}_folded.png');
        final before =
            t.getSize(find.byKey(const ValueKey('device_screen'))).width;
        await t.tap(find.byKey(const ValueKey('fold_button')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
        final mid =
            t.getSize(find.byKey(const ValueKey('device_screen'))).width;
        expect(mid, greaterThan(before));
        await t.pump(const Duration(milliseconds: 600));
        expect(s.runtime.foldStage, 1);
        if (model.panels == 3) {
          await t.tap(find.byKey(const ValueKey('fold_button')));
          await t.pump();
          await t.pump(const Duration(milliseconds: 900));
          expect(s.runtime.foldStage, 2);
        }
        await t.tap(find.byKey(const ValueKey('device_home')));
        await t.pump(const Duration(milliseconds: 300));
        await capture(t, key, 'preview/09_${model.id}_open.png');
        for (final page in DevicePage.values.where(
          (p) => p != DevicePage.lock && p != DevicePage.home,
        )) {
          s.runtime.open(page);
          await t.tap(find.byKey(const ValueKey('device_home')));
          s.runtime.open(page);
          await t.pump(const Duration(milliseconds: 300));
          expect(t.takeException(), isNull, reason: '${model.id} $page');
        }
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'capture photographed internals for every model from actual bench',
    (t) async {
      size(t, const Size(1200, 820));
      I18n.lang = 'ru';
      final gs = GameState()..forceOffline = true;
      final sh = Shell();
      final key = GlobalKey();
      for (final model in deviceCatalog) {
        await t.runAsync(() => PhotoAnatomy.load(model.id));
        final s = RepairSession(
          RepairSession.practiceId,
          'battery',
          device: model.id,
          training: true,
        );
        while (s.current!.id != 'battery_off') {
          performStep(s);
        }
        gs.repairs[RepairSession.practiceId] = s;
        sh.open('repair', arg: RepairSession.practiceId);
        await t.pumpWidget(phoneApp(gs, sh, boundary: key));
        await t.pump(const Duration(milliseconds: 500));
        await capture(t, key, 'preview/09_inside_${model.id}.png');
        expect(t.takeException(), isNull, reason: model.id);
        await t.pumpWidget(const SizedBox());
      }
      gs.dispose();
      sh.dispose();
    },
  );
}
