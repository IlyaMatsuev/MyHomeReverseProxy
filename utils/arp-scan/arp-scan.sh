#!/bin/bash

# This script performs the ARP table refresh for a specified net interface:
#  - Usually "wlan0" for WiFi and "eth0" for Ethernet connection. This needs to be adjusted depending how your primary network interface is configured
#  - Network interface can be found by running "ip addr show", looking for an entry with an IP address. It can look similar to this: "inet 192.168.0.10/24 brd 192.168.0.255 scope global noprefixroute wlan0"

# Having ARP table up-to-date is necessary in order to keep routes between devices in the local network synced
# When the ARP table is outdated, some devices that changed their MAC address in the local network might not be able to communicate with the local server

# Usage Example:
# $ sudo bash ./utils/arp-scan/arp-scan.sh wlan0

INTERFACE=${1:-wlan0}

# arp-scan and ip live in sbin, which cron's default PATH (/usr/bin:/bin) doesn't include
PATH="/usr/sbin:/sbin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOG_FILE="$SCRIPT_DIR/logs/${INTERFACE}-latest.log"
mkdir -p "$SCRIPT_DIR/logs"

if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
    echo "Error: the network interface \"$INTERFACE\" doesn't exist" >&2
    echo "Find the one with your local IP (e.g. 192.168.0.10):" >&2
    echo "  ip -brief addr" >&2
    echo "...and pass it:" >&2
    echo "  npm run arp-scan <interface>" >&2
    exit 1
fi

SUBNET=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+\.\d+\.\d+')

if [ -n "$SUBNET" ]; then
    for i in $(seq 1 254); do
        ping -c 1 -W 1 "$SUBNET.$i" &>/dev/null &
    done
    wait
    sleep 2
fi

{
    echo "=== ARP Scan on ${INTERFACE} ==="
    echo "Date: $(date)"
    echo "========================="
    echo
    arp-scan --interface="$INTERFACE" --localnet
} | tee "$LOG_FILE"
