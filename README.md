# My Reverse Proxy

The project is a simple reverse proxy that is used mainly to forward requests for domains with the same IP address to the same machine but on different ports.

This server is also designed to allow requests from the local network but require authorization when the request comes from the Internet.

It is super simple and serves a single purpose - forwarding HTTP requests to the right server on the right port depending on the domain name the request has been made to.

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

```json
{
    "test.domain.home": {
        "hostname": "111.222.333.4",
        "port": 8888
    }
}
```

With this configuration, any request coming to `http://test.domain.home` will be forwarded to `http://111.222.333.4:8888` (if request comes from the local network).

- For requests coming from the Internet, another config file `config/addresses.[dev|prod].json` needs to be specified:

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

## 🛠️ Troubleshooting

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
