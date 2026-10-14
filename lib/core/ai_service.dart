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

/// One ready-made OpenAI-compatible provider (shown as a button in the admin panel).
class AiPreset {
  final String name, url, model;
  const AiPreset(this.name, this.url, this.model);
}

const aiPresets = <AiPreset>[
  AiPreset('Groq', 'https://api.groq.com/openai/v1', 'llama-3.1-8b-instant'),
  AiPreset('OpenRouter', 'https://openrouter.ai/api/v1', 'meta-llama/llama-3.3-70b-instruct:free'),
  AiPreset('Gemini (AIza)', 'https://generativelanguage.googleapis.com/v1beta/openai', 'gemini-2.5-flash'),
];

/// AI client for the in-game dialogs.
///
/// Google keys of both kinds work:
///  * "AIza…" -> Gemini Developer API (generativelanguage.googleapis.com)
///  * "AQ.…"  -> Vertex AI Express (aiplatform.googleapis.com). This one needs
///    the "Vertex AI API" to be enabled in the key's Google Cloud project,
///    otherwise Google answers HTTP 403.
/// Both endpoints are tried (the one that worked last goes first). Alternatively
/// any OpenAI-compatible service can be configured in the admin panel.
///
/// Game rules (accept / refuse / counter-offer) are decided locally; the AI only
/// writes the in-character reply. On failure an offline phrase is used and the
/// reason goes to the admin log. After a configuration error (401/403/404) the
/// AI is paused for a short time so the player does not wait on every message.
class AiService {
  static String? modelOverride;

  // Custom OpenAI-compatible provider (empty url = use Google).
  static String customUrl = '';
  static String customKey = '';
  static String customModel = '';

  /// Endpoint that worked last: 'vertex', 'gemini' or null.
  static String? lastGood;

  /// Link from a "service disabled" error (open it to enable the API).
  static String? fixUrl;

  static DateTime? _pausedUntil;
  static String? _pauseReason;
  static const _langNames = {'ru': 'Russian', 'en': 'English', 'uk': 'Ukrainian'};
  static const _timeout = Duration(seconds: 12);

  static String langName(String lang) => _langNames[lang] ?? 'English';

  static bool get hasCustom => customUrl.trim().isNotEmpty;

  static bool isVertexKey(String k) => k.trim().startsWith('AQ.');

  static String keyKind(String k) {
    if (hasCustom) return 'свой провайдер (OpenAI-совместимый)';
    final t = k.trim();
    if (t.isEmpty) return 'нет ключа';
    if (t.startsWith('AIza')) return 'Gemini API (AIza…)';
    if (t.startsWith('AQ.')) return 'Vertex AI Express (AQ.…)';
    return 'неизвестный формат';
  }

  static String modelFor(String key) {
    if (hasCustom) return customModel.trim().isEmpty ? 'gpt-4o-mini' : customModel.trim();
    final o = modelOverride?.trim();
    if (o != null && o.isNotEmpty) return o;
    return isVertexKey(key) ? 'gemini-2.5-flash' : 'gemini-flash-latest';
  }

  static String offline(String key, double? number) =>
      I18n.t(key).replaceAll('{p}', number == null ? '' : number.toInt().toString());

  /// Stops AI calls for [pauseSeconds] (used after a configuration error).
  static bool get paused => _pausedUntil != null && DateTime.now().isBefore(_pausedUntil!);
  static String? get pauseReason => paused ? _pauseReason : null;
  static void resume() {
    _pausedUntil = null;
    _pauseReason = null;
  }

  static String _redact(String s, List<String> secrets) {
    var out = s;
    for (final k in secrets) {
      if (k.length > 6) out = out.replaceAll(k, '***');
    }
    return out.length > 500 ? '${out.substring(0, 500)}…' : out;
  }

  /// Pulls a short human-readable message (and a fix link) out of a Google error.
  static String _short(String raw) {
    try {
      final j = jsonDecode(raw);
      final e = j is List ? j.first['error'] : j['error'];
      if (e is Map) {
        final m = (e['message'] ?? '').toString();
        final st = (e['status'] ?? '').toString();
        return st.isEmpty ? m : '$st: $m';
      }
    } catch (_) {}
    return raw;
  }

  static void _grabFixUrl(String raw) {
    final m = RegExp(r'https://console\.(?:developers|cloud)\.google\.com/[^\s"\\<>]+').firstMatch(raw);
    if (m != null) {
      var u = m.group(0)!;
      while (u.isNotEmpty && '.,;)'.contains(u[u.length - 1])) {
        u = u.substring(0, u.length - 1);
      }
      fixUrl = u;
    }
  }

  // ------------------------------------------------------------ transports
  static Future<_Raw> _google(String ep, String key, String model, String system, List<Map<String, dynamic>> contents, int maxTokens) async {
    final vertex = ep == 'vertex';
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
    final res = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
    final raw = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) return _Raw(null, res.statusCode, raw);
    final data = jsonDecode(raw);
    final cand = (data['candidates'] as List?)?.firstOrNull;
    final parts = cand?['content']?['parts'] as List?;
    final out = parts == null ? '' : parts.map((p) => (p['text'] ?? '').toString()).join().trim();
    if (out.isEmpty) return _Raw(null, 200, 'пустой ответ, finishReason=${cand?['finishReason']}');
    return _Raw(out, 200, '');
  }

  static Future<_Raw> _openAi(String model, String system, List<Map<String, dynamic>> contents, int maxTokens) async {
    var base = customUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final uri = Uri.parse(base.endsWith('/chat/completions') ? base : '$base/chat/completions');
    final msgs = <Map<String, String>>[
      {'role': 'system', 'content': system},
      for (final c in contents)
        {
          'role': c['role'] == 'model' ? 'assistant' : 'user',
          'content': ((c['parts'] as List)[0] as Map)['text'].toString(),
        },
    ];
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (customKey.trim().isNotEmpty) 'Authorization': 'Bearer ${customKey.trim()}',
          },
          body: jsonEncode({'model': model, 'messages': msgs, 'max_tokens': maxTokens, 'temperature': 0.9}),
        )
        .timeout(_timeout);
    final raw = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) return _Raw(null, res.statusCode, raw);
    final data = jsonDecode(raw);
    final out = ((data['choices'] as List?)?.firstOrNull?['message']?['content'] ?? '').toString().trim();
    if (out.isEmpty) return _Raw(null, 200, 'пустой ответ');
    return _Raw(out, 200, '');
  }

  // ----------------------------------------------------------------- core
  static Future<AiResult> _call({
    required String apiKey,
    required String system,
    required List<Map<String, dynamic>> contents,
    int maxTokens = 1024,
    bool force = false,
  }) async {
    final sw = Stopwatch()..start();
    final key = apiKey.trim();
    final model = modelFor(key);

    if (!force && paused) {
      return AiResult('', false, 'ИИ на паузе: $_pauseReason', 0);
    }
    if (!hasCustom && key.isEmpty) {
      const err = 'нет API-ключа (ни встроенного, ни введённого в настройках)';
      AppLog.I.error('ai', err);
      return const AiResult('', false, err, 0);
    }

    final secrets = [key, customKey.trim()];
    final errors = <String>[];

    // Which transports to try, in order.
    final List<String> plan;
    if (hasCustom) {
      plan = ['custom'];
    } else if (isVertexKey(key)) {
      plan = lastGood == 'gemini' ? ['gemini', 'vertex'] : ['vertex', 'gemini'];
    } else if (key.startsWith('AIza')) {
      plan = ['gemini'];
    } else {
      plan = lastGood == 'vertex' ? ['vertex', 'gemini'] : ['gemini', 'vertex'];
    }

    var allConfig = true;
    for (final ep in plan) {
      try {
        final r = ep == 'custom'
            ? await _openAi(model, system, contents, maxTokens)
            : await _google(ep, key, model, system, contents, maxTokens);
        if (r.text != null) {
          sw.stop();
          if (!hasCustom) lastGood = ep;
          fixUrl = null;
          resume();
          AppLog.I.info('ai', 'OK [$ep, $model] ${sw.elapsedMilliseconds} мс');
          return AiResult(r.text!, true, null, sw.elapsedMilliseconds);
        }
        if (r.status != 200) {
          _grabFixUrl(r.body);
          final isCfg = r.status == 400 || r.status == 401 || r.status == 403 || r.status == 404;
          if (!isCfg) allConfig = false;
          errors.add('$ep: HTTP ${r.status} ${_redact(_short(r.body), secrets)}');
        } else {
          allConfig = false;
          errors.add('$ep: ${r.body}');
        }
      } catch (e) {
        allConfig = false;
        errors.add('$ep: ${_redact(e.toString(), secrets)}');
      }
    }
    final config = allConfig; // every error looked like a configuration problem
    sw.stop();
    final err = '[$model] ${errors.join(' | ')}';
    AppLog.I.error('ai', err);
    if (config && !force) {
      _pausedUntil = DateTime.now().add(const Duration(minutes: 2));
      _pauseReason = errors.isEmpty ? 'ошибка настройки' : errors.first;
      AppLog.I.warn('ai', 'ИИ приостановлен на 2 минуты (ошибка настройки). Проверьте ключ в админ-панели.');
    }
    return AiResult('', false, err, sw.elapsedMilliseconds);
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

  /// Connection test used by the admin panel (ignores the pause).
  static Future<AiResult> ping(String apiKey) {
    resume();
    return _call(
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
      force: true,
    );
  }
}

class _Raw {
  final String? text;
  final int status;
  final String body;
  _Raw(this.text, this.status, this.body);
}
