#!/bin/bash

# This script generates a random token for the proxy auth header (PROXY_API_KEY and PROXY_AUTH_HEADER in .env).

# Usage Example:
# $ npm run traefik:token:generate [alias]
# $ npm run traefik:token:generate
# $ npm run traefik:token:generate webapp
# [alias] is added at the beginning ("webapp_<random>") to tell the tokens apart

set -e

ALIAS="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Helper scripts
source "$SCRIPT_DIR/../../utils/scripts/read-env.sh"

PROXY_AUTH_HEADER="${PROXY_AUTH_HEADER:-$(read_env PROXY_AUTH_HEADER)}"

# Commas would split the token list in .env, quotes would break routes.yaml
case "$ALIAS" in
  *[!A-Za-z0-9_-]*)
    echo "Error: the alias can only contain letters, digits, \"-\" and \"_\"" >&2
    exit 1
    ;;
esac

if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: openssl is not installed. Install it and run the command again:" >&2
  echo "  sudo apt-get install openssl  # Linux" >&2
  echo "  brew install openssl          # macOS" >&2
  exit 1
fi

# 32 random bytes (256 bits), hex encoded
TOKEN="$(openssl rand -hex 32)"
if [ -n "$ALIAS" ]; then
  TOKEN="${ALIAS}_$TOKEN"
fi

echo "$TOKEN"
# Only when run by hand, not when the token is captured by another script
if [ -t 1 ]; then
  echo "Set it as PROXY_API_KEY in .env, run \"npm run traefik:restart\", and send it in the ${PROXY_AUTH_HEADER:-<PROXY_AUTH_HEADER from .env>} header" >&2
fi
