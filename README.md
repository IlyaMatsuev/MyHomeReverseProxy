# My Reverse Proxy

[![Publish Package](https://github.com/IlyaMatsuev/MyReverseProxy/actions/workflows/publish.yaml/badge.svg)](https://github.com/IlyaMatsuev/MyReverseProxy/actions/workflows/publish.yaml)

The project is a reverse proxy that is used mainly to forward requests for domains with the same IP address to the same machine but on different ports.

This server is designed to allow requests from the local network but require authorization when the request comes from the Internet.

```
  foo.home ─────────────┐
                        │    ┌──────────────────┐    foo.home ──> 127.0.0.1:8080
  bar.home ─────────────┼──> │  Reverse Proxy   │    bar.home ──> 192.168.0.5:9000
                        │    └──────────────────┘    baz.home ──> 127.0.0.1:3000
  baz.home ─────────────┘
```

Apart from that, this project also provides configuration for the [PiHole](config/pihole) service, which is used to specify custom domain names for the local network.

## 🔍 Usage

> Before building/running the server, make sure that the SSL certificate is configured and renewed. SSL setup instructions are described [here](/ssl).

To run the server locally (uses `NODE_ENV=dev`):

```bash
npm start
```

To run the server via the docker image (uses `NODE_ENV=prod`):

```bash
npm run start:prod
```

## 🛠️ Setup

> Before setting up the reverse proxy, please make sure to get the SSL certificate first, following the instructions [here](ssl).

In order to set up this project properly, you would need to edit your router's network settings:

1. Set static IP address for the machine where this project is meant to be setup at

- For `tp-link` router: `Advanced` -> `Network` -> `DHCP Server` -> `Address Reservation` -> `Add a new entry providing a static IP address (e.g. "192.168.0.10"), and a MAC address from one of the connected devices`

2. Configure default DNS server for your local network. In your router settings look for `Primary DNS` address change, and set it with the IP address provided for the static IP configuration above

- For `tp-link` router: `Advanced` -> `Network` -> `DHCP Server` -> `Primary DNS`

3. Configure port forwarding, to forward requests from the Internet to the reverse proxy

- For `tp-link` router: `Advanced` -> `NAT Forwarding` -> `Port Forwarding` -> `Add two new entries with the same static IP address and mappings for ports 80->80 and 443->443 (protocol = All)`

At this point your router should be able to always give the same static IP to your reverse proxy server and forward all requests on ports `80/443` (HTTP/HTTPS)

4. Configure `config/config.prod.yaml` according to your needs — see the [Configuration](#-configuration) section below for all available options.
5. Start the reverse proxy on your server: `npm run start:prod`
6. Configure the PiHole service following [these instructions](config/pihole). PiHole service can be started with: `npm run pihole:start:prod`
7. Configure the automatic network MAC addresses scan by following the guide in [this script](scripts/arp-scan/arp-scan.sh)

## ⚙️ Configuration

Configuration is stored in a single YAML file per environment:

- `config/config.dev.yaml` — used when `NODE_ENV=dev` (default)
- `config/config.prod.yaml` — used when `NODE_ENV=prod`

The config file has three top-level sections:

### `addresses`

Maps incoming hostnames to backend services:

```yaml
addresses:
    test.domain.home:
        protocol: https # "http" by default
        hostname: 111.222.333.4 # "127.0.0.1" by default
        port: 8888 # 80 by default
        startUrl: /dashboard # redirect path for root requests, "" by default
        localOnly: true # false by default; restrict to local network only
        skipAuth: false # false by default; if true, external requests bypass X-Proxy-Authorization (rate limiting still applies)
```

With this configuration, any request to `test.domain.home` is forwarded to `https://111.222.333.4:8888`.

You can also use a query parameter `host` or header `x-host` for requests to the proxy to specify the destination hostname dynamically.

### `secrets`

Credentials for external (non-local) access and local network detection:

```yaml
secrets:
    username: user
    passwordHash: 49031abf...
    secretHash: 5a2de1adb...
    # Use single quotes to avoid backslash escaping in YAML
    localAddressPattern: '^127\.0\.0\.1$'
```

External requests must include the `X-Proxy-Authorization` header with base64-encoded `username:password:secret` credentials. The plain values are scrypt-hashed at request time and compared against `passwordHash` / `secretHash`. Local requests (matching `localAddressPattern`) bypass authentication entirely.

> **Note:** Always use YAML single-quoted strings for `localAddressPattern` to avoid escape sequence errors. Backslashes in double-quoted YAML strings must be doubled (`\\d`, `\\.`, etc.).

#### Rotating credentials

`passwordHash` and `secretHash` store hash values, so they cannot be edited by hand. Use the `scripts/rotate-credentials.js` node script to set new values and automatically update `config/config.prod.yaml`:

```bash
node scripts/rotate-credentials.js <username> <password> <secret>
```

The change is picked up automatically by the running server (the config file is watched), so no restart is needed.

### `limits`

Rate limiting for external requests:

```yaml
limits:
    windowMs: 900000 # time window in milliseconds
    requestsPerWindow: 10 # max requests per window from external IPs
    skipSuccessful: false # if true, successful requests (< 400) are not counted
    blocked:
        statusCode: 429
        message:
            message: Too Many Requests
```

> **Note:** Changes to `limits` require a server restart to take effect. Changes to `addresses` and `secrets` are picked up automatically.

## 🛠️ Troubleshooting

### 504 Gateway Timeout

When receiving a similar error "Error occurred while trying to proxy", the first thing to check is whether the service you're trying to reach is up.

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
Please make sure to update tests as appropriate.

## 🎫 License

[MIT](LICENSE)
