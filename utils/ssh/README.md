# Configure SSH connection

This manual describes how to configure an SSH connection between machines over the local network (or via the Internet).

## Quick setup

Run these commands in this order, since the second one disables password login:

1. On your client (generates the key, copies it to the server, adds `<alias>` and `<alias>-pub` hosts to `~/.ssh/config`):

```shell
# npm run ssh:setup:client <alias> <server-ip> <server-user> [public-port]
# <alias> - name you will use to connect to the server
# <server-ip> - local ip address of the server to connect to
# <server-user> - server user to connect as
# <public-port> - when set, creates a new SSH host entry ("<alias>-pub") to connect to the server over the Internet.
# "myhome" connects via the local network
npm run ssh:setup:client myhome 192.168.0.10 myuser
```

> If you want to use the SSH connection over the Internet, consider setting a custom SSH `<public-port>` like `2222` instead of `22` for a better disguise.

2. On the server (disables password and root login, allows only your user, installs `fail2ban`):

```shell
# npm run ssh:setup:server [user=$whoami]
npm run ssh:setup:server
```

3. **[Optional]** Configure port forwarding (for access over the Internet via `myhome-pub`)

In the router settings, configure port forwarding:

- External port: whatever you specified in `<public-port>` on a client (`22` by default)
- Internal port: `22` (default)
- Internal address: whatever you specified in `<server-ip>`

3. On your client, check the connection:

```shell
# npm run ssh:verify <alias>
npm run ssh:verify myhome
npm run ssh:verify myhome-pub
```

Keep your current SSH session to the server open until `npm run ssh:verify myhome` passes.

---

## Troubleshooting

To verify logs from the SSH server:

```shell
sudo journalctl -u ssh -n 50 --no-pager
```

To verify logs from the SSH client:

```shell
# "pi" is a username configured in "~/.ssh/config"
ssh -v pi
```

If everything is correct, but you still cannot log in (`Permission denied (publickey)`):

1. Check the permissions of the `~/.ssh` folder on the server, they have to be like this:

```shell
ls -ld "/home/$whoami}/.ssh"
# Good: drwx------
# Bad: drwxrwxr-x
```

2. The public key from the client must be in the `~/.ssh/authorized_keys` on the server

To manage `fail2ban` on the server:

- Check status and banned IP addresses: `sudo fail2ban-client status sshd`
- Check logs: `sudo tail -f /var/log/fail2ban.log`
- Unban an IP address: `sudo fail2ban-client set sshd unbanip <IP>`
