#!/bin/bash

# This script prints the last lines of traefik/logs/traefik.log, then follows traefik/logs/access.log as a table.
# Stop it with Ctrl+C.

# Usage Example:
# $ npm run traefik:logs [lines]
# $ npm run traefik:logs
# $ npm run traefik:logs 100
# [lines] is how many lines of each log to print first (20 by default)

LINES="${1:-20}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGS_DIR="$SCRIPT_DIR/../logs"

# Helper scripts
source "$SCRIPT_DIR/../../utils/scripts/read-env.sh"

# Hosts are shown without it: "hub" for "hub.<DOMAIN>"
DOMAIN="${DOMAIN:-$(read_env DOMAIN)}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is not installed. Install it and run the command again:" >&2
  echo "  sudo apt install jq  # Linux" >&2
  echo "  brew install jq      # macOS" >&2
  exit 1
fi

echo "=== traefik.log ==="
# Traefik creates it readable by root only
if [ -r "$LOGS_DIR/traefik.log" ]; then
  tail -n "$LINES" "$LOGS_DIR/traefik.log"
else
  sudo tail -n "$LINES" "$LOGS_DIR/traefik.log"
fi
echo

echo "=== access.log ==="
printf '%-14s  %-6s  %-6s  %-8s  %-6s  %-15s  %-14s  %-20s  %-35s  %s\n' \
  TIME STATUS ORIGIN DURATION SIZE CLIENT HOST ROUTER REQUEST USER-AGENT
# -F keeps following the file after logrotate empties it. Lines that aren't JSON are skipped
tail -n "$LINES" -F "$LOGS_DIR/access.log" |
  jq --unbuffered -R -r --arg domain "$DOMAIN" '
    def pad(n): tostring | if length < n then . + " " * (n - length) else . end;
    def size: if . < 1024 then "\(.)B" elif . < 1048576 then "\(. / 1024 | floor)K" else "\(. / 1048576 | floor)M" end;
    fromjson? | [
      (.time[5:10] + " " + .time[11:19] | pad(14)),
      (.DownstreamStatus | pad(6)),
      # The status from the service. "-": Traefik answered by itself (no router, auth, rate limit, redirect)
      (if (.OriginStatus // 0) == 0 then "-" else .OriginStatus end | pad(6)),
      ((.Duration // 0) / 1000000 | floor | "\(.)ms" | pad(8)),
      (.DownstreamContentSize // 0 | size | pad(6)),
      (.ClientHost | pad(15)),
      (.RequestHost // "-" | if $domain != "" and endswith("." + $domain) then .[:-($domain | length) - 1] else . end | pad(14)),
      (.RouterName // "-" | sub("^websecure-"; "") | sub("@file$"; "") | pad(20)),
      ("\(.RequestMethod) \(.RequestPath)" | pad(35)),
      (.["request_User-Agent"] // "-")
    ] | join("  ")'
