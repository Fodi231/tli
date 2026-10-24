import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/core/repair/device_runtime.dart';
import 'package:techlife/ui/repair/device_lab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  testWidgets('export actual tri-fold animation frames', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.runAsync(
      () => Directory('build/fold_frames').create(recursive: true),
    );
    I18n.lang = 'ru';
    final s = RepairSession('preview', 'battery', device: 'matext');
    s.runtime.page = DevicePage.home;
    final key = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: DeviceLab(session: s, onChanged: () {}),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 500));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await t.pump();
    int n = 0;
    Future<void> frame() async {
      await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes =
            (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
        await File(
          'build/fold_frames/f${n.toString().padLeft(2, '0')}.png',
        ).writeAsBytes(bytes);
        image.dispose();
        n++;
      });
    }

    for (var i = 0; i < 5; i++) {
      await frame();
    }
    for (var stage = 1; stage <= 2; stage++) {
      await t.tap(find.byKey(const ValueKey('fold_button')));
      await t.pump();
      for (var i = 0; i < 11; i++) {
        await t.pump(const Duration(milliseconds: 85));
        await frame();
        expect(t.takeException(), isNull);
      }
      expect(s.runtime.foldStage, stage);
      for (var i = 0; i < 4; i++) {
        await frame();
      }
    }
    await t.pumpWidget(const SizedBox());
  });
}
