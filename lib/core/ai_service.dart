import 'dart:convert';

import 'package:http/http.dart' as http;

import 'i18n.dart';
import 'models.dart';

/// Wraps the free Google Gemini API. Game rules (accept / reject / counter)
/// are decided locally; the AI only writes the in-character reply.
/// If there is no key or the request fails, offline phrases are used.
class AiService {
  // Alias that always points to the current Flash model. Change if needed.
  static const model = 'gemini-flash-latest';
  static const _langNames = {'ru': 'Russian', 'en': 'English', 'uk': 'Ukrainian'};

  static String langName(String lang) => _langNames[lang] ?? 'English';

  static String offline(String key, double? number) =>
      I18n.t(key).replaceAll('{p}', number == null ? '' : number.toInt().toString());

  static Future<String> reply({
    required String apiKey,
    required String lang,
    required String persona,
    required List<ChatMsg> history,
    required String hint,
    required String offlineKey,
    double? number,
  }) async {
    if (apiKey.trim().isEmpty) return offline(offlineKey, number);
    try {
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
        return offline(offlineKey, number);
      }
      final lastParts = contents.last['parts'] as List;
      final lp = lastParts[0] as Map;
      lp['text'] = '${lp['text']}\n\n$hint';

      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey.trim()},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': persona}
                ]
              },
              'contents': contents,
              'generationConfig': {'temperature': 0.9, 'maxOutputTokens': 160},
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return offline(offlineKey, number);
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final t = text.trim();
      return t.isEmpty ? offline(offlineKey, number) : t;
    } catch (_) {
      return offline(offlineKey, number);
    }
  }
}
