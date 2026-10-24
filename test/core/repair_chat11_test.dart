import 'dart:convert';
import 'package:techlife/core/repair/device_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techlife/core/ai_service.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/core/market/chat_intent.dart';

void main() {
  test(
    'hinge footprint stays narrow until edge-on, then opens to full width',
    () {
      expect(projectedFoldWidth(0, 200), closeTo(200, .001));
      expect(projectedFoldWidth(.25, 200), closeTo(200, .001));
      expect(projectedFoldWidth(.5, 200), closeTo(200, .001));
      expect(projectedFoldWidth(.75, 200), inExclusiveRange(200, 400));
      expect(projectedFoldWidth(1, 200), closeTo(400, .001));
      expect(projectedFoldWidth(2, 200), closeTo(600, .001));
    },
  );
  tearDown(() => AiService.client = http.Client());
  test('colloquial offers and agreement are negotiation, not free chat', () {
    expect(chatPrice('давай 600'), 600);
    expect(chatPrice('ну давай 650'), 650);
    expect(acceptsCounter('ладно давай'), isTrue);
    expect(chatPrice('iPhone 13 128 ГБ'), isNull);
    expect(acceptsCounter('Да?'), isFalse);
  });
  test(
    'AI cannot change listing or negotiated price; agreement unlocks payment',
    () async {
      I18n.lang = 'ru';
      AiService.resume();
      AiService.managedEnabled = false;
      AiService.customUrl = '';
      AiService.googleEndpoint = 'gemini';
      final gs = GameState()..geminiKey = 'AIza_test';
      addTearDown(gs.dispose);
      AiService.client = MockClient(
        (r) async => http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Отдам за \$800. Адрес скинуть?'},
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      final d = Deal(
        id: 'consistent',
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
      await gs.sendToDeal(d, 'что продаешь за сколько какое состояние');
      expect(d.messages.last.text, contains(r'$920'));
      expect(d.price, 0);
      await gs.sendToDeal(d, 'давай 600');
      expect(d.counterPrice, 775);
      expect(d.messages.last.text, contains(r'$775'));
      await gs.sendToDeal(d, 'ну давай 650');
      expect(d.status, 'open');
      await gs.sendToDeal(d, 'ладно давай');
      expect(d.status, 'agreed');
      expect(d.price, 775);
      expect(gs.lastAiError, isNull);
      expect(d.messages.last.text, contains(r'$775'));
      expect(gs.balance, 1500);
      expect(gs.confirmDeal(d), isTrue);
      expect(gs.balance, 725);
      expect(gs.confirmDeal(d), isFalse);
    },
  );
}
