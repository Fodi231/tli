import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/ui/market/market_chat.dart';

void main() {
  testWidgets(
    'natural agreement shows a purchase button at the authoritative price',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      I18n.lang = 'ru';
      final gs = GameState()..forceOffline = true;
      final d = Deal(
        id: 'ui-consistent',
        kind: 'buy',
        item: 'iPhone Duo',
        counterpart: 'Роман',
        market: 1700,
        ask: 920,
        limit: 700,
        deviceId: 'iphoneduo',
        fault: 'display',
      );
      gs.deals.add(d);
      await gs.sendToDeal(d, 'давай 600');
      await gs.sendToDeal(d, 'ну давай 650');
      await gs.sendToDeal(d, 'ладно давай');
      await t.pumpWidget(
        ChangeNotifierProvider<GameState>.value(
          value: gs,
          child: MaterialApp(
            home: Scaffold(body: MarketChat(deal: d, onBack: () {})),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Купить'), findsOneWidget);
      final button = find.widgetWithText(FilledButton, 'Купить · \$775');
      expect(button, findsOneWidget);
      await t.tap(button);
      await t.pump(const Duration(milliseconds: 300));
      expect(d.status, 'won');
      expect(gs.balance, 725);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      gs.dispose();
    },
  );
}
