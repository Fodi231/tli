/// Only unambiguous price offers and explicit acceptance affect bargaining.
/// Device model numbers, storage sizes and questions never count as offers.
double? chatPrice(String text) {
  final match = RegExp(
    r'^\s*(?:(?:предлагаю|дам|за|давай|ну давай|ну за|ладно за|пропоную|давай за|i offer|offer|how about)\s+)?[$€]?\s*(\d+(?:[.,]\d{1,2})?)\s*[$€]?\s*[.!]?\s*$',
    caseSensitive: false,
  ).firstMatch(text);
  return match == null
      ? null
      : double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

bool acceptsCounter(String text) {
  final normalized =
      text
          .toLowerCase()
          .replaceAll(RegExp(r'[.,!…]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  return const {
    'да',
    'давай',
    'хорошо',
    'хорошо давай',
    'да давай',
    'ок',
    'окей',
    'ладно',
    'ладно давай',
    'ну давай',
    'ок давай',
    'да беру',
    'согласен',
    'согласна',
    'договорились',
    'по рукам',
    'беру',
    'устраивает',
    'да согласен',
    'да согласна',
    'так',
    'добре',
    'добре давай',
    'домовились',
    'згоден',
    'згодна',
    'гаразд',
    'мене влаштовує',
    'yes',
    'ok',
    'okay',
    'deal',
    'agreed',
    'sounds good',
    'that works',
    'i agree',
    'i will take it',
    "i'll take it",
    'sure',
    'fine',
    'yes please',
  }.contains(normalized);
}
