#!/bin/sh
set -eu

# Railway allows one volume per service. Persist music, art, search indexes,
# and APP_KEY under /data (mount the volume there).
DATA_ROOT="${KOEL_DATA_ROOT:-/data}"
mkdir -p \
  "${DATA_ROOT}/music" \
  "${DATA_ROOT}/images" \
  "${DATA_ROOT}/search-indexes"

# Point image defaults at the consolidated volume without fighting VOLUME dirs.
export MEDIA_PATH="${MEDIA_PATH:-${DATA_ROOT}/music}"

link_dir() {
  target="$1"
  link="$2"
  mkdir -p "$target"
  if [ -L "$link" ]; then
    return 0
  fi
  if [ -d "$link" ] && [ -z "$(ls -A "$link" 2>/dev/null || true)" ]; then
    rmdir "$link" 2>/dev/null || rm -rf "$link"
  elif [ -e "$link" ] && [ ! -L "$link" ]; then
    # Preserve any first-boot contents into the volume, then replace with symlink.
    cp -a "$link/." "$target/" 2>/dev/null || true
    rm -rf "$link"
  fi
  ln -sfn "$target" "$link"
}

link_dir "${DATA_ROOT}/music" /music
link_dir "${DATA_ROOT}/images" /var/www/html/storage/app/public/images
link_dir "${DATA_ROOT}/search-indexes" /var/www/html/storage/search-indexes

chown -R www-data:www-data \
  "${DATA_ROOT}/music" \
  "${DATA_ROOT}/images" \
  "${DATA_ROOT}/search-indexes" \
  /music \
  /var/www/html/storage/app/public/images \
  /var/www/html/storage/search-indexes \
  2>/dev/null || true

# koel-init requires a real .env file even when vars are also injected by Railway.
if [ -z "${APP_KEY:-}" ]; then
  if [ -f "${DATA_ROOT}/.app_key" ]; then
    APP_KEY="$(cat "${DATA_ROOT}/.app_key")"
  else
    # Avoid artisan bootstrap before .env exists; Laravel expects base64:<32-bytes>.
    APP_KEY="base64:$(openssl rand -base64 32 | tr -d '\n')"
    printf '%s\n' "$APP_KEY" > "${DATA_ROOT}/.app_key"
    chown www-data:www-data "${DATA_ROOT}/.app_key" 2>/dev/null || true
  fi
  export APP_KEY
elif [ ! -f "${DATA_ROOT}/.app_key" ]; then
  printf '%s\n' "$APP_KEY" > "${DATA_ROOT}/.app_key"
  chown www-data:www-data "${DATA_ROOT}/.app_key" 2>/dev/null || true
fi

APP_URL_VALUE="${APP_URL:-http://localhost}"
FORCE_HTTPS_VALUE="${FORCE_HTTPS:-false}"
DB_CONNECTION_VALUE="${DB_CONNECTION:-pgsql}"
DB_HOST_VALUE="${DB_HOST:-postgres}"
DB_PORT_VALUE="${DB_PORT:-5432}"
DB_DATABASE_VALUE="${DB_DATABASE:-koel}"
DB_USERNAME_VALUE="${DB_USERNAME:-koel}"
DB_PASSWORD_VALUE="${DB_PASSWORD:-koel}"

cat > /var/www/html/.env <<EOF
APP_NAME=${APP_NAME:-Koel}
APP_ENV=${APP_ENV:-production}
APP_DEBUG=${APP_DEBUG:-false}
APP_KEY=${APP_KEY}
APP_URL=${APP_URL_VALUE}
FORCE_HTTPS=${FORCE_HTTPS_VALUE}
DB_CONNECTION=${DB_CONNECTION_VALUE}
DB_HOST=${DB_HOST_VALUE}
DB_PORT=${DB_PORT_VALUE}
DB_DATABASE=${DB_DATABASE_VALUE}
DB_USERNAME=${DB_USERNAME_VALUE}
DB_PASSWORD=${DB_PASSWORD_VALUE}
MEDIA_PATH=${MEDIA_PATH}
STREAMING_METHOD=${STREAMING_METHOD:-x-sendfile}
FFMPEG_PATH=${FFMPEG_PATH:-/usr/bin/ffmpeg}
MEMORY_LIMIT=${MEMORY_LIMIT:-}
LASTFM_API_KEY=${LASTFM_API_KEY:-}
LASTFM_API_SECRET=${LASTFM_API_SECRET:-}
SPOTIFY_CLIENT_ID=${SPOTIFY_CLIENT_ID:-}
SPOTIFY_CLIENT_SECRET=${SPOTIFY_CLIENT_SECRET:-}
EOF

chown www-data:www-data /var/www/html/.env

exec /usr/local/bin/koel-entrypoint "$@"
