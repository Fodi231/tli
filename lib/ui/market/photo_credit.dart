import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/market/market_strings.dart';

Future<void> showPhotoCredit(BuildContext context, String deviceId) async {
  final records =
      jsonDecode(await rootBundle.loadString('assets/market/sources.json'))
          as List;
  final source =
      records
          .cast<Map<String, dynamic>>()
          .where((r) => r['id'] == deviceId)
          .firstOrNull;
  if (!context.mounted || source == null) return;
  await showDialog<void>(
    context: context,
    builder:
        (c) => AlertDialog(
          title: Text(
            mt('Источник изображения', 'Image credit', 'Джерело зображення'),
          ),
          content: SingleChildScrollView(
            child: SelectableText(
              '${source['title']}\n\n© ${source['author']}\n${source['license']}\n${source['licenseUrl']}\n\n${source['source']}\n\n${source['changes']}\n\n${mt("Изменения: уменьшение и конвертация в JPEG. Лицензия исходного изображения сохранена. Фото иллюстрирует модель, а не состояние игрового лота.", "Changes: resized and converted to JPEG. Original image license retained. The image illustrates the model, not the condition of the game listing.", "Зміни: зменшення та конвертація в JPEG. Ліцензію зображення збережено. Фото ілюструє модель, а не стан ігрового лота.")}\n${deviceId == 'pixel7' ? mt("Pixel 7: иллюстрация модели.", "Pixel 7: model illustration.", "Pixel 7: ілюстрація моделі.") : ""}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(mt('Закрыть', 'Close', 'Закрити')),
            ),
          ],
        ),
  );
}
