import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/market/device_catalog.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/ui/repair/photo_anatomy.dart';
import 'package:techlife/ui/repair/repair_bench.dart';
import 'package:techlife/ui/repair/workbench_geometry.dart';
import 'package:techlife/ui/shell.dart';
import 'market_phone_test.dart' show phoneApp, capture;
import '../core/repair_session_test.dart' show advanceTo, performStep;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  testWidgets('all ten generated atlases have independent removable layers', (
    t,
  ) async {
    for (final model in deviceCatalog) {
      final photo = await t.runAsync(() => PhotoAnatomy.load(model.id));
      expect(photo!.spec.separateParts, true);
      expect(photo.spec.asset, 'assets/repair/generated/${model.id}.png');
      for (final type in [
        'rear_cover',
        'front',
        'display_back',
        'battery',
        'camera',
        'shield',
        'port',
        'cover_inside',
      ]) {
        expect(
          photo.spec.sprites.containsKey(type),
          true,
          reason: '${model.id} $type',
        );
        final r = photo.spec.sprites[type]!;
        expect(r.width, greaterThan(0));
        expect(r.height, greaterThan(0));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(1));
        if (type != 'rear_cover') {
          expect(
            r.overlaps(photo.spec.sprites['chassis']!),
            false,
            reason: 'Baked $type in ${model.id}',
          );
        }
      }
      if (model.panels > 1) {
        expect(photo.spec.sprites.containsKey('aux_battery_0'), true);
      }
      if (model.panels == 3) {
        expect(photo.spec.sprites.containsKey('aux_battery_1'), true);
      }
    }
  });
  testWidgets(
    'Mate XT only turns over on the hand action, with animated frames',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final g = GameState()..forceOffline = true;
      final shell = Shell()..open('repair', arg: RepairSession.practiceId);
      final key = GlobalKey();
      I18n.lang = 'ru';
      final s = RepairSession(
        RepairSession.practiceId,
        'display',
        device: 'matext',
        training: true,
      );
      advanceTo(s, 'power_off');
      performStep(s);
      g.repairs[s.orderId] = s;
      await t.runAsync(() => PhotoAnatomy.load('matext'));
      await t.pumpWidget(phoneApp(g, shell, boundary: key));
      await t.pump(const Duration(milliseconds: 300));
      expect(s.current!.id, 'flip_rear');
      expect(s.rearSideUp, false);
      expect(s.powered, false);
      await capture(t, key, 'preview/13_matext_front_off.png');
      final view = find.byType(WorkbenchView),
          v = t.getSize(find.byType(WorkbenchView));
      final geo = WorkbenchGeometry(
        v.width / v.height > 1.16,
        device: 'matext',
      );
      final scale = math.min(
        v.width / geo.size.width,
        v.height / geo.size.height,
      );
      final point =
          t.getTopLeft(view) +
          v.center(Offset.zero) +
          (geo.rect('chassis', s).center - geo.size.center(Offset.zero)) *
              scale;
      await t.tapAt(point);
      await t.pump();
      await t.pump(const Duration(milliseconds: 180));
      expect(s.rearSideUp, true);
      await t.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'preview/13_matext_flip_mid.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
      await t.pump(const Duration(milliseconds: 550));
      await capture(t, key, 'preview/13_matext_rear.png');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      g.dispose();
      shell.dispose();
    },
  );
}
