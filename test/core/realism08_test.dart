import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techlife/core/ai_service.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/core/market/chat_intent.dart';
import 'package:techlife/core/wallpaper_cfg.dart';
import 'package:techlife/core/wallpapers.dart';

void main() {
  setUp(() {
    I18n.lang = 'ru';
    AiService.resume();
    AiService.managedEnabled = false;
    AiService.customUrl = '';
    AiService.googleEndpoint = 'gemini';
  });
  tearDown(() => AiService.client = http.Client());

  test(
    'counter survives save and natural agreement keeps payment explicit',
    () async {
      final gs = GameState()..forceOffline = true;
      addTearDown(gs.dispose);
      final d = Deal(
        id: 'realism',
        kind: 'buy',
        item: 'iPhone 12',
        counterpart: 'Виктор',
        market: 280,
        ask: 120,
        limit: 105,
        deviceId: 'iphone12',
        fault: 'display',
      );
      gs.deals.add(d);
      await gs.sendToDeal(d, r'Предлагаю $100');
      expect(d.counterPrice, 110);
      expect(d.status, 'open');
      expect(d.messages.last.text, contains(r'$110'));
      final restored = GameState();
      addTearDown(restored.dispose);
      expect(restored.importSave(gs.exportSave()), isTrue);
      restored.forceOffline = true;
      final chat = restored.deals.firstWhere((x) => x.id == d.id);
      await restored.sendToDeal(chat, 'Хорошо, давай');
      expect(chat.status, 'agreed');
      expect(chat.price, 110);
      expect(restored.balance, 1500);
      expect(restored.stock, isEmpty);
      expect(restored.confirmDeal(chat), isTrue);
      expect(restored.balance, 1390);
      expect(restored.confirmDeal(chat), isFalse);
    },
  );

  test('buyer honours their own rounded counteroffer', () async {
    final gs = GameState()..forceOffline = true;
    addTearDown(gs.dispose);
    final d = Deal(
      id: 'sell',
      kind: 'sell',
      item: 'iPhone 12',
      counterpart: 'Виктор',
      market: 280,
      ask: 120,
      limit: 103,
    );
    gs.deals.add(d);
    await gs.sendToDeal(d, '120');
    expect(d.counterPrice, 105);
    await gs.sendToDeal(d, 'По рукам');
    expect(d.status, 'agreed');
    expect(d.price, 105);
    expect(gs.balance, 1500);
  });

  test('questions model numbers and storage do not accept or change price', () {
    for (final text in [
      'У iPhone 13 память 128 ГБ?',
      '110?',
      'ок, а батарея?',
      'Да?',
      '256 GB',
      'нет',
    ]) {
      expect(chatPrice(text), isNull, reason: text);
      expect(acceptsCounter(text), isFalse, reason: text);
    }
    expect(acceptsCounter('Хорошо, давай!'), isTrue);
    expect(acceptsCounter('Sounds good.'), isTrue);
    expect(acceptsCounter('Домовились'), isTrue);
    expect(chatPrice(r'Предлагаю $100'), 100);
    final old = Deal(
      id: 'old',
      kind: 'buy',
      item: 'iPhone 12',
      counterpart: 'Виктор',
      market: 280,
      ask: 120,
      limit: 105,
    )..rounds = 1;
    final json = old.toJson()..remove('counter');
    expect(Deal.fromJson(json).counterPrice, 110);
  });

  test(
    'out of character AI output is replaced without changing decision',
    () async {
      final gs = GameState()..geminiKey = 'AIza_test_not_a_real_key';
      addTearDown(gs.dispose);
      AiService.client = MockClient(
        (r) async => http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          'Игра отклонила сумму. Давай 110 игровых долларов.',
                    },
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
        id: 'guard',
        kind: 'buy',
        item: 'iPhone 12',
        counterpart: 'Виктор',
        market: 280,
        ask: 120,
        limit: 105,
        deviceId: 'iphone12',
        fault: 'display',
      );
      gs.deals.add(d);
      await gs.sendToDeal(d, '100');
      expect(d.messages.last.text, contains(r'$110'));
      expect(AiService.breaksCharacter(d.messages.last.text), isFalse);
      expect(d.messages.last.fallback, isTrue);
      expect(d.counterPrice, 110);
      expect(gs.balance, 1500);
    },
  );

  test('offline questions get specific truthful concise answers', () async {
    final gs = GameState()..forceOffline = true;
    addTearDown(gs.dispose);
    final d = gs.openMarketDeal('m01')!;
    await gs.sendToDeal(d, 'Сколько памяти?');
    expect(d.messages.last.text, contains('128 GB'));
    expect(d.messages.last.text.length, lessThan(80));
    await gs.sendToDeal(d, 'Какой износ батареи?');
    expect(d.messages.last.text, contains('не проверял'));
    expect(d.rounds, 0);
  });

  test('wallpapers and glass persist independently and old saves migrate', () {
    final gs = GameState();
    addTearDown(gs.dispose);
    for (final asset in bundledWallpapers.keys) {
      gs.setWallpaperAsset(asset);
      expect(gs.homeWp.asset, asset);
      expect(gs.homeWp.hasImage, isFalse);
    }
    gs.setLockSeparate(true);
    gs.setWallpaperAsset(bundledWallpapers.keys.first, lock: true);
    gs.setLiquidGlass(false);
    final restored = GameState();
    addTearDown(restored.dispose);
    expect(restored.importSave(gs.exportSave()), isTrue);
    expect(restored.liquidGlass, isFalse);
    expect(restored.homeWp.asset, bundledWallpapers.keys.last);
    expect(restored.lockCfg.asset, bundledWallpapers.keys.first);
    restored.setWallpaperPreset(2);
    expect(restored.homeWp.asset, isNull);
    expect(restored.lockCfg.asset, bundledWallpapers.keys.first);
    final cfg =
        WallpaperCfg()..loadJson({'p': 3, 'asset': 'file:///arbitrary.jpg'});
    expect(cfg.asset, isNull);
    expect(cfg.preset, 3);
    final data = jsonDecode(gs.exportSave()) as Map<String, dynamic>;
    data.remove('liquidGlass');
    restored.importSave(jsonEncode(data));
    expect(restored.liquidGlass, isTrue);
  });
}
