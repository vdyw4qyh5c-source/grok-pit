#!/usr/bin/env bash
# Deploy / update sergeybondarenko.pro on a VPS that already has PM2 + nginx.
#
#   ./scripts/deploy.sh              check git, update if origin moved, first-run setup
#   ./scripts/deploy.sh --force      rebuild + restart even when git is unchanged
#   ./scripts/deploy.sh --install-cron
#
# Safe around other sites: binds 127.0.0.1:38471 only, nginx server_name is
# exclusive to this domain, never runs `pm2 startup`.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source "$ROOT/deploy/config.env"

APP_NAME="${APP_NAME:-sergeybondarenko}"
DOMAIN="${DOMAIN:-sergeybondarenko.pro}"
PORT="${PORT:-38471}"
HOST="${HOST:-127.0.0.1}"
BRANCH="${BRANCH:-main}"
NITRO_PRESET="${NITRO_PRESET:-node-server}"
REMOTE="${REMOTE:-origin}"
LOCK_FILE="${LOCK_FILE:-/tmp/${APP_NAME}.deploy.lock}"

FORCE=0
INSTALL_CRON=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --install-cron) INSTALL_CRON=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

log() { printf '[deploy] %s\n' "$*"; }
die() { printf '[deploy] ERROR: %s\n' "$*" >&2; exit 1; }

load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
    return 0
  fi
  if [[ -s /usr/local/nvm/nvm.sh ]]; then
    # shellcheck disable=SC1091
    source /usr/local/nvm/nvm.sh
    return 0
  fi
  return 1
}

node_major() {
  node -p "process.versions.node.split('.')[0]"
}

# TanStack Start needs >=22.12. Prefer nvm so other apps on Node 20 stay untouched.
load_node() {
  export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
  load_nvm || true

  if command -v nvm >/dev/null 2>&1; then
    if nvm use 22 >/dev/null 2>&1 || nvm install 22; then
      nvm use 22 >/dev/null
    fi
  fi

  command -v node >/dev/null || die "node не найден. Поставь Node 22: nvm install 22"
  command -v npm >/dev/null || die "npm не найден."
  command -v pm2 >/dev/null || die "pm2 не найден. На этом сервере он уже должен быть в PATH."

  local major
  major="$(node_major)"
  if (( major < 22 )); then
    die "нужен Node 22.12+ (сейчас $(node -v)). Другие проекты не трогаем — поставь отдельно: nvm install 22 && nvm use 22"
  fi
  export NODE_BIN
  NODE_BIN="$(command -v node)"
  log "node $($NODE_BIN -v) ($NODE_BIN)"
}

with_lock() {
  if command -v flock >/dev/null; then
    exec 9>"$LOCK_FILE"
    flock -n 9 || die "деплой уже идёт (lock $LOCK_FILE)"
  fi
}

git_ready() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "это не git-репозиторий"
  git remote get-url "$REMOTE" >/dev/null 2>&1 || die "нет remote «$REMOTE» — добавь origin и запушь код"
}

current_branch() {
  local b
  b="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$b" == "HEAD" ]]; then
    echo "$BRANCH"
  else
    echo "$b"
  fi
}

git_has_updates() {
  local branch remote_ref local_sha remote_sha
  branch="$(current_branch)"
  git fetch --quiet "$REMOTE" "$branch"
  remote_ref="$REMOTE/$branch"
  git rev-parse --verify "$remote_ref" >/dev/null 2>&1 || die "нет $remote_ref после fetch"
  local_sha="$(git rev-parse HEAD)"
  remote_sha="$(git rev-parse "$remote_ref")"
  [[ "$local_sha" != "$remote_sha" ]]
}

pull_updates() {
  local branch
  branch="$(current_branch)"
  if [[ -n "$(git status --porcelain)" ]]; then
    log "на сервере есть локальные правки — stash, чтобы pull прошёл"
    git stash push -u -m "deploy-auto-stash $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null
  fi
  git pull --ff-only "$REMOTE" "$branch"
}

build_exists() {
  [[ -f "$ROOT/.output/server/index.mjs" ]]
}

pm2_running() {
  pm2 describe "$APP_NAME" >/dev/null 2>&1
}

nginx_site_path() {
  if [[ -d /etc/nginx/sites-available ]]; then
    echo "/etc/nginx/sites-available/${DOMAIN}"
  else
    echo "/etc/nginx/conf.d/${DOMAIN}.conf"
  fi
}

nginx_configured() {
  local path
  path="$(nginx_site_path)"
  [[ -f "$path" ]] && grep -q "sergeybondarenko-managed" "$path"
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    command -v sudo >/dev/null || die "sudo не найден — nginx без него не настроить"
    sudo "$@"
  fi
}

render_nginx() {
  sed -e "s/__DOMAIN__/${DOMAIN}/g" -e "s/__PORT__/${PORT}/g" \
    "$ROOT/deploy/nginx.conf.tpl"
}

ensure_nginx() {
  if nginx_configured; then
    log "nginx для ${DOMAIN} уже есть — не трогаю (чтобы не стереть certbot)"
    return 0
  fi
  command -v nginx >/dev/null || die "nginx не найден"

  local dest enabled
  dest="$(nginx_site_path)"
  log "первый деплой: пишу nginx ${dest} → 127.0.0.1:${PORT}"
  render_nginx | as_root tee "$dest" >/dev/null

  if [[ -d /etc/nginx/sites-enabled ]]; then
    enabled="/etc/nginx/sites-enabled/${DOMAIN}"
    if [[ ! -e "$enabled" ]]; then
      as_root ln -s "$dest" "$enabled"
    fi
  fi

  as_root nginx -t
  if command -v systemctl >/dev/null && systemctl is-active --quiet nginx; then
    as_root systemctl reload nginx
  else
    as_root nginx -s reload
  fi
  log "nginx смотрит ${DOMAIN} на это приложение"

  if command -v certbot >/dev/null; then
    log "пробую выпустить HTTPS через certbot"
    as_root certbot --nginx \
      -d "$DOMAIN" -d "www.${DOMAIN}" \
      --non-interactive --agree-tos \
      --register-unsafely-without-email \
      --redirect \
      || as_root certbot --nginx \
        -d "$DOMAIN" \
        --non-interactive --agree-tos \
        --register-unsafely-without-email \
        --redirect \
      || log "certbot не выдал сертификат (часто DNS ещё не смотрит сюда). HTTP уже работает. Позже: sudo certbot --nginx -d ${DOMAIN}"
  else
    log "certbot нет — сайт на HTTP. Потом: sudo certbot --nginx -d ${DOMAIN}"
  fi
}

ensure_pm2() {
  build_exists || die "нет сборки .output/server/index.mjs — сначала npm run build:vps"

  if pm2_running; then
    log "перезапускаю pm2 ${APP_NAME}"
  else
    log "первый запуск pm2 ${APP_NAME} на ${HOST}:${PORT}"
  fi
  pm2 startOrReload "$ROOT/ecosystem.config.cjs" --update-env
  pm2 save
}

install_deps() {
  if npm ci; then
    return 0
  fi
  log "npm ci не сошёлся с lock — ставлю через npm install"
  npm install --no-audit --no-fund
}

build_app() {
  log "зависимости + сборка (NITRO_PRESET=${NITRO_PRESET})"
  install_deps
  if ! NITRO_PRESET="$NITRO_PRESET" npm run build:vps || ! build_exists; then
    log "повтор сборки с NITRO_PRESET=node_server (Nitro 3)"
    NITRO_PRESET=node_server npm run build:vps
  fi
  build_exists || die "сборка прошла, но нет .output/server/index.mjs — проверь NITRO_PRESET"
}

wait_healthy() {
  local i url
  url="http://${HOST}:${PORT}/"
  if ! command -v curl >/dev/null; then
    log "curl нет — пропускаю health-check, смотри pm2 logs ${APP_NAME}"
    return 0
  fi
  for i in $(seq 1 30); do
    if curl -fsS -o /dev/null --max-time 2 "$url"; then
      log "приложение отвечает на ${url}"
      return 0
    fi
    sleep 1
  done
  die "процесс не ответил на ${url} за 30с — смотри pm2 logs ${APP_NAME}"
}

install_cron() {
  local line cron
  line="*/3 * * * * cd ${ROOT} && /usr/bin/env bash ${ROOT}/scripts/deploy.sh >> ${ROOT}/deploy/deploy.log 2>&1"
  cron="$(crontab -l 2>/dev/null || true)"
  if printf '%s\n' "$cron" | grep -Fq "$ROOT/scripts/deploy.sh"; then
    log "cron уже стоит"
    return 0
  fi
  { printf '%s\n' "$cron"; printf '%s\n' "$line"; } | crontab -
  log "cron: каждые 3 минуты проверяет git"
}

main() {
  load_node
  with_lock

  if (( INSTALL_CRON )); then
    git_ready
    install_cron
    return 0
  fi

  git_ready

  local updated=0
  if git_has_updates; then
    log "на ${REMOTE} есть новые коммиты"
    pull_updates
    updated=1
  else
    log "git без изменений ($(git rev-parse --short HEAD))"
  fi

  local first=0
  if ! build_exists || ! pm2_running || ! nginx_configured; then
    first=1
  fi

  if (( updated || FORCE || first )); then
    if (( FORCE )); then
      log "принудительная пересборка (--force)"
    elif (( first && ! updated )); then
      log "первый деплой или окружение ещё не собрано"
    fi
    build_app
    ensure_nginx
    ensure_pm2
    wait_healthy
    log "готово: https://${DOMAIN}  (локально ${HOST}:${PORT}, pm2 ${APP_NAME})"
  else
    if ! pm2_running; then
      ensure_pm2
      wait_healthy
    else
      log "обновлений нет, ${APP_NAME} уже запущен — выхожу"
    fi
  fi
}

main
