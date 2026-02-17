# Configure SSH connection

This manual describes how to configure an SSH connection between machines over the local network (or via the Internet).

## 1. Disable password authentication

...on your server to prevent brute force attacks. Attempts to log in without private key will fail immediately.

On the server:

```shell
sudo nano /etc/ssh/sshd_config
```

...and change these lines:

```text
PasswordAuthentication no
PermitRootLogin no
# "user" is the name of user allowed to log in
AllowUsers user
```

Reload SSH (_make sure to not close the existing SSH connection to be able to change the settings if log in doesn't work after this_):

```shell
sudo systemctl reload sshd
```

## 2. Generate SSH keys

On your client, generate a new key:

```shell
# "ilya@my-client" is just a comment to identify the key
# "~/.ssh/id_home_pi" is the name of the new SSH keys (to easily identify)
ssh-keygen -t ed25519 -C "ilya@my-client" -f ~/.ssh/id_home_pi
```

Copy your public key to the SSH server (**_this only works if the password authentication still enabled_**):

```shell
# "user" is the SSH username on your server
# "192.168.0.100" is the IP in the same local network
ssh-copy-id -i ~/.ssh/id_home_pi.pub user@192.168.0.100
```

If password authentication already disabled for the host, copy the key manually from your machine...

```shell
# Copy the entire key
cat ~/.ssh/id_home_pi.pub
```

...to the SSH server:

```shell
# Paste the key at the bottom (new line)
sudo nano ~/.ssh/authorized_keys
```

## 3. Configure port forwarding (for access over the Internet)

SSH uses port `22` but it's better to assign a different port when exposing it in the router settings. For example, `2222`
In the router settings, configure port forwarding:

- External port: `2222`
- Internal port: `22`
- Internal address: `192.168.0.100`

## 4. Add SSH setting (for convenience)

In `~/.ssh/config` add:

```text
# Local network
Host pi
    # "192.168.0.100" is the IP in the same local network
    HostName 192.168.0.100
    # "user" is the SSH username on your server
    User user
    IdentityFile ~/.ssh/id_home_pi
    IdentitiesOnly yes

# The Internet
Host pi-pub
    # "myhome.duckdns.org" is the domain name
    HostName myhome.duckdns.org
    # "user" is the SSH username on your server
    User user
    # 2222 is an example of a changed port for SSH forwarding in the router settings: 2222 -> 22
    Port 2222
    IdentityFile ~/.ssh/id_home_pi
    IdentitiesOnly yes
```

Now you can log in using:

```shell
# Via the local network
ssh pi
# Via the Internet
ssh pi-pub
```

## 5. Add rate limiter (for security)

Install `fail2ban` for temporary ban all clients that fail to connect:

```shell
sudo apt install fail2ban
# Copy the config file ("jail.conf" can get overridden during an update)
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

Edit `sshd` section:

```text
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 1d
findtime = 1h
```

Restart `fail2ban`:

```shell
sudo systemctl restart fail2ban
```

Later, you can:

- Check status and banned IP addresses: `sudo fail2ban-client status sshd`
- Check logs: `sudo tail -f /var/log/fail2ban.log`
- Unban an IP address: `sudo fail2ban-client set sshd unbanip <IP>`

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
ls -ld /home/ilya/.ssh
# Good: drwx------
# Bad: drwxrwxr-x
```

2. The public key from the client must be in the `~/.ssh/authorized_keys` on the server
