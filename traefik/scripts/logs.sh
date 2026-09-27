#!/bin/bash

# This script prints the last lines of traefik/logs/traefik.log, then follows traefik/logs/access.log as a table.
# Stop it with Ctrl+C.

# Usage Example:
# $ npm run traefik:logs [lines=5]
# $ npm run traefik:logs
# $ npm run traefik:logs 100
# $ NO_COLOR=1 npm run traefik:logs
# [lines] is how many lines of each log to print first (5 by default)
# NO_COLOR=1 prints without colors (they are also off when the output isn't a terminal)

LINES="${1:-5}"
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

# Colors only in a terminal, not when the output is saved to a file. NO_COLOR=1 turns them off
if [ -t 1 ] && [ -z "$NO_COLOR" ]; then
  COLOR=true
else
  COLOR=false
fi
# Terminal color codes: 1 bold, 2 dim, 31 red, 32 green, 33 yellow
style() {
  if [ "$COLOR" = true ]; then printf '\033[%sm' "$1"; fi
}
BOLD="$(style 1)"
DIM="$(style 2)"
RED="$(style 31)"
GREEN="$(style 32)"
YELLOW="$(style 33)"
RESET="$(style 0)"

echo "${BOLD}===== Traefik server logs =====${RESET}"
# Traefik creates it readable by root only
if [ -r "$LOGS_DIR/traefik.log" ]; then
  tail -n "$LINES" "$LOGS_DIR/traefik.log"
else
  sudo tail -n "$LINES" "$LOGS_DIR/traefik.log"
fi | sed -e "s/ INF / ${GREEN}INF${RESET} /" -e "s/ ERR / ${RED}ERR${RESET} /" -e "s/ WRN / ${YELLOW}WRN${RESET} /"
echo

echo "${BOLD}===== Incoming requests =====${RESET}"
if [ "$COLOR" = true ]; then
  echo "${DIM}Status: $(style '1;32')2xx${RESET}${DIM} $(style '1;36')3xx${RESET}${DIM} $(style '1;35')401/403/429${RESET}${DIM} (no token, rate limit) $(style '1;33')4xx${RESET}${DIM} $(style '1;31')5xx${RESET}${DIM}. Dimmed rows: no router matched (bots)${RESET}"
fi
printf "$(style '1;4')%-14s  %-6s  %-6s  %-8s  %-6s  %-15s  %-14s  %-20s  %-35s  %s${RESET}\n" \
  TIME STATUS ORIGIN DURATION SIZE CLIENT HOST ROUTER REQUEST USER-AGENT

# -F keeps following the file after logrotate empties it
tail -n "$LINES" -F "$LOGS_DIR/access.log" |
  jq --unbuffered -R -r --arg domain "$DOMAIN" --argjson color "$COLOR" -f "$SCRIPT_DIR/access_log.jq"
