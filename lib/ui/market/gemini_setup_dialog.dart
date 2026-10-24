import 'package:flutter/material.dart';
import '../../core/game_state.dart';
import '../../core/ai_service.dart';
import '../../core/market/market_strings.dart';

class GeminiSetupDialog extends StatefulWidget {
  final GameState gs;
  const GeminiSetupDialog({super.key, required this.gs});
  @override
  State<GeminiSetupDialog> createState() => _GeminiSetupDialogState();
}

class _GeminiSetupDialogState extends State<GeminiSetupDialog> {
  late final keyCtrl = TextEditingController(text: widget.gs.geminiKey);
  late final modelCtrl = TextEditingController(
    text:
        widget.gs.aiModel.isEmpty ? AiService.defaultModel : widget.gs.aiModel,
  );
  late String endpoint = widget.gs.aiEndpoint;
  bool busy = false;
  String? result;
  @override
  void dispose() {
    keyCtrl.dispose();
    modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Gemini AI'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mt(
              'Ключ сохраняется на этом устройстве. Скопируй его из Google AI Studio.',
              'The key is saved on this device. Get it from Google AI Studio.',
              'Ключ зберігається на цьому пристрої. Отримай його в Google AI Studio.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: endpoint,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Google API'),
            items: const [
              DropdownMenuItem(
                value: 'gemini',
                child: Text(
                  'Gemini API · AI Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'vertex',
                child: Text(
                  'Vertex / Agent Platform Express',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged:
                busy
                    ? null
                    : (v) {
                      if (v != null) setState(() => endpoint = v);
                    },
          ),
          const SizedBox(height: 8),
          Text(
            mt(
              'AI Studio → Gemini API. Ключ Cloud Express → Vertex. Доступ к API должен быть включён в проекте ключа.',
              'AI Studio → Gemini API. Cloud Express key → Vertex. Enable the selected API in the key’s project.',
              'AI Studio → Gemini API. Ключ Cloud Express → Vertex. Обраний API має бути ввімкнений у проєкті ключа.',
            ),
            style: const TextStyle(fontSize: 11),
          ),
          TextField(
            controller: keyCtrl,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'API key',
              hintText: 'AIza…',
            ),
          ),
          TextField(
            controller: modelCtrl,
            decoration: InputDecoration(
              labelText: mt('Модель', 'Model', 'Модель'),
            ),
          ),
          const SizedBox(height: 12),
          if (busy) const LinearProgressIndicator(),
          if (result != null)
            Text(result!, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(mt('Закрыть', 'Close', 'Закрити')),
      ),
      OutlinedButton(
        onPressed:
            busy
                ? null
                : () async {
                  widget.gs.setAiProvider('', '', '');
                  widget.gs.setGoogleEndpoint(endpoint);
                  widget.gs.setKey(keyCtrl.text);
                  widget.gs.setAiModel(modelCtrl.text);
                  setState(() => busy = true);
                  final r = await widget.gs.adminTestAi();
                  if (mounted) {
                    setState(() {
                      busy = false;
                      result =
                          r.ok
                              ? mt(
                                'Подключение работает',
                                'Connection successful',
                                'Підключення працює',
                              )
                              : r.error;
                    });
                  }
                },
        child: Text(mt('Проверить', 'Test', 'Перевірити')),
      ),
      FilledButton(
        onPressed:
            busy
                ? null
                : () {
                  widget.gs.setAiProvider('', '', '');
                  widget.gs.setGoogleEndpoint(endpoint);
                  widget.gs.setKey(keyCtrl.text);
                  widget.gs.setAiModel(modelCtrl.text);
                  Navigator.pop(context);
                },
        child: Text(mt('Сохранить', 'Save', 'Зберегти')),
      ),
    ],
  );
}
