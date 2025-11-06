#!/bin/bash

# This script updates the IP address associated with the imhouse.duckdns.org domain. The script needs to be executed every 5 minutes to keep the domain accessible.

# The script need to have executable permissions:
# chmod +x ./scripts/duckdns/duck.sh

# Usage Example:
# $ sudo ./scripts/duckdns/duck.sh $DuckDNSToken path/to/duck.log
# To schedule:
# $ sudo crontab -e
# $ */5 * * * * path-to-scripts-dir/duckdns/duck.sh $DuckDNSToken path/to/duck.log >/dev/null 2>&1

DUCK_DNS_TOKEN="$1"
LOG_FILE_PATH="$2"

if [ -z "$DUCK_DNS_TOKEN" ] || [ -z "$LOG_FILE_PATH" ]; then
  echo "Usage: $0 <duck_dns_token> <log_file_path>"
  exit 1
fi

echo url="https://www.duckdns.org/update?domains=imhouse&token=$DUCK_DNS_TOKEN&ip=" | curl -k -o "$LOG_FILE_PATH" -K -
