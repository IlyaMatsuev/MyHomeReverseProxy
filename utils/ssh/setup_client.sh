#!/bin/bash

# This script configures SSH access to the server from the client machine:
#  1. Generates an SSH key (~/.ssh/id_<alias>) if it doesn't exist
#  2. Adds
#     - "<alias>" (local network) host to ~/.ssh/config
#     - "<alias>-pub" (the Internet), if [public-port] is provided and DOMAIN is set in .env
#  3. Copies the public key to the server (works only while password authentication is still enabled on the server,
#     otherwise prints the key to add on the server manually, after which the script can be run again)
# Run it before "ssh:setup:server", which disables password authentication on the server.

# Usage Example:
# $ npm run ssh:setup:client <alias> <server-ip> <server-user> [public-port]
# $ npm run ssh:setup:client home 192.168.0.10 myuser
# $ npm run ssh:setup:client home 192.168.0.10 myuser 2222
# [public-port] is used only by "<alias>-pub", which is added only when it's provided and DOMAIN is defined

set -e

ALIAS="$1"
SERVER_IP="$2"
SERVER_USER="$3"
PUBLIC_PORT="$4"

if [ -z "$ALIAS" ] || [ -z "$SERVER_IP" ] || [ -z "$SERVER_USER" ]; then
  echo "Usage: npm run ssh:setup:client <alias> <server-ip> <server-user> [public-port]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEY_PATH="$HOME/.ssh/id_$ALIAS"
CONFIG_PATH="$HOME/.ssh/config"

# Helper scripts
source "$SCRIPT_DIR/../scripts/read-env.sh"

DOMAIN="${DOMAIN:-$(read_env DOMAIN)}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate SSH key
if [ -f "$KEY_PATH" ]; then
  echo "Skipped key generation: $KEY_PATH already exists"
else
  ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$KEY_PATH"
fi

# Add hosts config in ~/.ssh/config
add_host() {
  if grep -qE "^Host[[:space:]]+$1$" "$CONFIG_PATH" 2>/dev/null; then
    echo "Skipped \"$CONFIG_PATH\": host \"$1\" already exists"
    return
  fi
  {
    echo
    echo "Host $1"
    echo "  HostName $2"
    if [ -n "$3" ]; then
      echo "  Port $3"
    fi
    echo "  User $SERVER_USER"
    echo "  IdentityFile $KEY_PATH"
    echo "  IdentitiesOnly yes"
  } >> "$CONFIG_PATH"
  echo "Added host \"$1\" to \"$CONFIG_PATH\""
}

# Local SSH entry via standard port 22
add_host "$ALIAS" "$SERVER_IP"

# SSH entry over the Internet via the provided port
if [ -z "$PUBLIC_PORT" ]; then
  echo "Skipped host \"$ALIAS-pub\": [public-port] is not provided"
elif [ -z "$DOMAIN" ]; then
  echo "Skipped host \"$ALIAS-pub\": DOMAIN is not defined in the environment or in $ENV_FILE"
else
  add_host "$ALIAS-pub" "$DOMAIN" "$PUBLIC_PORT"
fi
chmod 600 "$CONFIG_PATH"

# Copy the public key to the server
if ! ssh-copy-id -i "$KEY_PATH.pub" "$SERVER_USER@$SERVER_IP"; then
  echo "Error: could not copy the key. If password authentication is already disabled on the server, add the key there manually and run this script:" >&2
  echo "  mkdir -p ~/.ssh && echo '$(cat "$KEY_PATH.pub")' >> ~/.ssh/authorized_keys" >&2
  exit 1
fi

echo "Done. Now run the setup step on the server:"
echo "  \"npm run ssh:setup:server <server-user>\""
echo

echo "Then check the connection with:"
echo "  \"npm run ssh:verify $ALIAS\" (local network)"
if [ -n "$PUBLIC_PORT" ] && [ -n "$DOMAIN" ]; then
  echo "  or \"npm run ssh:verify $ALIAS-pub\" (over the Internet)"
fi
