#!/bin/bash

# This script hardens the SSH server on this machine:
#  1. Allows only key login for the given user (no passwords, no root login)
#  2. Installs fail2ban to ban IPs for a day after 3 failed login attempts within an hour
# Run "ssh:setup:client" on your client first: this script refuses to run if the user has no authorized SSH keys.
# Keep your current SSH session open until you've verified that a new login works.

# Usage Example:
# $ npm run ssh:setup:server [user]
# $ npm run ssh:setup:server
# $ npm run ssh:setup:server myuser
# [user] defaults to the user running the command

set -e

# Not $(whoami): the script runs via sudo, so whoami is root. SUDO_USER is the user who ran sudo
SSH_USER="${1:-$SUDO_USER}"
SSHD_CONFIG_PATH="/etc/ssh/sshd_config"
SSHD_DROP_IN_PATH="/etc/ssh/sshd_config.d/10-my-home.conf"
FAIL2BAN_JAIL_PATH="/etc/fail2ban/jail.d/my-home.local"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: the script must run as root" >&2
  exit 1
fi
if [ -z "$SSH_USER" ] || [ "$SSH_USER" = "root" ]; then
  echo "Error: provide a non-root user to run SSH: npm run ssh:setup:server <user>" >&2
  exit 1
fi

USER_HOME="$(getent passwd "$SSH_USER" | cut -d ':' -f 6)"
if [ -z "$USER_HOME" ]; then
  echo "Error: user \"$SSH_USER\" does not exist" >&2
  exit 1
fi

echo "This disables password and root login on this server. Only \"$SSH_USER\" will be able to log in, and only with an SSH key."
echo "Make sure you've run \"npm run ssh:setup:client <alias> <server-ip> <server-user>\" on your client first."
# Ctrl+C stops the script here, nothing is changed before this point
read -r -p "Press Enter to continue or Ctrl+C (or Command+C) to cancel..."

# Disabling passwords without an authorized key would lock the user out
AUTHORIZED_KEYS_PATH="$USER_HOME/.ssh/authorized_keys"
if [ ! -s "$AUTHORIZED_KEYS_PATH" ]; then
  echo "Error: $AUTHORIZED_KEYS_PATH is empty. Run \"npm run ssh:setup:client\" on your client first" >&2
  exit 1
fi

# sshd ignores the keys if these are accessible by other users
chown "$SSH_USER:" "$USER_HOME/.ssh" "$AUTHORIZED_KEYS_PATH"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$AUTHORIZED_KEYS_PATH"

# Save SSH settings
# sshd keeps the first value it reads for each setting, and sshd_config includes sshd_config.d/*.conf at the top
if ! grep -qE '^Include /etc/ssh/sshd_config\.d/\*\.conf' "$SSHD_CONFIG_PATH"; then
  echo "Error: $SSHD_CONFIG_PATH doesn't include the drop-in folder. Add this line at the top of it and run the script again:" >&2
  echo "  Include /etc/ssh/sshd_config.d/*.conf" >&2
  exit 1
fi

cat > "$SSHD_DROP_IN_PATH" <<EOF
# Created by MyHomeReverseProxy "npm run ssh:setup:server"
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers $SSH_USER
EOF

# Revert instead of reloading a config that is invalid or overridden by another file
if ! sshd -t || ! sshd -T | grep -qx 'passwordauthentication no'; then
  rm -f "$SSHD_DROP_IN_PATH"
  echo "Error: the SSH settings are invalid or overridden by another file in /etc/ssh/sshd_config.d, the changes are reverted" >&2
  exit 1
fi
systemctl reload ssh
echo "SSH: password and root login disabled, only \"$SSH_USER\" can log in"

# Install fail2ban
apt-get install -y fail2ban python3-systemd
cat > "$FAIL2BAN_JAIL_PATH" <<'EOF'
# Created by MyHomeReverseProxy "npm run ssh:setup:server"
[sshd]
enabled = true
port = ssh
# sshd logs only to journald on Debian 12+ (no /var/log/auth.log)
backend = systemd
maxretry = 3
findtime = 1h
bantime = 1d
EOF
fail2ban-client --test >/dev/null
systemctl enable fail2ban
systemctl restart fail2ban
echo "fail2ban: IPs are banned for a day after 3 failed login attempts within an hour. To change rate-limit settings, edit:"
echo "  sudo nano \"$FAIL2BAN_JAIL_PATH\" && sudo fail2ban-client reload"

echo "Done. Keep this session open and run \"npm run ssh:verify <alias>\" on your client to verify the connection"
