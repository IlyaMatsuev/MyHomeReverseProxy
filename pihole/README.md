# PiHole Setup

PiHole is a tool that meant to filter out DNS requests in the local network to block ads in the Internet.  
Apart from that it can also be used to add custom DNS names for the local network, monitor requests to the Internet and work as a DHCP server (if enabled, not the case for this project).

## 🤔 Prerequisites

Before running the `pihole`, you need to create a file with environment variables at `pihole/.env`, following the settings examples from `pihole/.env.example`. It's created automatically by `npm run pihole:start`, or you can create it yourself:

```shell
npm run pihole:setup
```

Set `TZ` to your time zone (e.g. `Europe/Amsterdam`) for the timestamps in the logs and the dashboard, it's UTC if empty.

Make sure to specify the correct network interface for `PIHOLE_INTERFACE` according to your network source. Read how to find your network interface [here](../utils/arp-scan/arp-scan.sh).

## 🎲 Not first time setup

If you ran the `pihole` on your machine before, you can move all the data from:

- `/etc/pihole/` to the `pihole/data` in this project
- `/etc/dnsmasq.d` to the `pihole/dnsmasq.d` in this project

This way, running the pihole service as a docker container will preserve the old settings.

> **Note:** PiHole v6 ignores the files in `pihole/dnsmasq.d` by default. Set `FTLCONF_misc_etc_dnsmasq_d=true` in `pihole/.env` if you still need them.

## 1️⃣ First time setup

1. Start the pihole service: `npm run pihole:start`
2. Wait a minute, the service needs some time to start up. The logs can be checked with `docker logs -f pihole`
3. Go to the web interface: `http://{server-ip}:{PIHOLE_PORT_HTTP}/admin` (`8080` by default), or `https://pihole.<DOMAIN>` once Traefik is running

- Configure DNS settings: `Settings` -> `DNS` -> `Toggle Advanced mode at the top right` -> `Make sure "Interface settings" is set to "Permit all origins"`
- Resolve the domain to the server's local IP. Set `FTLCONF_misc_dnsmasq_lines` in `pihole/.env` (see [.env.example](.env.example)), e.g. `address=/mydomain.duckdns.org/192.168.0.10`. It resolves the domain and all its subdomains (`hub.mydomain.duckdns.org`, `radarr.mydomain.duckdns.org`, etc.) to the server:
    - Devices in the local network reach Traefik directly instead of going through the router, so Traefik sees them as local. Without it, requests come from the router's IP, and are treated as requests from the Internet
    - Now, to add a service, you only need to add it to `traefik/config/routes.yaml`. Read more about adding services [here](../README.md#-configuration)
- _[Optional]_ Configure Ad lists. Ad lists can be found online and imported via the `Lists` tab.

4. After making any changes, restart the `pihole`: `npm run pihole:restart`
