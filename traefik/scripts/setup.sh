#!/bin/bash

# This script creates the local config files from their examples. Existing files are never overwritten.
#  - .env from .env.example
#  - traefik/config/routes.yaml from traefik/config/routes.yaml.example

# Usage Example:
# $ npm run traefik:setup

set -e

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

copy_if_missing() {
  if [ -e "$2" ]; then
    echo "Skipped $2: already exists"
  else
    cp "$1" "$2"
    echo "Created $2: fill in your values"
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
