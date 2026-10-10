# Сборка и запуск только через GitHub (с Linux Mint)

Flutter на ноутбук ставить не нужно.

1. Установите git: `sudo apt install git`
2. Создайте репозиторий на github.com (кнопка New), имя например `techlife`, **Public**
3. Создайте токен для входа: GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic) -> Generate, галочка `repo` и `workflow`
4. В папке проекта:
   git init -b main
   git add .
   git commit -m "TechLife"
   git remote add origin https://github.com/ВАШ_ЛОГИН/techlife.git
   git push -u origin main
   (логин - ваш ник, пароль - токен из шага 3)
5. Репозиторий -> Settings -> Pages -> Source: **GitHub Actions**
6. Вкладка Actions -> Build all platforms -> Run workflow
7. Через 10-15 минут:
   - играть в браузере: https://ВАШ_ЛОГИН.github.io/techlife/
   - файлы: страница запуска -> Artifacts (APK, Windows, Web, неподписанный IPA)
