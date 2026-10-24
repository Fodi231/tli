import 'dart:async';
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
  AiPreset(
    'OpenRouter',
    'https://openrouter.ai/api/v1',
    'meta-llama/llama-3.3-70b-instruct:free',
  ),
  AiPreset(
    'Gemini (AIza)',
    'https://generativelanguage.googleapis.com/v1beta/openai',
    'gemini-3.8-flash',
  ),
];

/// AI client for the in-game dialogs.
///
/// Gemini Developer API and Vertex Express are distinct services. The player
/// chooses the endpoint explicitly; an API-key prefix is not a service selector.
/// A failed request is never silently sent to a different Google service.
///
/// Game rules (accept / refuse / counter-offer) are decided locally; the AI only
/// writes the in-character reply. On failure an offline phrase is used and the
/// reason goes to the admin log. After a configuration error (401/403/404) the
/// AI is paused for a short time so the player does not wait on every message.
class AiService {
  /// Injectable transport for deterministic API tests.
  static http.Client client = http.Client();
  static String? modelOverride;
  static String googleEndpoint = 'gemini';
  static const defaultModel = 'gemini-3.5-flash-lite';
  static String managedUrl = const String.fromEnvironment(
    'TECHLIFE_AI_URL',
    defaultValue:
        'https://techlife-ai-service.brainycloud19.chatgpt.site/api/chat',
  );
  static bool managedEnabled = true;
  static bool get hasManaged => managedEnabled && managedUrl.trim().isNotEmpty;

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
  static const _langNames = {
    'ru': 'Russian',
    'en': 'English',
    'uk': 'Ukrainian',
  };
  static const requestTimeout = Duration(seconds: 45);

  static String langName(String lang) => _langNames[lang] ?? 'English';

  static bool breaksCharacter(String text) {
    final s = text.toLowerCase();
    return [
      'игров',
      'ігров',
      'игра отклон',
      'гра відхил',
      'game dollar',
      'in-game',
      'game result',
      'интерфейс',
      'інтерфейс',
      'interface',
      'as an ai',
      'language model',
      'я ии',
      'я — ии',
      'я искусствен',
      'я штучн',
      'npc',
      'не сошлись по цене, чтобы',
    ].any(s.contains);
  }

  static bool get hasCustom => customUrl.trim().isNotEmpty;

  static String keyKind(String k) {
    if (hasManaged) return 'TechLife AI · автоматически';
    if (hasCustom) return 'свой провайдер (OpenAI-совместимый)';
    if (k.trim().isEmpty) return 'нет ключа';
    return googleEndpoint == 'vertex'
        ? 'Vertex / Agent Platform Express'
        : 'Gemini Developer API';
  }

  static String modelFor(String key) {
    if (hasManaged) return defaultModel;
    if (hasCustom) {
      return customModel.trim().isEmpty ? 'gpt-4o-mini' : customModel.trim();
    }
    final o = modelOverride?.trim();
    if (o != null && o.isNotEmpty) return o;
    return defaultModel;
  }

  static String offline(String key, double? number) => I18n.t(
    key,
  ).replaceAll('{p}', number == null ? '' : number.toInt().toString());

  /// Stops AI calls for [pauseSeconds] (used after a configuration error).
  static bool get paused =>
      _pausedUntil != null && DateTime.now().isBefore(_pausedUntil!);
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
    final m = RegExp(
      r'https://console\.(?:developers|cloud)\.google\.com/[^\s"\\<>]+',
    ).firstMatch(raw);
    if (m != null) {
      var u = m.group(0)!;
      while (u.isNotEmpty && '.,;)'.contains(u[u.length - 1])) {
        u = u.substring(0, u.length - 1);
      }
      fixUrl = u;
    }
  }

  // ------------------------------------------------------------ transports
  static Future<_Raw> _google(
    String ep,
    String key,
    String model,
    String system,
    List<Map<String, dynamic>> contents,
    int maxTokens,
  ) async {
    final vertex = ep == 'vertex';
    final uri =
        vertex
            ? Uri.parse(
              'https://aiplatform.googleapis.com/v1/publishers/google/models/$model:generateContent',
            )
            : Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
            );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-goog-api-key': key,
    };
    final gen = <String, dynamic>{
      if (!model.startsWith('gemini-3') && !model.startsWith('gemini-4'))
        'temperature': 0.9,
      'maxOutputTokens': maxTokens,
    };
    if (model.startsWith('gemini-3') || model.startsWith('gemini-4')) {
      gen['thinkingConfig'] = {'thinkingLevel': 'low'};
    }
    // Thinking tokens would eat the output budget and slow replies down.
    if (model.contains('2.5-flash')) {
      gen['thinkingConfig'] = {'thinkingBudget': 0};
    }
    final body = {
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': contents,
      'generationConfig': gen,
    };
    final res = await client
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(requestTimeout);
    final raw = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) return _Raw(null, res.statusCode, raw);
    final data = jsonDecode(raw);
    final cand = (data['candidates'] as List?)?.firstOrNull;
    final parts = cand?['content']?['parts'] as List?;
    final out =
        parts == null
            ? ''
            : parts
                .where((p) => p['thought'] != true)
                .map((p) => (p['text'] ?? '').toString())
                .join()
                .trim();
    if (out.isEmpty) {
      return _Raw(
        null,
        200,
        'пустой ответ, finishReason=${cand?['finishReason']}',
      );
    }
    return _Raw(out, 200, '');
  }

  static Future<_Raw> _openAi(
    String model,
    String system,
    List<Map<String, dynamic>> contents,
    int maxTokens,
  ) async {
    var base = customUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final uri = Uri.parse(
      base.endsWith('/chat/completions') ? base : '$base/chat/completions',
    );
    final msgs = <Map<String, String>>[
      {'role': 'system', 'content': system},
      for (final c in contents)
        {
          'role': c['role'] == 'model' ? 'assistant' : 'user',
          'content': ((c['parts'] as List)[0] as Map)['text'].toString(),
        },
    ];
    final res = await client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (customKey.trim().isNotEmpty)
              'Authorization': 'Bearer ${customKey.trim()}',
          },
          body: jsonEncode({
            'model': model,
            'messages': msgs,
            'max_tokens': maxTokens,
            'temperature': 0.9,
          }),
        )
        .timeout(requestTimeout);
    final raw = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) return _Raw(null, res.statusCode, raw);
    final data = jsonDecode(raw);
    final out =
        ((data['choices'] as List?)?.firstOrNull?['message']?['content'] ?? '')
            .toString()
            .trim();
    if (out.isEmpty) return _Raw(null, 200, 'пустой ответ');
    return _Raw(out, 200, '');
  }

  static Future<_Raw> _managed(
    List<Map<String, dynamic>> contents,
    Map<String, dynamic>? context,
  ) async {
    final messages = <Map<String, String>>[];
    for (final c in contents.skip(
      contents.length > 8 ? contents.length - 8 : 0,
    )) {
      final text =
          (c['parts'] as List).map((p) => p['text'] ?? '').join('\n').trim();
      if (text.isEmpty || (messages.isEmpty && c['role'] != 'user')) continue;
      messages.add({
        'role': c['role'] == 'model' ? 'model' : 'user',
        'text': text.length > 1000 ? text.substring(0, 1000) : text,
      });
    }
    final body =
        context == null
            ? {'mode': 'ping'}
            : {'mode': 'dialog', 'context': context, 'messages': messages};
    final response = await client
        .post(
          Uri.parse(managedUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(requestTimeout);
    if (response.statusCode != 200) {
      return _Raw(
        null,
        response.statusCode,
        'TechLife AI HTTP ${response.statusCode}',
      );
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final text = data is Map ? (data['text'] as String? ?? '').trim() : '';
    return text.isEmpty
        ? _Raw(null, 502, 'Empty TechLife AI reply')
        : _Raw(text, 200, '');
  }

  // ----------------------------------------------------------------- core
  static Future<AiResult> _call({
    required String apiKey,
    required String system,
    required List<Map<String, dynamic>> contents,
    int maxTokens = 1024,
    bool force = false,
    Map<String, dynamic>? managedContext,
  }) async {
    final sw = Stopwatch()..start();
    final key = apiKey.trim();
    final model = modelFor(key);

    if (!force && paused) {
      return AiResult('', false, 'ИИ на паузе: $_pauseReason', 0);
    }
    if (!hasManaged && !hasCustom && key.isEmpty) {
      const err = 'нет API-ключа (ни встроенного, ни введённого в настройках)';
      AppLog.I.error('ai', err);
      return const AiResult('', false, err, 0);
    }

    final secrets = [key, customKey.trim()];
    final errors = <String>[];

    // No cross-service fallback: permissions and enabled APIs are different.
    final plan = [
      hasManaged
          ? 'managed'
          : hasCustom
          ? 'custom'
          : googleEndpoint == 'vertex'
          ? 'vertex'
          : 'gemini',
    ];

    var allConfig = true;
    for (final ep in plan) {
      try {
        final r =
            ep == 'managed'
                ? await _managed(contents, managedContext)
                : ep == 'custom'
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
          final isCfg =
              r.status == 400 ||
              r.status == 401 ||
              r.status == 403 ||
              r.status == 404;
          if (!isCfg) allConfig = false;
          errors.add(
            '$ep: HTTP ${r.status} ${_redact(_short(r.body), secrets)}',
          );
        } else {
          allConfig = false;
          errors.add('$ep: ${r.body}');
        }
      } on TimeoutException {
        allConfig = false;
        errors.add(
          '$ep: нет ответа за ${requestTimeout.inSeconds} секунд. Проверьте сеть и доступ к выбранному API; можно повторить тест.',
        );
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
      AppLog.I.warn(
        'ai',
        'ИИ приостановлен на 2 минуты (ошибка настройки). Проверьте ключ в админ-панели.',
      );
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
    Map<String, dynamic>? managedContext,
  }) async {
    final contents = <Map<String, dynamic>>[];
    for (final m in history.skip(
      history.length > 24 ? history.length - 24 : 0,
    )) {
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
            {'text': m.text},
          ],
        });
      }
    }
    if (contents.isEmpty || contents.last['role'] != 'user') {
      return AiResult(
        offline(offlineKey, number),
        false,
        'пустая история диалога',
        0,
      );
    }
    final managedContents = [
      for (final c in contents)
        {
          'role': c['role'],
          'parts': [
            for (final p in c['parts'] as List) {'text': p['text']},
          ],
        },
    ];
    final lp = (contents.last['parts'] as List)[0] as Map;
    lp['text'] = '${lp['text']}\n\n$hint';

    final r = await _call(
      apiKey: apiKey,
      system: persona,
      contents: hasManaged ? managedContents : contents,
      managedContext: managedContext,
    );
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
            {'text': 'Say hello in Russian.'},
          ],
        },
      ],
      maxTokens: 1024,
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
