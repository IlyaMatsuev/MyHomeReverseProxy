#!/bin/bash

# This script schedules arp-scan.sh to run every hour in the root crontab. Does nothing if the job already exists.

# Usage Example:
# $ sudo bash ./utils/arp-scan/schedule.sh wlan0

set -e

INTERFACE=${1:-wlan0}
# Every hour
JOB_CRON="0 * * * *"

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/arp-scan.sh"

# Cron's default PATH (/usr/bin:/bin) doesn't include arp-scan and ip, which live in sbin
JOB="$JOB_CRON PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash \"$SCRIPT_PATH\" $INTERFACE"

if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
    echo "Skipped: the job already exists"
    crontab -l | grep -F "$SCRIPT_PATH"
    exit 0
fi

# "|| true" keeps the existing jobs pipeline working when there is no crontab yet
(crontab -l 2>/dev/null || true; echo "$JOB") | crontab -
echo "Scheduled: $JOB"
