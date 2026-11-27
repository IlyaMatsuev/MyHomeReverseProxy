#!/bin/bash

# This script creates the local config files from their examples. Existing files are never overwritten.
#  - .env from .env.example
#  - traefik/config/routes.yaml from traefik/config/routes.yaml.example
# It also downloads the plugins used for traefik locally. The plugins are redownloaded if the plugin version has changed or if the plugin folder is deleted
# It also sets up the access log rotation if it isn't set up for this project yet (asks for the sudo password).

# Usage Example:
# $ npm run traefik:setup

set -e

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

PLUGINS_DIR="$ROOT_DIR/traefik/plugins-local/src/"
API_TOKEN_PLUGIN_MODULE=github.com/Aetherinox/traefik-api-token-middleware
API_TOKEN_PLUGIN_VERSION=v0.1.4

copy_if_missing() {
  if [ -e "$2" ]; then
    echo "Skipped $2: already exists"
  else
    cp "$1" "$2"
    echo "Created $2: fill in your values"
  fi
}

# Usage: download_plugin <module> <version>
download_plugin() {
  plugin_dir="$PLUGINS_DIR$1"
  if [ -d "$plugin_dir" ] && [ "$(git --git-dir="$plugin_dir/.git" describe --tags --exact-match 2>/dev/null)" = "$2" ]; then
    echo "Skipped $plugin_dir: $2 already exists"
  else
    rm -rf "$plugin_dir"
    git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$2" "https://$1.git" "$plugin_dir"
    echo "Created $plugin_dir: $2"
  fi
}

ENV_PATH="$ROOT_DIR/.env"

copy_if_missing "$ROOT_DIR/.env.example" "$ENV_PATH"
# Access for the current user only
chmod 600 "$ENV_PATH"

# Traefik doesn't load routes.yaml without it
if [ -z "$(grep -E '^PROXY_API_KEY=' "$ENV_PATH" | tail -n 1 | cut -d '=' -f 2-)" ]; then
  echo "Warning: PROXY_API_KEY is empty in \"$ENV_PATH\""
  echo "Generate a token with \"npm run traefik:token:generate [alias]\" and set it there"
fi

copy_if_missing "$ROOT_DIR/traefik/config/routes.yaml.example" "$ROOT_DIR/traefik/config/routes.yaml"

download_plugin "$API_TOKEN_PLUGIN_MODULE" "$API_TOKEN_PLUGIN_VERSION"

# Skip if logrotate routine file already exists
LOGROTATE_CONFIG_PATH=/etc/logrotate.d/traefik
if grep -qF "$ROOT_DIR/traefik/logs/access.log" "$LOGROTATE_CONFIG_PATH" 2>/dev/null; then
  echo "Skipped $LOGROTATE_CONFIG_PATH: already exists"
elif ! sudo bash "$ROOT_DIR/traefik/scripts/setup_logrotate.sh"; then
  echo "Error: the access log rotation isn't set up. Resolve the issue above and run" >&2
  echo "  npm run traefik:logs:rotate" >&2
fi
