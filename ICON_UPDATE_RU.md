# Обновление иконки TechLife

23 октября 2026. Версия: TechLife 0.7.0+8 с автоматическим ИИ. Использовано новое присланное изображение устройств с надписью TechLife без перерисовки. Полное обновление интерфейса описано в UPDATE_0_7_RU.md.

## Исходный Flutter-проект

Скопируй из архива поверх своего проекта эти файлы:

```text
assets/icon/icon.png
assets/icon/icon_fg.png
assets/icon/icon_maskable.png
assets/icon/app_icon.ico
icon_cfg/web.yaml
```

Обычный PNG — 1024×1024, без прозрачности. ICO содержит размеры 16, 24, 32, 48, 64, 128 и 256. Android foreground и Web maskable имеют поля, чтобы системная маска не обрезала надпись.

GitHub workflow уже генерирует иконки Android/iOS/Web из этих файлов и копирует ICO для Windows. Запусти обычную сборку. Для локального проекта с уже созданными папками платформ сначала выполни нужную команду:

```bash
flutter pub get
dart run flutter_launcher_icons -f icon_cfg/android.yaml
dart run flutter_launcher_icons -f icon_cfg/ios.yaml
dart run flutter_launcher_icons -f icon_cfg/web.yaml
```

Команды предназначены для соответствующих существующих папок `android/`, `ios/`, `web/`; выполнять все три для одной платформы не нужно. Для Windows скопируй `assets/icon/app_icon.ico` в `windows/runner/resources/app_icon.ico` и пересобери приложение. Собранные APK/EXE/IPA не меняются заменой исходного изображения: требуется новая сборка.

## Готовая Web-версия

Для отдельной замены иконки Web-версии замени следующие файлы относительно корня публикации:

```text
favicon.png
icons/Icon-192.png
icons/Icon-512.png
icons/Icon-maskable-192.png
icons/Icon-maskable-512.png
assets/assets/icon/icon.png
manifest.json
index.html
```

Они лежат в `web_release/` архива. Для обновления интерфейса до 0.7.0 используй весь новый web_release/, включая JavaScript игры. Для более старой Web-версии используй полный `web_release/` из полного архива, чтобы сохранить обновление ИИ. Если браузер или система показывает прежнюю иконку, обнови страницу; установленную PWA иногда нужно удалить с домашнего экрана и добавить снова.

## Проверка

Проверены размеры всех PNG, отсутствие alpha-канала в основной иконке, семь кадров ICO и совпадение изображения в Web bundle с основной иконкой. Вариант с круглой маской осмотрен визуально. В 0.7.0 пройдены 66 тестов и выполнена release-сборка Web. Нативные пакеты и физические устройства не проверялись. Результаты — в VALIDATION.md.

`GAME_IDEAS_RU.md` содержит предложения по развитию; они не включены в игру автоматически.
