#!/bin/bash

# This script schedules update_ip.sh to run every 5 minutes in the current user's crontab. Does nothing if the job already exists.

# Usage Example:
# $ bash ./utils/duckdns/schedule_update_ip.sh

set -e

# Every 5 minutes
JOB_CRON="*/5 * * * *"

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/update_ip.sh"

JOB="$JOB_CRON /bin/bash \"$SCRIPT_PATH\" >/dev/null 2>&1"

if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
    echo "Skipped: the job already exists"
    crontab -l | grep -F "$SCRIPT_PATH"
    exit 0
fi

# "|| true" keeps the existing jobs pipeline working when there is no crontab yet
(crontab -l 2>/dev/null || true; echo "$JOB") | crontab -
echo "Scheduled: $JOB"
echo "Done"
echo
