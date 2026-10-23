import '../i18n.dart';

String rt(String key) {
  final words = _strings[key];
  if (words == null) return key.tr;
  final i = I18n.langs.indexOf(I18n.lang);
  return words[i < 0 ? 0 : i];
}

const _strings = <String, List<String>>{
  'r_workbench': ['Мастерская', 'Workbench', 'Майстерня'],
  'r_live': ['РЕМОНТ · 2D', 'REPAIR · 2D', 'РЕМОНТ · 2D'],
  'r_training': ['Учебный стол', 'Practice bench', 'Навчальний стіл'],
  'r_training_desc': [
    'Замена дисплея • бесплатно • детали включены',
    'Display replacement • free • parts included',
    'Заміна дисплея • безкоштовно • деталі включено',
  ],
  'r_training_done': [
    'Практика завершена. Теперь можно брать заказы.',
    'Practice complete. You are ready for customer orders.',
    'Практику завершено. Тепер можна брати замовлення.',
  ],
  'r_again': ['Ещё раз', 'Practice again', 'Ще раз'],
  'r_2d': ['Ручной ремонт 2D', 'Hands-on 2D repair', 'Ручний ремонт 2D'],
  'r_legacy': ['Классический ремонт', 'Classic repair', 'Класичний ремонт'],
  'r_task': ['ТЕКУЩАЯ ЗАДАЧА', 'CURRENT TASK', 'ПОТОЧНЕ ЗАВДАННЯ'],
  'r_step': ['Этап', 'Step', 'Етап'],
  'r_tools': ['Инструменты', 'Tools', 'Інструменти'],
  'r_hints': ['Подсказки', 'Hints', 'Підказки'],
  'r_saved': [
    'Прогресс сохраняется автоматически',
    'Progress saves automatically',
    'Прогрес зберігається автоматично',
  ],
  'r_exit': ['К заказам', 'Orders', 'До замовлень'],
  'r_help': ['Как играть', 'How to play', 'Як грати'],
  'r_help_body': [
    'Выберите инструмент, затем работайте с деталью. Винт: 3 нажатия. Перетаскивание: удерживайте деталь и ведите в выделенную зону. Прогрев и тест: удерживайте 1,2 секунды. Приближение: щипок или +/−. На ПК: 1–8 — инструменты, H — подсказки, Esc — выйти. Деталь списывается со склада при установке. Учебный стол бесплатный. Это игровая схема, не инструкция по ремонту реального устройства.',
    'Select a tool, then interact with a component. Screw: 3 taps. Drag: move the component to the highlighted zone. Heat and test: hold for 1.2 seconds. Zoom: pinch or +/−. Desktop: 1–8 select tools, H toggles hints, Esc exits. A spare part is consumed when installed. Practice is free. This is a game schematic, not a real device repair guide.',
    'Обери інструмент і працюй із деталлю. Гвинт: 3 натискання. Перетягування: веди деталь у виділену зону. Прогрів і тест: утримуй 1,2 секунди. Наближення: щипок або +/−. На ПК: 1–8 — інструменти, H — підказки, Esc — вихід. Запчастина списується під час встановлення. Навчальний стіл безкоштовний. Це ігрова схема, а не інструкція ремонту справжнього пристрою.',
  ],
  'r_new': ['НОВАЯ ДЕТАЛЬ', 'NEW PART', 'НОВА ДЕТАЛЬ'],
  'r_old': ['СНЯТАЯ ДЕТАЛЬ', 'REMOVED PART', 'ЗНЯТА ДЕТАЛЬ'],
  'r_tray': ['ЛОТОК КРЕПЕЖА', 'PARTS TRAY', 'ЛОТОК КРІПЛЕННЯ'],
  'r_cover_place': ['МЕСТО КРЫШКИ', 'COVER REST', 'МІСЦЕ КРИШКИ'],
  'r_display_place': ['МЕСТО ДИСПЛЕЯ', 'DISPLAY REST', 'МІСЦЕ ДИСПЛЕЯ'],
  'r_installed': ['Установлено', 'Installed', 'Встановлено'],
  'r_in_stock': ['На складе', 'In stock', 'На складі'],
  'r_parts_note': [
    'Запчасти учитываются по категории, как в текущем магазине.',
    'Parts use the existing category-based inventory.',
    'Запчастини обліковуються за категорією, як у поточному магазині.',
  ],
  'r_quality': ['Качество', 'Quality', 'Якість'],
  'r_no_reward': [
    'Учебный ремонт не меняет деньги и репутацию.',
    'Practice does not change money or reputation.',
    'Навчальний ремонт не змінює гроші та репутацію.',
  ],
  'r_wrong_tool': [
    'Нужен другой инструмент',
    'Choose the required tool',
    'Потрібен інший інструмент',
  ],
  'r_wrong_order': [
    'Сначала завершите текущую операцию',
    'Finish the current operation first',
    'Спочатку заверши поточну операцію',
  ],
  'r_wrong_drop': [
    'Перенесите деталь в выделенную зону',
    'Move the part into the highlighted zone',
    'Перенеси деталь у виділену зону',
  ],
  'r_missing_part': [
    'Нет запчасти. Купите её в магазине и вернитесь к столу.',
    'No spare part. Buy one in the shop, then return to the bench.',
    'Немає запчастини. Придбай її в магазині й повернися до столу.',
  ],
  'r_already_done': [
    'Этот ремонт уже завершён',
    'This repair is already complete',
    'Цей ремонт уже завершено',
  ],
  'r_target_done': [
    'Готово. Переходите к следующей точке.',
    'Done. Continue with the next point.',
    'Готово. Переходь до наступної точки.',
  ],
  'r_step_done': ['Этап завершён', 'Step complete', 'Етап завершено'],
  'r_action_done': ['Готово', 'Done', 'Готово'],
  'r_gesture_tap': [
    'Нажмите на деталь',
    'Tap the component',
    'Натисни на деталь',
  ],
  'r_gesture_drag': [
    'Перетащите деталь в указанную зону',
    'Drag the component to its destination',
    'Перетягни деталь у вказану зону',
  ],
  'r_gesture_hold': [
    'Удерживайте на детали 1,2 секунды',
    'Hold the component for 1.2 seconds',
    'Утримуй на деталі 1,2 секунди',
  ],
  'r_tool_hand': ['Рука', 'Hand', 'Рука'],
  'r_tool_driver': ['Отвёртка', 'Driver', 'Викрутка'],
  'r_tool_heater': ['Прогрев', 'Heat', 'Прогрів'],
  'r_tool_suction': ['Присоска', 'Suction', 'Присоска'],
  'r_tool_spudger': ['Лопатка', 'Spudger', 'Лопатка'],
  'r_tool_tweezers': ['Пинцет', 'Tweezers', 'Пінцет'],
  'r_tool_meter': ['Тестер', 'Tester', 'Тестер'],
  'r_step_diagnose': [
    'Диагностика неисправности',
    'Diagnose the fault',
    'Діагностика несправності',
  ],
  'r_hint_diagnose': [
    'Тестер · удерживайте на экране.',
    'Tester · hold on the screen.',
    'Тестер · утримуй на екрані.',
  ],
  'r_step_power_off': [
    'Выключить устройство',
    'Power off the device',
    'Вимкнути пристрій',
  ],
  'r_hint_power_off': [
    'Рука · удерживайте боковую кнопку.',
    'Hand · hold the side button.',
    'Рука · утримуй бічну кнопку.',
  ],
  'r_step_frame_out': [
    'Открутить нижние винты',
    'Remove the bottom screws',
    'Відкрутити нижні гвинти',
  ],
  'r_hint_frame_out': [
    'Отвёртка · по 3 нажатия на каждый из двух винтов.',
    'Driver · tap each of the two screws 3 times.',
    'Викрутка · по 3 натискання на кожен із двох гвинтів.',
  ],
  'r_step_heat': [
    'Размягчить клей дисплея',
    'Soften the display adhesive',
    'Розм’якшити клей дисплея',
  ],
  'r_hint_heat': [
    'Прогрев · удерживайте на экране.',
    'Heat · hold on the screen.',
    'Прогрів · утримуй на екрані.',
  ],
  'r_step_flip_front': [
    'Перевернуть корпус экраном вверх',
    'Turn the chassis screen-up',
    'Перевернути корпус екраном догори',
  ],
  'r_hint_flip_front': [
    'Выбери руку и нажми на корпус.',
    'Choose the hand and tap the chassis.',
    'Обери руку й натисни на корпус.',
  ],
  'r_step_display_heat': [
    'Ослабить клей дисплея',
    'Soften display adhesive',
    'Послабити клей дисплея',
  ],
  'r_hint_display_heat': [
    'Удерживай нагреватель на переднем дисплее.',
    'Hold the heater over the front display.',
    'Утримуй нагрівач на передньому дисплеї.',
  ],
  'r_step_flip_back': [
    'Перевернуть корпус обратно',
    'Turn the chassis back',
    'Перевернути корпус назад',
  ],
  'r_hint_flip_back': [
    'Выбери руку и нажми на корпус для подключения шлейфов.',
    'Choose the hand and tap the chassis to reconnect the cables.',
    'Обери руку й натисни на корпус для підключення шлейфів.',
  ],
  'r_step_open_back': [
    'Снять заднюю крышку',
    'Lift the rear cover',
    'Зняти задню кришку',
  ],
  'r_hint_open_back': [
    'Перетащи прогретую заднюю крышку вправо на подставку.',
    'Drag the heated rear cover onto the right stand.',
    'Перетягни прогріту задню кришку праворуч на підставку.',
  ],
  'r_step_close_back': [
    'Закрыть заднюю крышку',
    'Refit the rear cover',
    'Закрити задню кришку',
  ],
  'r_hint_close_back': [
    'Верни крышку на корпус после подключения шлейфов.',
    'Return the cover after reconnecting the flex cables.',
    'Поверни кришку після підключення шлейфів.',
  ],
  'r_step_open': ['Открыть дисплей', 'Lift the display', 'Відкрити дисплей'],
  'r_hint_open': [
    'Присоска · перетащите экран вправо.',
    'Suction · drag the display to the right.',
    'Присоска · перетягни екран праворуч.',
  ],
  'r_step_shield_screws_out': [
    'Открутить защиту шлейфов',
    'Unscrew the cable shield',
    'Відкрутити захист шлейфів',
  ],
  'r_hint_shield_screws_out': [
    'Отвёртка · все выделенные винты, по 3 оборота.',
    'Driver · all highlighted screws, 3 turns each.',
    'Викрутка · усі виділені гвинти, по 3 оберти.',
  ],
  'r_step_shield_out': [
    'Снять защитную пластину',
    'Remove the cable shield',
    'Зняти захисну пластину',
  ],
  'r_hint_shield_out': [
    'Пинцет · перенесите пластину в лоток крепежа.',
    'Tweezers · drag the shield to the parts tray.',
    'Пінцет · перенеси пластину в лоток кріплення.',
  ],
  'r_step_battery_off': [
    'Отключить батарею',
    'Disconnect the battery',
    'Від’єднати батарею',
  ],
  'r_hint_battery_off': [
    'Лопатка · нажмите на выделенный коннектор батареи.',
    'Spudger · tap the highlighted battery connector.',
    'Лопатка · натисни на виділений конектор батареї.',
  ],
  'r_step_part_off': [
    'Отключить шлейф детали',
    'Disconnect the component cable',
    'Від’єднати шлейф деталі',
  ],
  'r_hint_part_off': [
    'Лопатка · нажмите на верхний коннектор.',
    'Spudger · tap the upper connector.',
    'Лопатка · натисни на верхній конектор.',
  ],
  'r_tool_solvent': ['IPA', 'IPA', 'IPA'],
  'r_step_adhesive_soften': [
    'Ослабить клей батареи',
    'Soften battery adhesive',
    'Послабити клей батареї',
  ],
  'r_hint_adhesive_soften': [
    'IPA · удерживай у выделенного края батареи.',
    'IPA · hold at the highlighted battery edge.',
    'IPA · утримуй біля виділеного краю батареї.',
  ],
  'r_step_adhesive_handle': [
    'Поднять язычок батареи',
    'Lift the battery pull handle',
    'Підняти язичок батареї',
  ],
  'r_hint_adhesive_handle': [
    'Перетащи синий язычок в лоток.',
    'Drag the blue pull handle to the tray.',
    'Перетягни синій язичок у лоток.',
  ],
  'r_step_adhesive_out': [
    'Вытянуть клеевые полоски',
    'Pull the adhesive strips',
    'Витягнути клейкі смужки',
  ],
  'r_hint_adhesive_out': [
    'Пинцет · перетащите обе полоски в лоток.',
    'Tweezers · drag both strips into the tray.',
    'Пінцет · перетягни обидві смужки в лоток.',
  ],
  'r_step_part_screws_out': [
    'Открутить крепления детали',
    'Unscrew the component',
    'Відкрутити кріплення деталі',
  ],
  'r_hint_part_screws_out': [
    'Отвёртка · по 3 оборота на крепление.',
    'Driver · 3 turns per screw.',
    'Викрутка · по 3 оберти на кріплення.',
  ],
  'r_step_part_out': [
    'Снять неисправную деталь',
    'Remove the faulty component',
    'Зняти несправну деталь',
  ],
  'r_hint_part_out': [
    'Пинцет · перетащите деталь в лоток снятых деталей.',
    'Tweezers · drag the component to the removed-parts tray.',
    'Пінцет · перетягни деталь у лоток знятих деталей.',
  ],
  'r_step_part_in': [
    'Установить новую деталь',
    'Install the replacement',
    'Встановити нову деталь',
  ],
  'r_hint_part_in': [
    'Пинцет · перенесите новую деталь на её место.',
    'Tweezers · drag the new part into its socket.',
    'Пінцет · перенеси нову деталь на її місце.',
  ],
  'r_step_part_screws_in': [
    'Закрепить новую деталь',
    'Secure the replacement',
    'Закріпити нову деталь',
  ],
  'r_hint_part_screws_in': [
    'Отвёртка · затяните каждое крепление.',
    'Driver · tighten each screw.',
    'Викрутка · затягни кожне кріплення.',
  ],
  'r_step_adhesive_in': [
    'Зафиксировать батарею',
    'Secure the battery',
    'Зафіксувати батарею',
  ],
  'r_hint_adhesive_in': [
    'Рука · удерживайте на новой батарее.',
    'Hand · hold on the new battery.',
    'Рука · утримуй на новій батареї.',
  ],
  'r_step_part_on': [
    'Подключить шлейф детали',
    'Connect the component cable',
    'Приєднати шлейф деталі',
  ],
  'r_hint_part_on': [
    'Лопатка · нажмите на верхний коннектор.',
    'Spudger · tap the upper connector.',
    'Лопатка · натисни на верхній конектор.',
  ],
  'r_step_battery_on': [
    'Подключить батарею',
    'Reconnect the battery',
    'Приєднати батарею',
  ],
  'r_hint_battery_on': [
    'Лопатка · нажмите на выделенный коннектор батареи.',
    'Spudger · tap the highlighted battery connector.',
    'Лопатка · натисни на виділений конектор батареї.',
  ],
  'r_step_shield_in': [
    'Вернуть защитную пластину',
    'Refit the cable shield',
    'Повернути захисну пластину',
  ],
  'r_hint_shield_in': [
    'Пинцет · перенесите пластину из лотка на коннекторы.',
    'Tweezers · move the shield from the tray onto the connectors.',
    'Пінцет · перенеси пластину з лотка на конектори.',
  ],
  'r_step_shield_screws_in': [
    'Закрутить защиту шлейфов',
    'Secure the cable shield',
    'Закрутити захист шлейфів',
  ],
  'r_hint_shield_screws_in': [
    'Отвёртка · затяните 3 винта.',
    'Driver · tighten all 3 screws.',
    'Викрутка · затягни 3 гвинти.',
  ],
  'r_step_close': ['Закрыть дисплей', 'Close the display', 'Закрити дисплей'],
  'r_hint_close': [
    'Присоска · перенесите дисплей обратно на корпус.',
    'Suction · drag the display back onto the chassis.',
    'Присоска · перенеси дисплей назад на корпус.',
  ],
  'r_step_seal': [
    'Прижать уплотнитель',
    'Press the display seal',
    'Притиснути ущільнювач',
  ],
  'r_hint_seal': [
    'Рука · удерживайте на собранном экране.',
    'Hand · hold on the closed display.',
    'Рука · утримуй на складеному екрані.',
  ],
  'r_step_frame_in': [
    'Закрутить нижние винты',
    'Refit the bottom screws',
    'Закрутити нижні гвинти',
  ],
  'r_hint_frame_in': [
    'Отвёртка · оба винта, по 3 оборота.',
    'Driver · both screws, 3 turns each.',
    'Викрутка · обидва гвинти, по 3 оберти.',
  ],
  'r_step_test': [
    'Финальная проверка',
    'Final functional test',
    'Фінальна перевірка',
  ],
  'r_hint_test': [
    'Тестер · удерживайте на каждой из 3 тестовых зон.',
    'Tester · hold on each of the 3 test zones.',
    'Тестер · утримуй на кожній із 3 тестових зон.',
  ],
  'r_test_screen': ['Экран', 'Display', 'Екран'],
  'r_test_camera': ['Камера', 'Camera', 'Камера'],
  'r_test_charge': ['Питание', 'Power', 'Живлення'],
};
