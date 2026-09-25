#!/bin/bash

# This script updates the IP address associated with the mydomain.duckdns.org domain. The script needs to be executed every 5 minutes to keep the domain accessible.

# The script need to have executable permissions:
# chmod +x ./scripts/duckdns/duck.sh

# Usage Example:
# $ sudo ./scripts/duckdns/duck.sh $DuckDNSToken
# To schedule:
# $ sudo crontab -e
# $ */5 * * * * path-to-scripts-dir/duckdns/duck.sh $DuckDNSToken >/dev/null 2>&1

DUCK_DNS_TOKEN="$1"

if [ -z "$DUCK_DNS_TOKEN" ]; then
  echo "Usage: $0 <duck_dns_token>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE_PATH="$SCRIPT_DIR/duck.log"


# TODO: I need to rotate DuckDNS token
echo url="https://www.duckdns.org/update?domains=imhouse&token=$DUCK_DNS_TOKEN&ip=" | curl -k -o "$LOG_FILE_PATH" -K -
