import '../i18n.dart';
import '../catalog.dart';
import 'market_models.dart';

String mt(String ru, String en, String uk) =>
    I18n.lang == 'en'
        ? en
        : I18n.lang == 'uk'
        ? uk
        : ru;
String faultText(String? fault) =>
    fault == null
        ? mt('Исправен', 'Working', 'Справний')
        : (services[fault]?.nameKey.tr ?? fault);
String marketDescription(MarketListing l) =>
    '${l.device.name}. ${l.device.facts}.\n\n${l.damaged ? mt("Продаю для ремонта. Заявленная неисправность: ${faultText(l.fault)}. Учтена в цене. Остальные узлы требуют проверки мастером.", "For repair. Declared issue: ${faultText(l.fault)}. Priced accordingly; other components need inspection.", "Продаю для ремонту. Заявлена несправність: ${faultText(l.fault)}. Враховано в ціні. Інші вузли потребують перевірки майстром.") : mt("Личный телефон, продаю после обновления. Заявленных неисправностей нет. Можно осмотреть перед покупкой.", "Personal phone, selling after an upgrade. No declared faults. Inspection is welcome.", "Власний телефон, продаю після оновлення. Заявлених несправностей немає. Можна оглянути перед купівлею.")}\n\n${mt("Торг обсуждается в сообщениях. Фото иллюстрирует модель; состояние указано в объявлении.", "Negotiate in messages. The image illustrates the model; condition is described in this listing.", "Торг обговорюється в повідомленнях. Фото ілюструє модель; стан вказано в оголошенні.")}';
