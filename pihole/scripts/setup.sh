#!/bin/bash

# This script creates the local config files for Pihole from their examples. Existing files are never overwritten
#  - pihole/.env from pihole/.env.example

# Usage Example:
# $ sh ./pihole/scripts/setup.sh

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

copy_if_missing "$ROOT_DIR/pihole/.env.example" "$ROOT_DIR/pihole/.env"
# Access for the current user only
chmod 600 "$ROOT_DIR/pihole/.env"
