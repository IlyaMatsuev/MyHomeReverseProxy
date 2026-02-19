# My Reverse Proxy

The project is a reverse proxy that is used mainly to forward requests for domains with the same IP address to the same machine but on different ports.

This server is also designed to allow requests from the local network but require authorization when the request comes from the Internet.

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

## ⚙️ Configuration

- The server is configurable via the `config/addresses.[dev|prod].json` file.
  The key is the domain name that needs to be resolved, the value is the object containing of the hostname and the port where the requests on that domain need to be forwarded to:

```json5
{
    'test.domain.home': {
        // "http" by default
        protocol: 'https',
        // "localhost" by default
        hostname: '111.222.333.4',
        port: 8888,
        // "" by default. Url where the request should be redirected to, when accessing root address (e.g. "https://service.home" to be redirected to "http://localhost:8000/login")
        startUrl: '',
    },
}
```

With this configuration, any request coming to `http://test.domain.home` will be forwarded to `http://111.222.333.4:8888` (if request comes from the local network).

- For requests coming from the Internet, another config file `config/secrets.[dev|prod].json` needs to be specified:

```json
{
    "username": "user",
    "password": "pass",
    "secret": "secret",
    "localAddressPattern": "^127\\.0\\.0\\.1$"
}
```

You specify user credentials that will need to be passed on to the `X-Proxy-Authorization` header.

You can also use a query parameter `host` for your requests to the proxy in order to resolve the destination server.

- Another configuration file `config/limits.[dev|prod].json` is designed to set up limits on the incoming requests. Its responsibility is to make the server more secure once it's accessible in the global Internet:

```json
{
    "windowMs": 900000,
    "requestsPerWindow": 1,
    "skipSuccessful": false,
    "blocked": {
        "statusCode": 403,
        "message": {
            "message": "Forbidden"
        }
    }
}
```

`windowMs` - The time per which the limits on requests from the Internet counts

`requestsPerWindow` - The number of requests from the Internet per specified window (`windowMs`)

`skipSuccessful` - If `true`, successful requests (`status code < 400`) are not counted against the limit

`blocked.statusCode` - The HTTP status code to return once the `requestsPerWindow` limit is hit

`blocked.message` - The message to be returned in the HTTP response body once the `requestsPerWindow` limit is hit

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

4. Start the reverse proxy on your server: `npm run start:prod`
5. Configure the automatic network MAC addresses scan by following the guide in [this script](scripts/arp-scan/arp-scan.sh)
6. Configure the PiHole service following [these instructions](config/pihole). PiHole service can be started with: `npm run pihole:start:prod`
7. Now all you need to do is update `addresses.prod.json`, `secrets.prod.json`, and `limits.prod.json` according to your needs. Enjoy!

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
