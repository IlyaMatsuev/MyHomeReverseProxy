# PiHole Configs

TODO

1. Copy the existing pihole data (run from the project root):

```shell
sudo cp -r /etc/pihole/* ./config/pihole/data
```

2. Stop the existing service:

```shell
sudo systemctl stop pihole-FTL
sudo systemctl disable pihole-FTL

sudo systemctl stop lighttpd
sudo systemctl disable lighttpd
```

3. Remove the services:

```shell
sudo apt purge pihole
sudo apt autoremove
```

4. Remove old data:

```shell
sudo rm -rf /etc/pihole /etc/dnsmasq.d
```

Remove the old pihole data
