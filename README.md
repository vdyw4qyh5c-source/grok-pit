# grok-pit

Визитка питомника **Сергей Петрович / pitomnikmoscow** для домена [sergeybondarenko.pro](https://sergeybondarenko.pro).

Страницы: главная со ссылками, породы и цены, как добраться. Аккаунтов и базы нет — контент в `src/data/profile.ts`.

## Стек

React 19, TanStack Start / Router, Vite 8, Tailwind v4, Nitro. На VPS крутится как обычный Node-процесс через PM2, снаружи его закрывает nginx.

## Локально

Нужен Node 22.

```bash
npm install
npm run dev
```

Сайт на `http://localhost:8080`.

```bash
npm run build        # сборка под Vercel (дефолт платформы)
npm run build:vps    # сборка Node-сервера для VPS
npm run typecheck
```

## Деплой на VPS

Сервер уже с PM2 и другими сайтами. Этот проект их не трогает: слушает только `127.0.0.1:38471`, в nginx прописан только `sergeybondarenko.pro`. Имя процесса PM2: `sergeybondarenko`. Параметры — `deploy/config.env`.

### Один раз с компьютера

```bash
git add .
git commit -m "Prepare VPS deploy"
git remote add origin <url>
git push -u origin main
```

### Node 22 на сервере

TanStack Start не собирается на Node 20. Системный Node других проектов не трогаем — ставим 22 через nvm:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 22
```

Скрипт деплоя сам сделает `nvm use 22` (и поставит 22, если nvm уже есть).

### Один раз на сервере

1. A-запись `sergeybondarenko.pro` (и при необходимости `www`) на IP VPS.
2. Клонировать репозиторий, например в `/var/www/sergeybondarenko`.
3. Запустить первый деплой:

```bash
cd /var/www/sergeybondarenko
./scripts/deploy.sh
```

Скрипт соберёт приложение, поднимет его в PM2 и при первом запуске настроит nginx на этот домен. Если есть certbot — попробует выпустить HTTPS.

Проверка git каждые 3 минуты:

```bash
./scripts/deploy.sh --install-cron
```

### Дальше

Пуш в git. На сервере cron сам подтянет изменения, пересоберёт и перезапустит PM2.

Вручную то же самое:

```bash
./scripts/deploy.sh          # обновить, только если origin ушёл вперёд
./scripts/deploy.sh --force  # пересобрать в любом случае
```

Логи приложения: `pm2 logs sergeybondarenko`. Лог автодеплоя (если включён cron): `deploy/deploy.log`.
