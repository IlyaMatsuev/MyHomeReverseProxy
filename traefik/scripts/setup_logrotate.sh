#!/bin/bash

# This script makes logrotate rotate traefik/logs/access.log every week and keep the last 4 weeks.
# Traefik rotates its own log (traefik.log) by itself, but not the access log.
# Safe to run again: the config is overwritten, e.g. after moving the project.

# Usage Example:
# $ npm run traefik:logs:rotate

set -e

LOGS_DIR="$(cd "$(dirname "$0")/.." && pwd)/logs"
CONFIG_PATH=/etc/logrotate.d/traefik

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: run it as root: sudo bash $0" >&2
  exit 1
fi

if ! command -v logrotate >/dev/null 2>&1; then
  echo "Error: logrotate is not installed. Install it and run the command again:" >&2
  echo "  sudo apt install logrotate" >&2
  exit 1
fi

# Write to the logrotate traefik file to schedule log compression by its path at $LOGS_DIR/access.log
cat > "$CONFIG_PATH" <<CONFIG
$LOGS_DIR/access.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    # Traefik keeps the file open, so it's copied and emptied in place instead of moved
    copytruncate
}
CONFIG
chmod 644 "$CONFIG_PATH"
echo "Created $CONFIG_PATH: $LOGS_DIR/access.log is rotated weekly, the last 4 weeks are kept"
