#!/bin/bash

# This script performs the ARP table refresh for a specified net interface (wlan0 by default)
# Having ARP table up-to-date is necessary in order to keep routes between devices in the local network synced
# When the ARP table is outdated, some devices that changed their MAC address in the local network might not be able to communicate with the local server

# The script need to have executable permissions:
# chmod +x ./scripts/arp-scan/arp-scan.sh

# Usage Example:
# $ sudo ./scripts/arp-scan/arp-scan.sh wlan0
# To schedule:
# $ sudo crontab -e
# $ 0 * * * * path-to-project/scripts/arp-scan/arp-scan.sh wlan0

INTERFACE=${1:-wlan0}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_FILE="$SCRIPT_DIR/${INTERFACE}-latest.log"

{
    echo "=== ARP Scan on ${INTERFACE} ==="
    echo "Date: $(date)"
    echo "========================="
    echo
    arp-scan --interface="$INTERFACE" --localnet
} > "$LOG_FILE"
