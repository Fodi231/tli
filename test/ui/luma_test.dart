import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import '../ui/market_phone_test.dart' show phoneApp, capture;
import 'package:techlife/ui/shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  for (final lang in ['ru', 'en', 'uk']) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(1366, 768),
    ]) {
      testWidgets('Luma tabs fit $lang $size with 140% text', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final g = GameState()..forceOffline = true;
        g.openLumaCard('classic');
        g.createLumaGoal('Equipment', 3000);
        g.moveLumaGoal(g.luma.goals.single.id, 200);
        g.openLumaBusiness();
        final shell = Shell()..open('bank');
        I18n.lang = lang;
        await tester.pumpWidget(phoneApp(g, shell, scale: 1.4));
        await tester.pump(const Duration(milliseconds: 500));
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.byKey(ValueKey('luma_tab_$i')));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), null, reason: 'tab $i top');
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -1600),
          );
          await tester.pump();
          expect(tester.takeException(), null, reason: 'tab $i bottom');
        }
        await tester.pumpWidget(const SizedBox());
        g.dispose();
        shell.dispose();
      });
    }
  }
  testWidgets('Luma preview and real opening flow', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final g = GameState()..forceOffline = true;
    final shell = Shell()..open('bank');
    I18n.lang = 'ru';
    final boundary = GlobalKey();
    await tester.pumpWidget(phoneApp(g, shell, boundary: boundary));
    await tester.pump(const Duration(milliseconds: 500));
    Directory('preview').createSync(recursive: true);
    await capture(tester, boundary, 'preview/luma_welcome.png');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('Открыть карту бесплатно'));
    await tester.tap(find.text('Открыть карту бесплатно'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(g.luma.opened, true);
    expect(g.balance, 1500);
    expect(tester.takeException(), null);
    g.playerName = 'ALEX MORGAN';
    g.createLumaGoal('Новое оборудование', 3000);
    g.moveLumaGoal(g.luma.goals.single.id, 300);
    g.moveLumaBusiness(200);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(ValueKey('luma_tab_$i')));
      await tester.pump(const Duration(milliseconds: 300));
      await capture(tester, boundary, 'preview/luma_tab_$i.png');
      expect(tester.takeException(), null);
    }
    await tester.tap(find.byKey(const ValueKey('luma_tab_0')));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
    await tester.pump();
    await tester.ensureVisible(find.text('Изменить дизайн'));
    await tester.tap(find.text('Изменить дизайн'));
    await tester.pump();
    await capture(tester, boundary, 'preview/luma_designs.png');
    expect(tester.takeException(), null);
    await tester.tap(find.byKey(const ValueKey('luma_style_aurora')));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pump();
    await tester.ensureVisible(find.text('Купить за \$ 25'));
    await tester.tap(find.text('Купить за \$ 25'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(g.balance, 1000);
    await tester.tap(find.text('Подтвердить'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(g.balance, 975);
    expect(g.luma.style, 'aurora');
    await tester.pumpWidget(const SizedBox());
    g.dispose();
    shell.dispose();
  });
}
