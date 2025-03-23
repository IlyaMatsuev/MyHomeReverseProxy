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

4. Copy the `.key` and `fullchain.cer` files to the project `ssl/` folder. Both of these files need to be renamed to have `.pem` extension (to avoid compatibility issues)

## Renewing the certificate

1. Renew the certificate manually (`acme.sh` handles renewal automatically every **60 days**, but you can force it if needed)

```sh
~/.acme.sh/acme.sh --renew -d domain.duckdns.org --ecc
```

2. Copy/Update the `.key` and `fullchain.cer` files to the project `ssl/` folder. Both of these files need to be renamed to have `.pem` extension (to avoid compatibility issues)

## Tips

- To list all existing domain certificates:

```sh
~/.acme.sh/acme.sh --list
```
