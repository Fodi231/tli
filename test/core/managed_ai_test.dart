import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techlife/core/ai_service.dart';
import 'package:techlife/core/game_state.dart';

void main() {
  setUp(() {
    AiService.managedEnabled = true;
    AiService.customUrl = '';
    AiService.managedUrl =
        'https://techlife-ai-service.brainycloud19.chatgpt.site/api/chat';
    AiService.resume();
  });
  tearDown(() {
    AiService.client.close();
    AiService.client = http.Client();
    AiService.managedEnabled = true;
    AiService.resume();
  });
  test('fresh player gets live replies without entering a key', () async {
    final gs = GameState();
    addTearDown(gs.dispose);
    expect(gs.aiKey, isEmpty);
    AiService.client = MockClient((r) async {
      expect(r.url.host, 'techlife-ai-service.brainycloud19.chatgpt.site');
      expect(r.headers.containsKey('x-goog-api-key'), isFalse);
      final body = jsonDecode(r.body);
      expect(body['context']['deviceId'], 'iphone13');
      expect(body['context']['outcome'], 'chat');
      expect(body.containsKey('systemInstruction'), isFalse);
      return http.Response(
        jsonEncode({'ok': true, 'text': 'Не работает дисплей, память 128 ГБ.'}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final d = gs.openMarketDeal('m01')!;
    await gs.sendToDeal(d, 'Что сломано?');
    expect(d.messages.last.fallback, isFalse);
    expect(d.messages.last.text, contains('128'));
    expect(d.status, 'open');
  });
  test(
    'old personal key and custom provider never leak to the managed service',
    () async {
      final gs = GameState()..geminiKey = 'old-private-test-key';
      addTearDown(gs.dispose);
      AiService.customKey = 'old-custom-test-key';
      AiService.customUrl = 'https://old-provider.invalid';
      AiService.client = MockClient((r) async {
        expect(r.body, isNot(contains('old-private-test-key')));
        expect(r.body, isNot(contains('old-custom-test-key')));
        expect(
          r.headers.values.join(),
          isNot(contains('old-private-test-key')),
        );
        final b = jsonDecode(r.body);
        expect(b['context']['outcome'], 'accept');
        expect(b['context']['amount'], 190);
        return http.Response(
          '{"ok":true,"text":"Договорились. Подтверди сделку."}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final d = gs.openMarketDeal('m01')!;
      await gs.sendToDeal(d, '190');
      expect(d.status, 'agreed');
      expect(gs.stock, isEmpty);
      expect(gs.balance, 1500);
      expect(gs.confirmDeal(d), isTrue);
      expect(gs.balance, 1310);
    },
  );
  test('server quota failure falls back without changing ownership', () async {
    final gs = GameState();
    addTearDown(gs.dispose);
    AiService.client = MockClient(
      (r) async => http.Response('{"error":"rate_limit"}', 429),
    );
    final d = gs.openMarketDeal('m01')!;
    await gs.sendToDeal(d, 'Есть дефекты?');
    expect(d.busy, isFalse);
    expect(d.messages.last.fallback, isTrue);
    expect(gs.stock, isEmpty);
    expect(gs.lastAiError, contains('429'));
  });
  test(
    'automatic mode survives saves and can be restored from admin overrides',
    () {
      final gs = GameState();
      final restored = GameState();
      addTearDown(gs.dispose);
      addTearDown(restored.dispose);
      gs.setGoogleEndpoint('vertex');
      expect(AiService.hasManaged, isFalse);
      gs.useAutomaticAi();
      expect(AiService.hasManaged, isTrue);
      expect(restored.importSave(gs.exportSave()), isTrue);
      expect(restored.manualAi, isFalse);
      expect(AiService.hasManaged, isTrue);
    },
  );
  test('connection check uses the public service with no credential', () async {
    AiService.client = MockClient((r) async {
      expect(jsonDecode(r.body), {'mode': 'ping'});
      return http.Response('{"ok":true,"text":"OK"}', 200);
    });
    final result = await AiService.ping('');
    expect(result.ok, isTrue);
  });
}
