#!/bin/bash

# This script verifies that the SSH login to the given host from ~/.ssh/config works with the key.
# Password login is not allowed during the check, so it fails if the key is not accepted.

# Usage Example:
# $ npm run ssh:verify <alias>
# $ npm run ssh:verify myhome        (local network)
# $ npm run ssh:verify myhome-pub    (the Internet)

set -e

ALIAS="$1"

if [ -z "$ALIAS" ]; then
  echo "Usage: npm run ssh:verify <alias>" >&2
  exit 1
fi

if ssh -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o ConnectTimeout=10 "$ALIAS" true; then
  echo "Done: key login to \"$ALIAS\" works. Connect with \"ssh $ALIAS\""
else
  echo "Error: key login to \"$ALIAS\" failed. Check it with \"ssh -v $ALIAS\"" >&2
  exit 1
fi
