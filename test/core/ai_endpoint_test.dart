import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techlife/core/ai_service.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/models.dart';

void main() {
  setUp(() {
    AiService.managedEnabled = false;
    AiService.customUrl = '';
    AiService.googleEndpoint = 'gemini';
    AiService.modelOverride = null;
    AiService.lastGood = null;
    AiService.resume();
  });
  tearDown(() {
    AiService.client.close();
    AiService.client = http.Client();
    AiService.googleEndpoint = 'gemini';
    AiService.resume();
  });
  test(
    'AQ prefix does not silently select Vertex and Gemini 3.8 uses low thinking',
    () async {
      AiService.lastGood = 'vertex';
      AiService.modelOverride = 'gemini-3.8-flash';
      var count = 0;
      AiService.client = MockClient((r) async {
        count++;
        expect(r.url.host, 'generativelanguage.googleapis.com');
        expect(r.headers['x-goog-api-key'], 'AQ.test-not-a-real-key');
        expect(r.url.queryParameters, isNot(contains('key')));
        final gen = jsonDecode(r.body)['generationConfig'];
        expect(gen['thinkingConfig']['thinkingLevel'], 'low');
        expect(gen.containsKey('temperature'), isFalse);
        return http.Response(
          '{"candidates":[{"content":{"parts":[{"text":"OK"}]}}]}',
          200,
        );
      });
      expect((await AiService.ping('AQ.test-not-a-real-key')).ok, isTrue);
      expect(count, 1);
      expect(AiService.requestTimeout.inSeconds, 45);
    },
  );
  test(
    'explicit Vertex uses header and 403 never triggers a Gemini request',
    () async {
      AiService.googleEndpoint = 'vertex';
      var count = 0;
      AiService.client = MockClient((r) async {
        count++;
        expect(r.url.host, 'aiplatform.googleapis.com');
        expect(r.headers['x-goog-api-key'], 'test-not-a-real-key');
        expect(r.url.queryParameters, isNot(contains('key')));
        return http.Response(
          jsonEncode({
            'error': {
              'status': 'PERMISSION_DENIED',
              'message':
                  'API disabled. https://console.developers.google.com/apis/api/aiplatform.googleapis.com/overview?project=123',
            },
          }),
          403,
        );
      });
      final r = await AiService.reply(
        apiKey: 'test-not-a-real-key',
        lang: 'ru',
        persona: 'NPC',
        history: [ChatMsg(true, 'Hello')],
        hint: '',
        offlineKey: 'o_chat',
      );
      expect(r.ok, isFalse);
      expect(r.error, contains('vertex: HTTP 403'));
      expect(r.error, isNot(contains('gemini:')));
      expect(count, 1);
      expect(AiService.fixUrl, contains('aiplatform.googleapis.com'));
      expect(AiService.paused, isTrue);
    },
  );
  test(
    'timeout reports the selected API once without switching services',
    () async {
      var count = 0;
      AiService.client = MockClient((r) async {
        count++;
        throw TimeoutException('simulated');
      });
      final r = await AiService.ping('test-not-a-real-key');
      expect(r.error, contains('gemini: нет ответа за 45 секунд'));
      expect(r.error, isNot(contains('vertex:')));
      expect(count, 1);
    },
  );
  test('selected endpoint persists and old saves default to Gemini', () {
    final g = GameState();
    final restored = GameState();
    addTearDown(g.dispose);
    addTearDown(restored.dispose);
    g.setGoogleEndpoint('vertex');
    expect(restored.importSave(g.exportSave()), isTrue);
    expect(restored.aiEndpoint, 'vertex');
    expect(AiService.googleEndpoint, 'vertex');
    restored.setGoogleEndpoint('gemini');
    expect(AiService.googleEndpoint, 'gemini');
    final data = jsonDecode(g.exportSave()) as Map<String, dynamic>;
    data.remove('aiEndpoint');
    expect(restored.importSave(jsonEncode(data)), isTrue);
    expect(restored.aiEndpoint, 'gemini');
  });
}
