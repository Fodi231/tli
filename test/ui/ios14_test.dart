import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/main.dart';
import 'package:techlife/ui/onboarding.dart';
import 'package:techlife/ui/phone_shell.dart';
import 'package:techlife/ui/shell.dart';
import 'package:techlife/ui/system_notice.dart';
import 'package:techlife/ui/widgets.dart';
import 'market_phone_test.dart' show capture;

GameState state({
  bool fresh = false,
  String lang = 'ru',
  double scale = 1,
  int theme = 1,
}) {
  final g =
      GameState()
        ..forceOffline = true
        ..ready = true
        ..onboardingComplete = !fresh
        ..textScale = scale
        ..lang = lang
        ..themeMode = theme;
  I18n.lang = lang;
  g.player = LatLng(g.city.lat, g.city.lng);
  g.orders.add(
    Order(
      id: 'ios-test-order',
      device: 'iPhone 13',
      service: 'display',
      price: 145,
      lat: g.city.lat,
      lng: g.city.lng,
    ),
  );
  return g;
}

Widget app(GameState g, Shell sh, {GlobalKey? boundary}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<GameState>.value(value: g),
    ChangeNotifierProvider<Shell>.value(value: sh),
  ],
  child: RepaintBoundary(key: boundary, child: const TechLifeApp()),
);
void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> close(WidgetTester tester, GameState g, Shell sh) async {
  await tester.pumpWidget(const SizedBox());
  g.dispose();
  sh.dispose();
}

Future<void> capture14(WidgetTester tester, GlobalKey key, String path) async {
  final shadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(key.currentContext!.findRenderObject()!);
    await tester.pump();
    await capture(tester, key, path);
  } finally {
    debugDisableShadows = shadows;
    await tester.pump();
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  final scroll =
      find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first;
  for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
    var delta = -100.0;
    if (target.evaluate().isNotEmpty &&
        tester.getCenter(target).dy < tester.getTopLeft(scroll).dy + 20) {
      delta = 100;
    }
    await tester.drag(scroll, Offset(0, delta));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf')))
        .load();
    Directory('preview').createSync(recursive: true);
  });

  testWidgets('registration validates, back preserves input, then opens home', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final g = state(fresh: true);
    final sh = Shell();
    final key = GlobalKey();
    await tester.pumpWidget(app(g, sh, boundary: key));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await capture14(tester, key, 'preview/14_welcome.png');
    await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
    await tester.pump();
    expect(g.onboardingComplete, false);
    expect(find.text('Введи имя: минимум 2 символа'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('character_name')),
      '  Анна Ли  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_avatar_3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_back')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
    await tester.pump();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('character_name')))
          .controller!
          .text,
      '  Анна Ли  ',
    );
    await capture14(tester, key, 'preview/14_character.png');
    await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(g.playerName, 'Анна Ли');
    expect(g.avatarIndex, 3);
    expect(g.onboardingComplete, true);
    expect(g.balance, 1500);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester, g, sh);
  });

  for (final lang in ['ru', 'en', 'uk']) {
    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      testWidgets('first launch fits $lang $size at large text and keyboard', (
        tester,
      ) async {
        viewport(tester, size);
        final g = state(fresh: true, lang: lang, scale: 1.4);
        final sh = Shell();
        await tester.pumpWidget(app(g, sh));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byKey(const ValueKey('onboarding_scroll')),
          const Offset(0, -1800),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('character_name')),
          'Марія',
        );
        await tester.pump();
        tester.view.viewInsets = const FakeViewPadding(bottom: 210);
        await tester.pump();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await close(tester, g, sh);
      });
    }
  }

  for (final lang in ['ru', 'en', 'uk']) {
    for (final theme in [1, 2]) {
      testWidgets(
        'legacy apps and settings fit $lang theme $theme with 140% text',
        (tester) async {
          viewport(tester, const Size(320, 568));
          final g = state(lang: lang, scale: 1.4, theme: theme);
          final sh = Shell();
          g.notifications.add(
            AppNotification('money', 'n_pay', r'Покупка iPhone 13 · $110'),
          );
          await tester.pumpWidget(app(g, sh));
          await tester.pump();
          for (final id in [
            'work',
            'shop',
            'storage',
            'learning',
            'stats',
            'achievements',
            'mail',
            'staff',
            'calendar',
            'notifications',
            'settings',
          ]) {
            sh.open(id);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull, reason: '$id top');
            final scroll = find.byType(Scrollable);
            if (scroll.evaluate().isNotEmpty) {
              await tester.drag(scroll.first, const Offset(0, -1000));
              await tester.pump();
            }
            expect(tester.takeException(), isNull, reason: '$id scrolled');
          }
          // Each settings sub-page uses the same actual light/dark app theme.
          for (final title in [
            'appearance',
            'display',
            'profile',
            'language',
            'notifications',
            'sound_vibe',
            'ai_network',
            'data_saves',
            'about',
          ]) {
            sh.open('stats');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            sh.open('settings');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            final target = find.byKey(
              ValueKey(
                'settings_page_${title == 'sound_vibe'
                    ? 'sound'
                    : title == 'ai_network'
                    ? 'ai'
                    : title == 'data_saves'
                    ? 'data'
                    : title}',
              ),
            );
            tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position
                .jumpTo(0);
            await tester.pump();
            await reveal(tester, target);
            await tester.tap(target);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull, reason: '$title top');
            final scroll = find.byType(Scrollable);
            if (scroll.evaluate().isNotEmpty) {
              await tester.drag(scroll.first, const Offset(0, -1800));
              await tester.pump();
            }
            expect(tester.takeException(), isNull, reason: '$title scrolled');
          }
          await close(tester, g, sh);
        },
      );
    }
  }

  testWidgets(
    'glass setting removes blur and changes the rendered pixels immediately',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final g = state();
      final sh = Shell()..open('settings');
      final key = GlobalKey();
      await tester.pumpWidget(app(g, sh, boundary: key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await capture14(tester, key, 'preview/14_settings.png');
      await tester.tap(find.text('appearance'.tr));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final preview = find.byKey(const ValueKey('glass_live_preview'));
      await reveal(tester, preview);
      await tester.pump();
      expect(
        find.descendant(of: preview, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      await capture14(tester, key, 'preview/14_glass_on.png');
      await reveal(tester, find.byKey(const ValueKey('liquid_glass_switch')));
      await tester.tap(find.byKey(const ValueKey('liquid_glass_switch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(g.liquidGlass, false);
      expect(
        find.descendant(of: preview, matching: find.byType(BackdropFilter)),
        findsNothing,
      );
      await reveal(tester, preview);
      await tester.pump();
      await capture14(tester, key, 'preview/14_glass_off.png');
      final solid = tester.widget<Container>(
        find.descendant(
          of: preview,
          matching: find.byKey(const ValueKey('solid_material')),
        ),
      );
      expect((solid.decoration! as BoxDecoration).color!.a, 1);
      final on = File('preview/14_glass_on.png').readAsBytesSync();
      final off = File('preview/14_glass_off.png').readAsBytesSync();
      expect(on.length != off.length, true);
      expect(tester.takeException(), isNull);
      await close(tester, g, sh);
    },
  );

  testWidgets(
    'Luma failure uses a readable top banner and preserves bottom controls',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final g = state();
      g.openLumaCard('classic');
      final sh = Shell()..open('bank');
      final key = GlobalKey();
      await tester.pumpWidget(app(g, sh, boundary: key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final bankContext = tester.element(
        find.byKey(const ValueKey('luma_tab_0')),
      );
      const msg = 'Недостаточно средств, карта заморожена или превышен лимит.';
      g.balance = 100;
      await tester.tap(find.byKey(const ValueKey('luma_tab_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await reveal(tester, find.text('Страхование'));
      await tester.tap(find.text('Страхование'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Подтвердить'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(g.insured, false);
      expect(g.balance, 100);
      final label = find.byKey(const ValueKey('system_notice_text'));
      expect(find.text(msg), findsOneWidget);
      final color = tester.widget<Text>(label).style!.color!;
      final contrast =
          (color.computeLuminance() + .05) /
          (Colors.white.computeLuminance() + .05);
      expect(1 / contrast, greaterThan(4.5));
      expect(tester.getTopLeft(label).dy, lessThan(200));
      expect(
        tester.getBottomRight(find.byType(SystemNoticeBanner)).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('luma_tab_0'))).dy,
        ),
      );
      await capture14(tester, key, 'preview/14_luma_notice.png');
      toast(bankContext, 'Подключение работает');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(msg), findsNothing);
      expect(find.text('Подключение работает'), findsOneWidget);
      await tester.drag(find.byType(SystemNoticeBanner), const Offset(0, -150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SystemNoticeBanner), findsNothing);
      toast(bankContext, 'Готово');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      g.setLiquidGlass(false);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(SystemNoticeBanner),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SystemNoticeBanner), findsNothing);
      expect(tester.takeException(), isNull);
      await close(tester, g, sh);
    },
  );

  testWidgets(
    'native theme changes without a colour filter or losing app state',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final g = state();
      final sh = Shell()..open('shop');
      final key = GlobalKey();
      await tester.pumpWidget(app(g, sh, boundary: key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), 'iPhone');
      await tester.pump();
      g.setThemeMode(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text ??
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
        'iPhone',
      );
      expect(find.byType(ColorFiltered), findsNothing);
      await capture14(tester, key, 'preview/14_shop_dark.png');
      g.setThemeMode(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await capture14(tester, key, 'preview/14_shop_light.png');
      sh.open('stats');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await capture14(tester, key, 'preview/14_stats.png');
      expect(tester.takeException(), isNull);
      await close(tester, g, sh);
    },
  );
  testWidgets('old apps including the offline map fit landscape and desktop', (
    tester,
  ) async {
    for (final size in [const Size(844, 390), const Size(1366, 768)]) {
      viewport(tester, size);
      final g =
          state(scale: 1.4)
            ..mapStyle = 3
            ..layoutMode = 2;
      final sh = Shell();
      await tester.pumpWidget(app(g, sh));
      await tester.pump();
      for (final id in [
        'work',
        'shop',
        'storage',
        'learning',
        'stats',
        'achievements',
        'settings',
        'map',
        'notifications',
      ]) {
        sh.open(id);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: '$id $size');
      }
      await close(tester, g, sh);
    }
  });
  testWidgets(
    'reset character creation returns home instead of reopening settings',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final g = state();
      final sh = Shell()..open('settings');
      await tester.pumpWidget(app(g, sh));
      await tester.pump();
      await g.resetAll();
      await tester.pump();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('character_name')),
        'Второй мастер',
      );
      await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(sh.app, null);
      expect(sh.unlocked, true);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(g.balance, 1500);
      expect(tester.takeException(), isNull);
      await tester.pump(
        const Duration(seconds: 3),
      ); // Flush AppLog's debounced disk write.
      await close(tester, g, sh);
    },
  );
}
