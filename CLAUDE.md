# Claude Code Documentation

This document provides context for AI agents working on this project.

## Project Overview

Configuration for running Traefik (reverse proxy) and PiHole (local DNS) on a home server via Docker Compose, plus helper scripts. Traefik routes `<service>.<DOMAIN>` (a wildcard DuckDNS domain) to services on different ports. Requests from the local network are always allowed; selected services are also available from the Internet with a rate limit and a custom `X-Proxy-Authorization` header (the services use `Authorization` themselves). There is no application code.

## Structure

- **docker-compose.yaml** - `traefik` (`network_mode: host`, env from `.env`) and `pihole` (env from `pihole/.env`, ports from `.env`)
- **.env** (from `.env.example`, gitignored) - `ROUTER_IP`, `LAN_SUBNET`, `DOMAIN`, `DUCKDNS_TOKEN`, `FORWARD_AUTH_PORT`, `PIHOLE_PORT_*`
- **traefik/traefik.yaml** - Static config: entry points (80 -> 443 redirect), the `duckdns` ACME resolver (DNS challenge), file provider watching `traefik/config/`
- **traefik/config/routes.yaml** (from `routes.yaml.example`, gitignored) - Dynamic config: wildcard certificate, middlewares, routers, services
- **traefik/acme/acme.json** (gitignored) - Certificates issued by Traefik
- **traefik/scripts/setup.sh**, **pihole/scripts/setup.sh** - Create the gitignored files from their examples, never overwrite
- **pihole/** - PiHole env example, `data/` and `dnsmasq.d/` volumes (gitignored)
- **utils/** - Scripts: `arp-scan/`, `duckdns/` (IP update and cron scheduling), `ssh/` (client/server setup, verify), `scripts/read-env.sh` (sourced helper that reads a variable from the root `.env`)

## Key Patterns

- Environment variables can't be used in `traefik.yaml` (static config). `routes.yaml` is a Go template: `{{ env "VAR" }}`, with `fail` guards for required variables
- `{{ $lan }}` in `routes.yaml` matches `LAN_SUBNET` or `127.0.0.1` except `ROUTER_IP` (requests that loop back through the router come from its IP). PiHole resolves `<DOMAIN>` to the server's local IP via `FTLCONF_misc_dnsmasq_lines`
- Local-only service: router with `Host(...) && {{ $lan }}`. Internet access: an extra `<name>-remote` router with only `Host(...)` and `[rate-limit, proxy-auth, strip-proxy-auth]` middlewares; the longer local rule wins for local requests
- `proxy-auth` is a `forwardAuth` to `127.0.0.1:FORWARD_AUTH_PORT`. That service doesn't exist yet
- Changes to `routes.yaml` apply without a restart; changes to `.env` or `traefik.yaml` need `npm run traefik:restart`
- Shell scripts use `$0` for their own path (they're run with `sh` or `bash`), `BASH_SOURCE` only in sourced files

## Commands

```bash
npm run traefik:start        # Also traefik:restart, traefik:setup
npm run pihole:start         # Also pihole:restart, pihole:setup
npm run duckdns:update-ip    # Also duckdns:update-ip:schedule
npm run arp-scan             # Also arp-scan:schedule
npm run ssh:setup:client     # Also ssh:setup:server, ssh:verify
npm run prettier             # Format code
```

## Testing

No tests exist. Test scripts in a scratch copy or a container, never against the real `~/.ssh`, crontab or system config.
