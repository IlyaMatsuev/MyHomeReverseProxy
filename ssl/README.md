# SSL Certificate Setup

This guide explains how to generate and renew an SSL certificate for the reverse-proxy server.

## Prerequisites

- You need to have a registered domain name. I'm using [DuckDNS](https://www.duckdns.org/) for that
- All `domain.duckdns.org` references in the following instructions need to be replaced with an actual registered domain name (e.g. `ilya.duckdns.org`)

## Generating a certificate

1. Install `acme.sh` (if not installed yet)

```sh
curl https://get.acme.sh | sh
source ~/.bashrc
```

2. Set up the DuckDNS API token (required only for the next command, does not have to be set globally)

```sh
export DuckDNS_Token="TOKEN"
```

3. Issue the SSL certificate using DNS challenge

```sh
~/.acme.sh/acme.sh --issue --dns dns_duckdns -d domain.duckdns.org --ecc
```

After the successful challenge, the certificate files are stored in `~/.acme.sh/domain.duckdns.org_ecc/`

4. Install the certificate to copy the key into the project `ssl/` folder

```sh
~/.acme.sh/acme.sh --install-cert -d domain.duckdns.org \
--ecc \
--key-file /path-to-project/ssl/key.pem \
--fullchain-file /path-to-project/ssl/fullchain.pem
```

## Renewing the certificate

1. Renew the certificate manually (`acme.sh` handles renewal automatically every **60 days**, but you can force it if needed)

```sh
~/.acme.sh/acme.sh --renew -d domain.duckdns.org --ecc --dns dns_duckdns --dnssleep 60
```

2. Install the certificate into `acme.sh` and copy the key into the project `ssl/` folder

```sh
~/.acme.sh/acme.sh --install-cert -d domain.duckdns.org \
--ecc \
--key-file /path-to-project/ssl/key.pem \
--fullchain-file /path-to-project/ssl/fullchain.pem \
--reloadcmd "docker restart reverse-proxy"
```

## Tips

- To list all existing domain certificates:

```sh
~/.acme.sh/acme.sh --list
```
