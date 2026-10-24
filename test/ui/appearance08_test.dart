import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/core/wallpapers.dart';
import 'package:techlife/ui/liquid_surface.dart';
import 'package:techlife/ui/shell.dart';
import 'package:techlife/ui/widgets.dart';
import 'market_phone_test.dart' show phoneApp, capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });

  testWidgets(
    'home uses supplied market icon and four exact wallpaper assets',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gs = GameState()..forceOffline = true;
      final sh = Shell()..unlock();
      final key = GlobalKey();
      I18n.lang = 'ru';
      await tester.pumpWidget(phoneApp(gs, sh, boundary: key));
      for (final asset in bundledWallpapers.keys) {
        gs.setWallpaperAsset(asset);
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName == asset,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/icon/techmarket.png',
        ),
        findsWidgets,
      );
      await capture(tester, key, 'preview/08_home.png');
      sh.open('settings');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('appearance'.tr));
      await tester.pump();
      final toggle = find.byKey(const ValueKey('liquid_glass_switch'));
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.tap(toggle);
      await tester.pump();
      expect(gs.liquidGlass, isFalse);
      final thumb = find.byKey(const ValueKey('wallpaper_asset_0'));
      await tester.ensureVisible(thumb);
      await tester.pump();
      await tester.tap(thumb);
      await tester.pump();
      expect(gs.homeWp.asset, bundledWallpapers.keys.first);
      await capture(tester, key, 'preview/08_wallpapers.png');
      expect(tester.takeException(), isNull);
      sh.open('notifications');
      gs.notifications.insert(
        0,
        AppNotification('money', 'n_pay', r'Покупка iPhone 12 · $110'),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await capture(tester, key, 'preview/08_notifications.png');
      expect(find.text(r'Покупка iPhone 12 · $110'), findsOneWidget);
      await tester.tap(find.text(r'Покупка iPhone 12 · $110'));
      await tester.pump();
      expect(gs.notifications.first.read, isTrue);
      expect(sh.app, 'bank');
      await tester.pumpWidget(const SizedBox());
      gs.dispose();
      sh.dispose();
    },
  );

  for (final glass in [true, false]) {
    testWidgets('toast has readable colors and glass preference $glass', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gs = GameState()..liquidGlass = glass;
      final key = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gs,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: Builder(
                  builder:
                      (c) => Center(
                        child: FilledButton(
                          onPressed: () => toast(c, 'Подключение работает'),
                          child: const Text('Проверить'),
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Проверить'));
      await tester.pump(const Duration(milliseconds: 600));
      final bar = find.byKey(const ValueKey('system_toast'));
      final label = find.descendant(
        of: bar,
        matching: find.text('Подключение работает'),
      );
      expect(label, findsOneWidget);
      expect(tester.widget<Text>(label).style!.color, const Color(0xFF10283C));
      expect(
        find.descendant(of: bar, matching: find.byType(LiquidSurface)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.byType(BackdropFilter)),
        glass ? findsOneWidget : findsNothing,
      );
      await capture(
        tester,
        key,
        glass ? 'preview/08_toast_glass.png' : 'preview/08_toast_solid.png',
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      gs.dispose();
    });
  }
}
