import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/market/device_catalog.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/ui/market/marketplace_app.dart';
import 'package:techlife/ui/market/market_chat.dart';
import 'package:techlife/ui/phone/dynamic_island.dart';
import 'package:techlife/ui/phone_shell.dart';
import 'package:techlife/ui/repair/repair_bench.dart';
import 'package:techlife/ui/shell.dart';
import '../core/repair_session_test.dart' show performStep;

Widget phoneApp(
  GameState gs,
  Shell shell, {
  double scale = 1,
  GlobalKey? boundary,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<GameState>.value(value: gs),
    ChangeNotifierProvider<Shell>.value(value: shell),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
    ),
    builder:
        (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
    home: RepaintBoundary(key: boundary, child: const PhoneShell()),
  ),
);
Future<void> capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
  });
  await tester.pump(const Duration(milliseconds: 400));
  final render =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final img = await render.toImage(pixelRatio: 1.5);
    final bytes =
        (await img.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
    await File(path).writeAsBytes(bytes);
    img.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1366, 768),
  ]) {
    testWidgets(
      'phone lock home island and marketplace fit $size at 140% text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gs = GameState()..forceOffline = true;
        final shell = Shell();
        I18n.lang = 'ru';
        await tester.pumpWidget(phoneApp(gs, shell, scale: 1.4));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(LockScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        shell.unlock();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(DynamicIsland));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        shell.open('market');
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(MarketplaceApp), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.byKey(const ValueKey('market_search')),
          'iPhone 13',
        );
        await tester.pump();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        gs.dispose();
        shell.dispose();
      },
    );
  }
  testWidgets(
    'market search favorite contact and confirmed purchase use actual controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gs = GameState()..forceOffline = true;
      final shell = Shell()..open('market');
      I18n.lang = 'en';
      await tester.pumpWidget(phoneApp(gs, shell));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
        find.byKey(const ValueKey('market_search')),
        'iPhone 13',
      );
      await tester.pump();
      final card = find.byKey(const ValueKey('listing_m01'));
      await tester.ensureVisible(card);
      await tester.pump();
      await tester.tap(
        find.descendant(of: card, matching: find.byIcon(Icons.favorite_border)),
      );
      await tester.pump();
      expect(gs.favorites, contains('m01'));
      await tester.tap(card);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('contact_seller')));
      await tester.pump();
      expect(find.byType(MarketChat), findsOneWidget);
      await tester.enterText(find.byType(TextField), '195');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(gs.stock, isEmpty);
      expect(find.text('Buy · \$195'), findsOneWidget);
      await tester.tap(find.text('Buy · \$195'));
      await tester.pump();
      expect(gs.stock.single.name, 'iPhone 13');
      expect(gs.balance, 1305);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      gs.dispose();
      shell.dispose();
    },
  );
  testWidgets('capture real phone marketplace and model bench previews', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final gs = GameState()..forceOffline = true;
    final shell = Shell();
    final key = GlobalKey();
    I18n.lang = 'ru';
    await tester.pumpWidget(phoneApp(gs, shell, boundary: key));
    await tester.pump(const Duration(milliseconds: 500));
    await capture(tester, key, 'preview/phone_lock.png');
    shell.unlock();
    await tester.pump(const Duration(milliseconds: 500));
    await capture(tester, key, 'preview/phone_home.png');
    shell.open('market');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -160));
    await tester.pump();
    await capture(tester, key, 'preview/marketplace.png');
    final d = gs.openMarketDeal('m01')!;
    shell.open('messages', arg: d.id);
    await tester.pump(const Duration(milliseconds: 500));
    await gs.sendToDeal(d, 'У iPhone 13 есть дефекты?');
    await tester.pump();
    await capture(tester, key, 'preview/market_chat.png');
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = const Size(1100, 760);
    for (final model in deviceCatalog) {
      final session = RepairSession(
        RepairSession.practiceId,
        'battery',
        device: model.name,
        training: true,
      );
      while (session.current!.id != 'battery_off') {
        performStep(session);
      }
      gs.repairs[RepairSession.practiceId] = session;
      shell.open('repair', arg: RepairSession.practiceId);
      await tester.pumpWidget(phoneApp(gs, shell, boundary: key));
      await tester.pump(const Duration(milliseconds: 500));
      // The actual session, rendering and hit-test coordinates share the model.
      expect(find.byType(WorkbenchView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'preview/interior_${model.id}.png');
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    gs.dispose();
    shell.dispose();
  });
}
