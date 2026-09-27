#!/bin/bash

# This file defines the read_env function, which prints the value of the given key from the .env file in the project root.
# Plain grep/cut are used to work the same on macOS and Linux. Load it with "source" before calling the function.

# Usage Example:
# source "$SCRIPT_DIR/../scripts/read-env.sh"
# DOMAIN="${DOMAIN:-$(read_env DOMAIN)}"

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.env"

read_env() {
  if [ -f "$ENV_FILE" ]; then
    grep -E "^$1=" "$ENV_FILE" | tail -n 1 | cut -d '=' -f 2-
  fi
}
