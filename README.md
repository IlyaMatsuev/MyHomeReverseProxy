# My Reverse Proxy

The project contains configuration for running [Traefik](https://traefik.io/traefik) as a reverse proxy on a home server.
It forwards requests for subdomains of the same domain to different services running on the local network.

Requests from the local network are always allowed. Requests from the Internet are allowed only for the services you choose, and require authorization.

```
  hub.<DOMAIN> ───────┐
                      │    ┌──────────────────┐    hub.<DOMAIN>    ──> 127.0.0.1:3000
  radarr.<DOMAIN> ────┼──> │     Traefik      │    radarr.<DOMAIN> ──> 127.0.0.1:7878
                      │    └──────────────────┘    pihole.<DOMAIN> ──> 127.0.0.1:8080/admin
  pihole.<DOMAIN> ────┘
```

Apart from that, this project also provides:

- Configuration for the [PiHole](pihole) service, which is used as the DNS server for the local network
- Scripts to keep the [DuckDNS](https://www.duckdns.org/) domain pointing to your public IP, scan the local network with `arp-scan`, and [set up SSH access](utils/ssh) to the server

## 🔍 Usage

```bash
# Traefik
npm run traefik:start
npm run traefik:restart
# PiHole
npm run pihole:start
npm run pihole:restart
```

Both `start` and `restart` create the missing config files from their examples first (`npm run traefik:setup` / `npm run pihole:setup`).

The Traefik dashboard is available from the local network at `https://traefik.<DOMAIN>`.

## 🛠️ Setup

In order to set up this project properly, you would need to edit your router's network settings:

1. Set static IP address for the machine where this project is meant to be setup at

- For `tp-link` router: `Advanced` -> `Network` -> `DHCP Server` -> `Address Reservation` -> `Add a new entry providing a static IP address (e.g. "192.168.0.10"), and a MAC address from one of the connected devices`

2. Configure default DNS server for your local network. In your router settings look for `Primary DNS` address change, and set it with the IP address provided for the static IP configuration above

- For `tp-link` router: `Advanced` -> `Network` -> `DHCP Server` -> `Primary DNS`

3. Configure port forwarding, to forward requests from the Internet to the reverse proxy

- For `tp-link` router: `Advanced` -> `NAT Forwarding` -> `Port Forwarding` -> `Add two new entries with the same static IP address and mappings for ports 80->80 and 443->443 (protocol = All)`

At this point your router should be able to always give the same static IP to your reverse proxy server and forward all requests on ports `80/443` (HTTP/HTTPS)

4. Create the config files and fill in your values (see [Configuration](#-configuration)): `npm run traefik:setup`
5. Point the DuckDNS domain to your public IP, and keep it updated every 5 minutes: `npm run duckdns:update-ip && npm run duckdns:update-ip:schedule`
6. Start Traefik: `npm run traefik:start`. The SSL certificate is issued automatically, see [here](traefik/acme)
7. Configure and start the PiHole service following [these instructions](pihole). The wildcard DNS record described there is required: without it, requests from the local network are treated as requests from the Internet
8. _[Optional]_ Schedule an hourly scan of the local network devices: `npm run arp-scan:schedule [interface]` (`wlan0` by default)
9. _[Optional]_ Set up SSH access to the server following [these instructions](utils/ssh)

## ⚙️ Configuration

### `.env`

Created from [.env.example](.env.example). Changes require `npm run traefik:restart`.

| Variable                                                   | Description                                                                                       |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `ROUTER_IP`                                                | The router's IP. Requests from it are treated as external (see [below](#local-network-detection)) |
| `LAN_SUBNET`                                               | The local network, e.g. `192.168.0.0/24`                                                          |
| `DOMAIN`                                                   | The DuckDNS domain, e.g. `mydomain.duckdns.org`. Services are available at `<service>.<DOMAIN>`   |
| `DUCKDNS_TOKEN`                                            | The DuckDNS token, used to update the IP and to get the SSL certificate                           |
| `PROXY_AUTH_HEADER`                                        | The header with the token, e.g. `X-Proxy-Authorization` (see [Authorization](#authorization))     |
| `PROXY_API_KEY`                                            | The tokens for that header (see [Authorization](#authorization))                                  |
| `PIHOLE_PORT_DNS`, `PIHOLE_PORT_HTTP`, `PIHOLE_PORT_HTTPS` | The PiHole ports on the server                                                                    |

### `traefik/config/routes.yaml`

Created from [routes.yaml.example](traefik/config/routes.yaml.example) and ignored by git, so adding a service doesn't require a commit. Traefik watches the file and applies changes without a restart.

The file is a Go template: `{{ $domain }}` and `{{ $lan }}` are filled in from `.env`. If a required variable is missing, Traefik logs the error and loads no routes from the file.

#### Local network only

Add a router and a service:

```yaml
http:
    routers:
        radarr:
            rule: 'Host(`radarr.{{ $domain }}`) && {{ $lan }}'
            service: radarr
    services:
        radarr:
            loadBalancer:
                servers: [{ url: http://127.0.0.1:7878 }]
```

Requests from the Internet get `404`.

#### Available from the Internet

Add a second router without the `{{ $lan }}` condition:

```yaml
hub-remote:
    rule: 'Host(`hub.{{ $domain }}`)'
    service: hub
    middlewares: [rate-limit, proxy-auth]
```

Traefik checks longer rules first, so requests from the local network still match the local router (no auth, no rate limit), and all other requests match the `-remote` one. To skip the authorization, leave only `rate-limit` in `middlewares`.

#### Redirect from the root path

Some services start at a different path, e.g. PiHole at `/admin`. See the `pihole-admin` middleware in the example.

#### Rate limit

The `rate-limit` middleware limits the number of requests per client IP. Requests over the limit get `429`.

#### Authorization

The `proxy-auth` middleware checks that the `PROXY_AUTH_HEADER` header (e.g. `X-Proxy-Authorization`) contains one of the `PROXY_API_KEY` tokens, and removes the header before the request reaches the service. Requests without a valid token get `403`. A custom header is used because the services behind the proxy use `Authorization` themselves.

Generate a token, set it as `PROXY_API_KEY` in `.env`, and run `npm run traefik:restart` (`npm run traefik:setup` warns while it's empty). To give each app its own token (to revoke one without changing the others), generate more and separate them with commas: `PROXY_API_KEY=token1,token2`, then run `npm run traefik:restart`.

```bash
# npm run traefik:token:generate [alias]
# [alias] is added at the beginning to tell the tokens apart: "phone_<random>"
npm run traefik:token:generate phone
```

`PROXY_API_KEY` is required: an empty token would let requests without the header through, so `routes.yaml` isn't loaded without it.

The check is done by the [API Token Middleware](https://github.com/Aetherinox/traefik-api-token-middleware) plugin, which Traefik downloads on start (version in [traefik.yaml](traefik/traefik.yaml)). If the download fails, the routers that use `proxy-auth` are disabled.

> **Note:** The Traefik dashboard shows the middleware settings, including the token. It's available from the local network only.

#### Local network detection

A request is local when it comes from `LAN_SUBNET` or `127.0.0.1`, except `ROUTER_IP`. When a local device resolves `<DOMAIN>` to the public IP, its requests come back through the router with the router's IP, which is why the router is excluded, and why PiHole needs to resolve `<DOMAIN>` to the server's local IP.

## 🛠️ Troubleshooting

### 404 Not Found

No router matched the request. Check that the service is in `routes.yaml`, and check `docker logs traefik` for errors in the file. If it happens from the local network only for local services, your device resolves `<DOMAIN>` to the public IP, see [PiHole](pihole).

### 502 Bad Gateway

Traefik can't reach the service, check whether it's up and the port in `routes.yaml` is correct.

### Unreachable IP Address

Sometimes, it can happen that you are not able to reach (or `ping`) the server's device by its IP even when it is in the same local network as your device.

One of the reasons is the `Docker Desktop` app - it can alter the network settings and prevent you from reaching other devices in your local network. Try to exit the app and ping the server again.

### DNS Resolution Issues

In scenarios where you can reach the server device but the DNS is still not resolving the hostname you are using, try flushing the DNS cache on your device:

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

### mDNS Resolution Issues

If there are any issues related to not receiving packets via mDNS, the first thing to try is to restart the mDNS service:

```bash
sudo systemctl restart avahi-daemon
```

## ❓ Questions

If you have any questions you can start a discussion.  
If you think something works not as expected or you want to request a new feature, you can create an issue with the appropriate template selected.

## 🤝 Contributing

Pull requests are welcome.  
For major changes, please open an issue first to discuss what you would like to change.

## 🎫 License

[MIT](LICENSE)
