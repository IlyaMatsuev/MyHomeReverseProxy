#!/bin/bash

# This script updates the IP address associated with the imhouse.duckdns.org domain. The script needs to be executed every 5 minutes to keep the domain accessible.

# The script need to have executable permissions:
# chmod +x ./scripts/duckdns/duck.sh

# Usage Example:
# $ sudo ./scripts/duckdns/duck.sh
# To schedule:
# $ sudo crontab -e
# $ */5 * * * * path-to-scripts-dir/duckdns/duck.sh >/dev/null 2>&1

echo url="https://www.duckdns.org/update?domains=imhouse&token=b107eaa7-07a8-43a7-a0f0-c26a5f9cd0df&ip=" | curl -k -o /home/ilya/Desktop/projects/my-reverse-proxy/scripts/duckdns/duck.log -K -

