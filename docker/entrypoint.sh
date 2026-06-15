#!/usr/bin/env bash
# Container entrypoint: render config from ENV, ensure an RSA key + secret exist,
# prepare the database, then exec the CMD (puma).
set -e
cd /app
RAILS_ENV="${RAILS_ENV:-production}"
export RAILS_ENV

# 1. Config + database.yml from the committed, ENV-driven templates.
cp docker/license_server_config.rb "config/license_server_config_${RAILS_ENV}.rb"
cp docker/database.yml config/database.yml

# 2. RSA key. Generate an EPHEMERAL DEV key if none is provided — this is NOT a
#    valid production license-signing key; mount the real one via PRIVATE_KEY_FILE.
PRIV="${PRIVATE_KEY_FILE:-/app/config/keys/private.pem}"
PUB="${PUBLIC_KEY_FILE:-/app/config/keys/public.pem}"
if [ ! -f "$PRIV" ]; then
  echo "WARNING: no RSA private key at $PRIV — generating an EPHEMERAL DEV key."
  echo "         Mount the real key (PRIVATE_KEY_FILE) for production licensing."
  mkdir -p "$(dirname "$PRIV")"
  openssl genrsa -out "$PRIV" 2048 2>/dev/null
  openssl rsa -in "$PRIV" -pubout -out "$PUB" 2>/dev/null
fi

# 3. secret_key_base (Rails 8 requires one in production). Generate if unset.
if [ -z "${SECRET_KEY_BASE:-}" ]; then
  echo "Note: SECRET_KEY_BASE not set — generating an ephemeral one (sessions reset on restart)."
  SECRET_KEY_BASE="$(bundle exec rails secret)"
fi
export SECRET_KEY_BASE

# 4. Wait for the database, then create/migrate/seed it.
if [ -n "${DB_HOST:-}" ]; then
  echo "Waiting for database at ${DB_HOST}:${DB_PORT:-3306}..."
  for _ in $(seq 1 60); do
    mysqladmin ping -h "$DB_HOST" -P "${DB_PORT:-3306}" --silent >/dev/null 2>&1 && break
    sleep 1
  done
fi
echo "Preparing database..."
bundle exec rails db:prepare

exec "$@"
