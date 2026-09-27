#!/bin/bash

# This script updates the IP address associated with the DuckDNS domain.
# The script needs to be executed every 5 minutes to keep the domain accessible.
# DOMAIN and DUCKDNS_TOKEN are taken from the environment, or from the .env file in the project root if they are not set.

# Usage Example:
# $ bash ./utils/duckdns/update_ip.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE_PATH="$SCRIPT_DIR/logs/update_ip.log"
mkdir -p "$SCRIPT_DIR/logs"

source "$SCRIPT_DIR/../scripts/read-env.sh"

DOMAIN="${DOMAIN:-$(read_env DOMAIN)}"
DUCKDNS_TOKEN="${DUCKDNS_TOKEN:-$(read_env DUCKDNS_TOKEN)}"

if [ -z "$DUCKDNS_TOKEN" ]; then
  echo "Error: DUCKDNS_TOKEN is not defined. Set it in the environment or in $ENV_FILE" >&2
  exit 1
fi
if [ -z "$DOMAIN" ]; then
  echo "Error: DOMAIN is not defined. Set it in the environment or in $ENV_FILE" >&2
  exit 1
fi

# DuckDNS expects the subdomain only: "mydomain" for "mydomain.duckdns.org"
SUBDOMAIN="${DOMAIN%.duckdns.org}"

# The URL is passed through stdin, so the token doesn't show up in the process list
echo url="https://www.duckdns.org/update?domains=$SUBDOMAIN&token=$DUCKDNS_TOKEN&ip=" | curl -s -K - | tee "$LOG_FILE_PATH"
echo
echo "Done"
echo
