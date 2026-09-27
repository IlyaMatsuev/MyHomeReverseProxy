# SSL Certificate

Traefik renews the SSL certificate by itself, there are no manual steps.

## How it works

- Traefik requests a wildcard certificate for `*.<DOMAIN>` from Let's Encrypt when it starts (`tls.stores.default.defaultGeneratedCert` in [routes.yaml](../config/routes.yaml.example))
- The domain ownership is proven with a DNS challenge through DuckDNS, using `DUCKDNS_TOKEN` from `.env` (the `duckdns` resolver in [traefik.yaml](../traefik.yaml))
- The certificate is stored in `traefik/acme/acme.json` (this folder) and renewed automatically 30 days before it expires

Prerequisites:

- `DOMAIN` and `DUCKDNS_TOKEN` are set in `.env`
- The domain points to your public IP. Keep it updated with `npm run duckdns:update-ip:schedule`

## Tips

- Check the certificate requests and renewals:

```sh
docker logs traefik 2>&1 | grep -i acme
```

- Force a new certificate (e.g. after changing `DOMAIN`):

```sh
rm traefik/acme/acme.json
npm run traefik:restart
```

- `acme.json` contains the private key. Traefik refuses to use it unless only the owner can read it (it creates the file this way):

```sh
chmod 600 traefik/acme/acme.json
```
