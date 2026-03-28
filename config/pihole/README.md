# PiHole Setup

PiHole is a tool that meant to filter out DNS requests in the local network to block ads in the Internet.  
Apart from that it can also be used to add custom DNS names for the local network, monitor requests to the Internet and work as a DHCP server (if enabled, not the case for this project).

## 🤔 Prerequisites

Before running the `pihole`, you need to create a file with environment variables at `configs/pihole/.env.pihole.prod`, following the settings examples from `configs/pihole/.env.pihole.example`. You can copy the values using:

```shell
# Should be run from the project root
cp ./configs/pihole/.env.pihole.example ./configs/pihole/.env.pihole.prod
```

Make sure to specify the correct network interface for `PIHOLE_INTERFACE` according to your network source. Read how to find your network interface [here](./../../scripts/arp-scan/arp-scan.sh).

## 🎲 Not first time setup

If you ran the `pihole` on your machine before, you can move all the data from:

- `/etc/pihole/` to the `configs/pihole/data` in this project
- `/etc/dnsmasq.d` to the `configs/pihole/dnsmasq.d` in this project

This way, running the pihole service as a docker container will preserve the old settings.

## 1️⃣ First time setup

1. Start the pihole service: `npm run pihole:start:prod`
2. Wait a minute, the service needs some time to start up. The logs can be checked with `docker logs -f pihole`
3. Go to the web interface: `http://{server-ip}:8080/admin`

- Configure DNS settings: `Settings` -> `DNS` -> `Toggle Advanced mode at the top right` -> `Make sure "Interface settings" is set to "Permit all origins"`
- _[Optional]_ Configure Ad lists. Ad lists can be found online and imported via the `Lists` tab.
- _[Optional]_ Configure local domain names. Local domain names can be configured so that the reverse proxy can forward the requests to the proper service based on the domain name. Domain names can be added via `Settings` -> `Local DNS Records` -> `List of local DNS records`. It's possible to add different domain names for the same address, which is how I use this project:
    - You can add a new entry like `pihole.home -> 192.168.0.100`
    - After that you can configure the forwarding for this service in `config/addresses.prod.json`. Read more about adding service entries [here](./../../README.md#-configuration)
    - This will allow you to access a service by typing the domain name only: `https://pihole.home` - you don't even need to remember the port now!

4. After making any changes, restart the `pihole`: `npm run pihole:restart:prod`
