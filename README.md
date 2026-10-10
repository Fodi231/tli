# TechLife — симулятор ремонта, покупки и перепродажи техники

Flutter-проект по вашему макету. Один код собирается в Android (APK), iOS (IPA), Windows (EXE) и Web.

## Что уже есть (MVP)

- Экран блокировки → главный экран с иконками, баланс и репутация, док, анимация открытия приложений
- **Работа** — заказы на ремонт (генерируются со временем), принятие, расстояние до клиента
- **Ремонт** — мини-игра: нажимайте шаги в правильном порядке (сертификат «Основы ремонта» показывает номера шагов). Ошибки снижают награду и репутацию
- **Магазин** — запчасти по категориям с поиском
- **Склад** — запчасти и купленные устройства, кнопка «Найти покупателя»
- **Сообщения** — торг с продавцами и покупателями. Решение (согласен / контрпредложение / уходит) принимает игровая логика, а **текст реплик пишет Google Gemini**. Без ключа работают офлайн-фразы
- **Карта** — настоящая OpenStreetMap, 3 города (Токио, Лос-Анджелес, Милан), заказы и магазины как маркеры, перемещение тапом по карте (платный проезд), перелёт между городами
- **Банк** — кредит, инвестиции с колебаниями курса, налоги (10% с дохода), страховка, история операций
- **Обучение** — цепочка курсов с сертификатами (+5% к наградам за каждый)
- Статистика, достижения, уведомления, настройки (язык RU / EN / UK, ключ Gemini, сброс)
- Автосохранение (shared_preferences)

**Заглушки «Скоро»:** Почта, Аукцион, Транспорт, Сотрудники, Календарь. Это следующий этап (аукционы, собственный сервис с сотрудниками).

> Важно: код написан без возможности скомпилировать его в моей среде (там нет Flutter SDK). Возможны мелкие ошибки компиляции. Если `flutter run` выдаст ошибку, пришлите текст, и я сразу исправлю.

## 1. Установка

1. Установите Flutter: https://docs.flutter.dev/get-started/install
2. Проверьте: `flutter doctor`
3. Распакуйте проект и в его папке выполните (создаёт папки платформ `android/`, `ios/`, `windows/`, `web/`, ваш код не трогает):

```bash
flutter create --platforms=android,ios,windows,web .
flutter pub get
```

## 2. Бесплатный ИИ (Google Gemini)

1. Откройте https://aistudio.google.com/apikey и создайте бесплатный ключ
2. В игре: **Настройки → Ключ Google Gemini API → Сохранить**

Модель задаётся в `lib/core/ai_service.dart` (`model = 'gemini-flash-latest'`). Если лимит бесплатного тарифа исчерпан или нет интернета, игра автоматически переходит на офлайн-фразы.

Ключ хранится только на устройстве игрока. Для публичного релиза лучше проксировать запросы через свой сервер, чтобы не раздавать ключ.

### Встроенный ключ (без публикации в коде)
Ключ **не записан в исходники**, чтобы он не попал в открытый репозиторий. Он подставляется при сборке из секрета GitHub:

1. Репозиторий → **Settings → Secrets and variables → Actions → New repository secret**
2. Name: `GEMINI_API_KEY`, Secret: ваш ключ → **Add secret**
3. Запустите сборку заново. Ключ попадёт в APK, EXE и IPA. В **веб-версию он намеренно не добавляется**: сайт публичный, и ключ можно было бы вытащить из его кода. В вебе игрок вводит свой ключ в Настройки → ИИ и сеть.

Локально: `flutter run --dart-define=GEMINI_API_KEY=ваш_ключ`.
Любой ключ внутри клиентского приложения можно извлечь, поэтому в Google AI Studio / Cloud Console ограничьте его API «Generative Language API» и поставьте квоту.

## 3. Запуск для разработки

```bash
flutter run -d chrome      # веб
flutter run -d windows     # Windows
flutter run                # подключённый телефон / эмулятор
```

## 4. Сборка

### Android (APK)
Перед релизной сборкой добавьте разрешение интернета в `android/app/src/main/AndroidManifest.xml` (над `<application`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Затем:

```bash
flutter build apk --release
# файл: build/app/outputs/flutter-apk/app-release.apk
```
Для Google Play: `flutter build appbundle --release` и подпись своим ключом (https://docs.flutter.dev/deployment/android).

### Windows (EXE)
Нужен Windows 10/11 и Visual Studio 2022 с компонентом «Desktop development with C++».

```bash
flutter build windows --release
# папка: build/windows/x64/runner/Release  (раздавайте всю папку, а не один .exe)
```

### iOS (IPA)
Только на Mac с Xcode и аккаунтом Apple Developer.

```bash
flutter build ipa --release
# файл: build/ios/ipa/*.ipa
```
Нет Mac? Используйте сборку в GitHub Actions (п. 5) — получите неподписанный IPA, подписать его можно позже.

### Web
```bash
flutter build web --release
# папка: build/web
```
Выложите содержимое `build/web` на любой статический хостинг: GitHub Pages, Netlify, Firebase Hosting, Cloudflare Pages. Если сайт лежит не в корне домена, добавьте `--base-href "/имя-папки/"`.

## 5. Сборка всех платформ в облаке (без Mac и Windows)

1. Создайте репозиторий на GitHub и загрузите проект (вместе с папкой `.github`)
2. Вкладка **Actions → Build all platforms → Run workflow**
3. Через несколько минут внизу страницы запуска скачайте артефакты: APK, Windows, Web, неподписанный IPA

## 6. Заметки

- Карта берёт плитки с `tile.openstreetmap.org` — для небольшого проекта это нормально, для большого трафика возьмите коммерческий провайдер (MapTiler, Stadia, Mapbox) и поменяйте `urlTemplate` в `lib/ui/apps/map_app.dart`.
- Названия городов и координаты: `lib/core/catalog.dart`. Новый город — одна строка в списке `cities`.
- Все тексты: `lib/core/i18n.dart` (ru / en / uk в одном месте).
- Баланс игры (цены, награды, налоги, шанс заказов): `lib/core/catalog.dart` и `lib/core/game_state.dart`.

## Структура

```
lib/
  main.dart
  core/   game_state.dart · ai_service.dart · catalog.dart · models.dart · i18n.dart · theme.dart
  ui/     phone_shell.dart (экран блокировки, главный экран) · shell.dart · widgets.dart
  ui/apps/  orders · repair · shop · storage · messages · map · bank · learning · stats · achievements · notifications · settings
```
