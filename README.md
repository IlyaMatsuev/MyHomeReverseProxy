# My Reverse Proxy

The project is a simple reverse proxy that is used mainly to forward requests for domains with the same IP address to the same machine but on different ports.

This server is also designed to allow requests from the local network but require authorization when the request comes from the Internet.

It is super simple and serves a single purpose - forwarding HTTP requests to the right server on the right port depending on the domain name the request has been made to.

## 🔍 Usage

To run the server locally (uses `NODE_ENV=dev`):

```bash
npm start
```

To run the server via the docker image (uses `NODE_ENV=prod`):

```bash
npm run start:prod
```

## 🛠️ Configuration

The server is configurable via the `config/addresses.[dev|prod].json` file.
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

For requests coming from the Internet, there needs to be specified another config file `config/addresses.[dev|prod].json`:

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

## ❓ Questions

If you have any questions you can start a discussion.  
If you think something works not as expected or you want to request a new feature, you can create an issue with the appropriate template selected.

## 🤝 Contributing

Pull requests are welcome.  
For major changes, please open an issue first to discuss what you would like to change.  
Please make sure to update tests as appropriate.

## 🎫 License

[MIT](LICENSE)
