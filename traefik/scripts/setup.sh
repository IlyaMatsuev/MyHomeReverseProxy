#!/bin/bash

# This script creates the local config files from their examples. Existing files are never overwritten.
#  - .env from .env.example
#  - traefik/config/routes.yaml from traefik/config/routes.yaml.example

# Usage Example:
# $ sh ./traefik/scripts/setup

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

copy_if_missing "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
# Access for the current user only
chmod 600 "$ROOT_DIR/.env"

copy_if_missing "$ROOT_DIR/traefik/config/routes.yaml.example" "$ROOT_DIR/traefik/config/routes.yaml"
