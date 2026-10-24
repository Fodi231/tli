import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/ui/market/market_chat.dart';
import 'package:techlife/ui/shell.dart';
import 'market_phone_test.dart' show phoneApp, capture;

StockItem owned(String id) =>
    StockItem(id, 'iPhone 13', 195, 420, deviceId: 'iphone13', repaired: true);

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
      testWidgets('all five market tabs fit $size in $lang with 140% text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gs = GameState()..forceOffline = true;
        gs.stock.add(owned('s1'));
        gs.toggleFavorite('m01');
        gs.openMarketDeal('m02');
        final shell = Shell()..open('market');
        I18n.lang = lang;
        await tester.pumpWidget(phoneApp(gs, shell, scale: 1.4));
        await tester.pump(const Duration(milliseconds: 500));
        for (var tab = 0; tab < 5; tab++) {
          await tester.tap(find.byKey(ValueKey('market_tab_$tab')));
          await tester.pump(const Duration(milliseconds: 220));
          expect(tester.takeException(), isNull, reason: 'top of tab $tab');
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -1400),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'bottom of tab $tab');
        }
        await tester.pumpWidget(const SizedBox());
        gs.dispose();
        shell.dispose();
      });
    }
  }
  testWidgets(
    'draft can be resumed and sold only after explicit confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gs = GameState()..forceOffline = true;
      gs.stock.add(owned('s1'));
      final shell = Shell()..open('market');
      I18n.lang = 'en';
      await tester.pumpWidget(phoneApp(gs, shell));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('market_tab_2')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('listing_title')));
      await tester.enterText(
        find.byKey(const ValueKey('listing_title')),
        'Restored iPhone 13',
      );
      await tester.enterText(
        find.byKey(const ValueKey('listing_description')),
        'Display replaced, tested.',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('listing_price')));
      await tester.enterText(
        find.byKey(const ValueKey('listing_price')),
        '410',
      );
      expect(gs.marketDrafts['s1']!.price, '410');
      expect(gs.playerListings, isEmpty);
      expect(gs.balance, 1500);
      await tester.ensureVisible(
        find.byKey(const ValueKey('save_listing_draft')),
      );
      await tester.tap(find.byKey(const ValueKey('save_listing_draft')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('profile_drafts')));
      await tester.tap(find.byKey(const ValueKey('profile_drafts')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('draft_s1')));
      await tester.tap(find.byKey(const ValueKey('draft_s1')));
      await tester.pump();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('listing_title')))
            .controller!
            .text,
        'Restored iPhone 13',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('publish_listing')));
      await tester.tap(find.byKey(const ValueKey('publish_listing')));
      await tester.pump();
      expect(find.byType(MarketChat), findsOneWidget);
      expect(gs.marketDrafts, isEmpty);
      expect(gs.balance, 1500);
      expect(gs.stock, hasLength(1));
      expect(gs.playerListings.single.title, 'Restored iPhone 13');
      await tester.enterText(
        find.byKey(const ValueKey('market_message_input')),
        '410',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(gs.balance, 1500);
      expect(find.text('Sell · \$410'), findsOneWidget);
      await tester.tap(find.text('Sell · \$410'));
      await tester.pump();
      expect(gs.balance, 1910);
      expect(gs.stock, isEmpty);
      expect(gs.playerListings.single.status, 'sold');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      gs.dispose();
      shell.dispose();
    },
  );
  testWidgets('price filter applies to the real catalog', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gs = GameState()..forceOffline = true;
    final shell = Shell()..open('market');
    I18n.lang = 'en';
    await tester.pumpWidget(phoneApp(gs, shell));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('market_filters')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const ValueKey('market_min_price')),
      '400',
    );
    await tester.enterText(
      find.byKey(const ValueKey('market_max_price')),
      '500',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('apply_market_filters')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('apply_market_filters')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('apply_market_filters')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pump();
    expect(find.byKey(const ValueKey('listing_m02')), findsOneWidget);
    expect(find.byKey(const ValueKey('listing_m01')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    gs.dispose();
    shell.dispose();
  });
  testWidgets('landscape chat stays usable with a software keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final gs = GameState()..forceOffline = true;
    final d = gs.openMarketDeal('m01')!;
    final shell = Shell()..open('messages', arg: d.id);
    I18n.lang = 'uk';
    await tester.pumpWidget(phoneApp(gs, shell, scale: 1.4));
    await tester.pump(const Duration(milliseconds: 500));
    tester.view.viewInsets = const FakeViewPadding(bottom: 230);
    await tester.pump();
    expect(find.byKey(const ValueKey('market_message_input')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('market_message_input')),
      '190',
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(d.status, 'agreed');
    expect(gs.balance, 1500);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    gs.dispose();
    shell.dispose();
  });
  testWidgets('capture all five redesigned tabs from Flutter widgets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gs = GameState()..forceOffline = true;
    I18n.lang = 'ru';
    gs.stock.add(owned('sample'));
    for (final id in ['m01', 'm02', 'm03']) {
      gs.toggleFavorite(id);
      gs.openMarketDeal(id);
    }
    final shell = Shell()..open('market');
    I18n.lang = 'ru';
    final key = GlobalKey();
    await tester.pumpWidget(phoneApp(gs, shell, boundary: key));
    await tester.pump(const Duration(milliseconds: 500));
    const names = ['catalog', 'favorites', 'sell', 'messages', 'profile'];
    for (var tab = 0; tab < 5; tab++) {
      await tester.tap(find.byKey(ValueKey('market_tab_$tab')));
      await tester.pump(const Duration(milliseconds: 300));
      await capture(tester, key, 'preview/techmarket_${names[tab]}.png');
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    gs.dispose();
    shell.dispose();
  });
}
