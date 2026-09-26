#!/usr/bin/env bash
# Deploy / update sergeybondarenko.pro on a VPS that already has PM2 + nginx.
#
#   ./scripts/deploy.sh              check git, update if origin moved, first-run setup
#   ./scripts/deploy.sh --force      rebuild + restart even when git is unchanged
#   ./scripts/deploy.sh --ssl        только сертификат (когда DNS уже смотрит сюда)
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
SSL_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --ssl) SSL_ONLY=1 ;;
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

node22_home() {
  if [[ -n "${NODE22_HOME:-}" ]]; then
    echo "$NODE22_HOME"
  elif [[ "$(id -u)" -eq 0 ]]; then
    echo /usr/local/lib/node-v22
  else
    echo "$HOME/.local/node-v22"
  fi
}

# Already-installed Node 22, without touching the system Node 20 used by other apps.
prefer_node22_bin() {
  local bin dir home
  home="$(node22_home)"
  if [[ -x "$home/bin/node" ]]; then
    export PATH="$home/bin:$PATH"
    return 0
  fi
  for dir in \
    "$HOME/.nvm/versions/node" \
    /root/.nvm/versions/node \
    "${NVM_DIR:-}/versions/node" \
    /usr/local/n/versions/node
  do
    [[ -d "$dir" ]] || continue
    bin="$(ls -1d "$dir"/v22.*/bin 2>/dev/null | sort -V | tail -n 1 || true)"
    if [[ -n "${bin:-}" && -x "$bin/node" ]]; then
      export PATH="$bin:$PATH"
      return 0
    fi
  done
  return 1
}

node_cpu() {
  case "$(uname -m)" in
    x86_64) echo x64 ;;
    aarch64|arm64) echo arm64 ;;
    *) die "неизвестная архитектура $(uname -m) — нужен linux x64 или arm64" ;;
  esac
}

# Official tarball into NODE22_HOME. Leaves /usr/bin/node (v20) alone.
install_standalone_node22() {
  local dest arch version url tmp extracted
  dest="$(node22_home)"
  if [[ -x "$dest/bin/node" ]]; then
    export PATH="$dest/bin:$PATH"
    return 0
  fi
  command -v curl >/dev/null || die "нужен curl, чтобы скачать Node 22"
  command -v tar >/dev/null || die "нужен tar"

  arch="$(node_cpu)"
  log "Node 22 нет — качаю официальный бинарник в ${dest} (системный $(command -v node 2>/dev/null || echo node) не трогаю)"
  version="$(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt \
    | sed -n "s/.*node-v\\([0-9.]*\\)-linux-${arch}\\.tar\\.xz/\\1/p" \
    | head -n 1)"
  [[ -n "$version" ]] || die "не удалось узнать последнюю Node 22 с nodejs.org"
  url="https://nodejs.org/dist/v${version}/node-v${version}-linux-${arch}.tar.xz"
  tmp="$(mktemp -d)"
  curl -fL "$url" -o "$tmp/node.tar.xz"
  tar -xJf "$tmp/node.tar.xz" -C "$tmp"
  extracted="$(find "$tmp" -maxdepth 1 -type d -name "node-v22*-linux-${arch}" | head -n 1)"
  [[ -n "$extracted" && -d "$extracted" ]] || die "архив Node 22 распаковался не туда"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mv "$extracted" "$dest"
  rm -rf "$tmp"
  [[ -x "$dest/bin/node" ]] || die "после установки нет $dest/bin/node"
  export PATH="$dest/bin:$PATH"
  log "поставил $($dest/bin/node -v) → $dest/bin/node"
}

node_major() {
  node -p "process.versions.node.split('.')[0]"
}

load_node() {
  export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
  prefer_node22_bin || install_standalone_node22
  prefer_node22_bin || true

  command -v node >/dev/null || die "node не найден даже после установки Node 22"
  command -v npm >/dev/null || die "npm не найден."
  command -v pm2 >/dev/null || die "pm2 не найден. На этом сервере он уже должен быть в PATH."

  local major
  major="$(node_major)"
  if (( major < 22 )); then
    die "в PATH всё ещё $(node -v) из $(command -v node). Должен быть ${NODE22_HOME:-/usr/local/lib/node-v22}/bin/node"
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
  issue_ssl || true
}

ssl_ready() {
  command -v nginx >/dev/null || return 1
  [[ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]
}

issue_ssl() {
  if ssl_ready; then
    log "сертификат для ${DOMAIN} уже есть"
    return 0
  fi
  command -v certbot >/dev/null || die "certbot не найден. Поставь: apt install certbot python3-certbot-nginx"
  nginx_configured || die "сначала нужен nginx для ${DOMAIN} — запусти ./scripts/deploy.sh без флагов"

  log "выпускаю HTTPS для ${DOMAIN}"
  if as_root certbot --nginx \
      -d "$DOMAIN" -d "www.${DOMAIN}" \
      --non-interactive --agree-tos \
      --register-unsafely-without-email \
      --redirect; then
    log "HTTPS готов: https://${DOMAIN}"
    return 0
  fi
  if as_root certbot --nginx \
      -d "$DOMAIN" \
      --non-interactive --agree-tos \
      --register-unsafely-without-email \
      --redirect; then
    log "HTTPS готов: https://${DOMAIN} (www не указан в DNS — это нормально)"
    return 0
  fi
  die "certbot не выдал сертификат. Проверь, что A-запись ${DOMAIN} смотрит на этот сервер: dig +short ${DOMAIN}"
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
  if (( SSL_ONLY )); then
    issue_ssl
    return 0
  fi

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
