# Claude Code Documentation

This document provides context for AI agents working on this project.

## Project Overview

A Node.js reverse proxy server that forwards requests for domains with the same IP address to different backend services running on various ports. The server allows unrestricted access from local network but requires authorization for external requests.

## Architecture

### Source Files (`src/`)

- **index.js** - Main entry point. Sets up Express HTTPS/HTTP servers with rate limiting and authorization middleware
- **request.js** - Request routing logic. Maps incoming hostnames to target addresses using config files
- **auth.js** - Authentication module. Provides `authorized()` for request auth and `fromLocalNetwork()` for IP checks
- **logger.js** - Colored console logging with timestamps
- **ssl.js** - SSL certificate loading

### Configuration Files (`config/`)

All config files have `.dev.json` and `.prod.json` variants based on `NODE_ENV`:

- **addresses.{env}.json** - Hostname to backend mapping

    - `protocol` - Target protocol (default: "http")
    - `hostname` - Target IP/hostname (default: "127.0.0.1")
    - `port` - Target port (default: 80)
    - `startUrl` - Redirect path for root requests
    - `localOnly` - If true, only accessible from local network

- **secrets.{env}.json** - Auth credentials and local network pattern

    - `username`, `password`, `secret` - Credentials for external access
    - `localAddressPattern` - Regex to identify local IPs

- **limits.{env}.json** - Rate limiting configuration

## Key Patterns

- Environment detection via `NODE_ENV` (defaults to "dev")
- Local network requests bypass rate limiting and auth
- External requests require `X-Proxy-Authorization` header with base64-encoded credentials
- Config files are loaded at startup, not dynamically

## Commands

```bash
npm start          # Run locally (dev mode)
npm run start:prod # Run via Docker (prod mode)
npm run eslint     # Lint and fix
npm run prettier   # Format code
```

## Testing

No unit tests currently exist in the project.
