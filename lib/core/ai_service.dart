import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_log.dart';
import 'i18n.dart';
import 'models.dart';

class AiResult {
  final String text;
  final bool ok;
  final String? error;
  final int ms;
  const AiResult(this.text, this.ok, this.error, this.ms);
}

/// Google Gemini client. Supports both key types:
///  * "AIza..." keys  -> Gemini Developer API (generativelanguage.googleapis.com)
///  * "AQ...."  keys  -> Vertex AI Express mode (aiplatform.googleapis.com)
/// Game rules (accept / reject / counter) are decided locally; the AI only
/// writes the in-character reply. On any failure an offline phrase is used and
/// the error is written to the admin log.
class AiService {
  static String? modelOverride;
  static const _langNames = {'ru': 'Russian', 'en': 'English', 'uk': 'Ukrainian'};

  static String langName(String lang) => _langNames[lang] ?? 'English';

  static bool isVertexKey(String k) => k.trim().startsWith('AQ.');

  static String keyKind(String k) {
    final t = k.trim();
    if (t.isEmpty) return 'нет ключа';
    if (t.startsWith('AIza')) return 'Gemini API (AIza…)';
    if (t.startsWith('AQ.')) return 'Vertex AI Express (AQ.…)';
    return 'неизвестный формат';
  }

  static String modelFor(String key) {
    final o = modelOverride?.trim();
    if (o != null && o.isNotEmpty) return o;
    return isVertexKey(key) ? 'gemini-2.5-flash' : 'gemini-flash-latest';
  }

  static String offline(String key, double? number) =>
      I18n.t(key).replaceAll('{p}', number == null ? '' : number.toInt().toString());

  static String _redact(String s, String key) {
    var out = s;
    if (key.isNotEmpty) out = out.replaceAll(key, '***');
    return out.length > 400 ? '${out.substring(0, 400)}…' : out;
  }

  static Future<AiResult> _call({
    required String apiKey,
    required String system,
    required List<Map<String, dynamic>> contents,
    int maxTokens = 1024,
  }) async {
    final sw = Stopwatch()..start();
    final key = apiKey.trim();
    final model = modelFor(key);
    if (key.isEmpty) {
      const err = 'нет API-ключа (ни встроенного, ни введённого в настройках)';
      AppLog.I.error('ai', err);
      return const AiResult('', false, err, 0);
    }
    try {
      final vertex = isVertexKey(key);
      final uri = vertex
          ? Uri.parse('https://aiplatform.googleapis.com/v1/publishers/google/models/$model:generateContent?key=$key')
          : Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (!vertex) 'x-goog-api-key': key,
      };
      final gen = <String, dynamic>{'temperature': 0.9, 'maxOutputTokens': maxTokens};
      // Thinking tokens would eat the output budget and slow replies down.
      if (model.contains('2.5-flash')) gen['thinkingConfig'] = {'thinkingBudget': 0};
      final body = {
        'systemInstruction': {
          'parts': [
            {'text': system}
          ]
        },
        'contents': contents,
        'generationConfig': gen,
      };
      final res = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 25));
      sw.stop();
      final raw = utf8.decode(res.bodyBytes);
      if (res.statusCode != 200) {
        final err = 'HTTP ${res.statusCode} [$model, ${vertex ? 'vertex' : 'gemini'}]: ${_redact(raw, key)}';
        AppLog.I.error('ai', err);
        return AiResult('', false, err, sw.elapsedMilliseconds);
      }
      final data = jsonDecode(raw);
      final cand = (data['candidates'] as List?)?.firstOrNull;
      final parts = cand?['content']?['parts'] as List?;
      final out = parts == null ? '' : parts.map((p) => (p['text'] ?? '').toString()).join().trim();
      if (out.isEmpty) {
        final err = 'пустой ответ [$model], finishReason=${cand?['finishReason']}: ${_redact(raw, key)}';
        AppLog.I.error('ai', err);
        return AiResult('', false, err, sw.elapsedMilliseconds);
      }
      AppLog.I.info('ai', 'OK [$model] ${sw.elapsedMilliseconds} мс');
      return AiResult(out, true, null, sw.elapsedMilliseconds);
    } catch (e) {
      sw.stop();
      final err = 'исключение [$model]: ${_redact(e.toString(), key)}';
      AppLog.I.error('ai', err);
      return AiResult('', false, err, sw.elapsedMilliseconds);
    }
  }

  static Future<AiResult> reply({
    required String apiKey,
    required String lang,
    required String persona,
    required List<ChatMsg> history,
    required String hint,
    required String offlineKey,
    double? number,
  }) async {
    final contents = <Map<String, dynamic>>[];
    for (final m in history) {
      final role = m.mine ? 'user' : 'model';
      if (contents.isEmpty && role == 'model') continue; // must start with user
      if (contents.isNotEmpty && contents.last['role'] == role) {
        final parts = contents.last['parts'] as List;
        final p = parts[0] as Map;
        p['text'] = '${p['text']}\n${m.text}';
      } else {
        contents.add({
          'role': role,
          'parts': [
            {'text': m.text}
          ],
        });
      }
    }
    if (contents.isEmpty || contents.last['role'] != 'user') {
      return AiResult(offline(offlineKey, number), false, 'пустая история диалога', 0);
    }
    final lp = (contents.last['parts'] as List)[0] as Map;
    lp['text'] = '${lp['text']}\n\n$hint';

    final r = await _call(apiKey: apiKey, system: persona, contents: contents);
    if (r.ok) return r;
    return AiResult(offline(offlineKey, number), false, r.error, r.ms);
  }

  /// Connection test used by the admin panel.
  static Future<AiResult> ping(String apiKey) => _call(
        apiKey: apiKey,
        system: 'You are a connection test. Reply with one short sentence.',
        contents: [
          {
            'role': 'user',
            'parts': [
              {'text': 'Say hello in Russian.'}
            ]
          }
        ],
        maxTokens: 256,
      );
}
