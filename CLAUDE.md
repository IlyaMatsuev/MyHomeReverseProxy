# Claude Code Documentation

This document provides context for AI agents working on this project.

## Project Overview

A Node.js reverse proxy server that forwards requests for domains with the same IP address to different backend services running on various ports. The server allows unrestricted access from local network but requires authorization for external requests.

## Architecture

### Source Files (`src/`)

- **index.js** - Main entry point. Sets up Express HTTPS/HTTP servers with rate limiting and authorization middleware
- **request.js** - Request routing logic. Maps incoming hostnames to target addresses using config files
- **auth.js** - Authentication module. Provides `authorized()` for request auth and `fromLocalNetwork()` for IP checks
- **config.js** - Configuration module. Loads YAML config, provides getters, and watches for file changes
- **logger.js** - Colored console logging with timestamps
- **ssl.js** - SSL certificate loading

### Configuration Files (`config/`)

Configuration is stored in a single YAML file per environment: `config.dev.yaml` or `config.prod.yaml` (based on `NODE_ENV`).

The config file contains three sections:

- **addresses** - Hostname to backend mapping (keyed by hostname)

    - `protocol` - Target protocol (default: "http")
    - `hostname` - Target IP/hostname (default: "127.0.0.1")
    - `port` - Target port (default: 80)
    - `startUrl` - Redirect path for root requests
    - `localOnly` - If true, only accessible from local network

- **secrets** - Auth credentials and local network pattern

    - `username`, `password`, `secret` - Credentials for external access
    - `localAddressPattern` - Regex to identify local IPs

- **limits** - Rate limiting configuration

    - `windowMs` - Time window in milliseconds
    - `requestsPerWindow` - Max requests per window
    - `skipSuccessful` - Skip successful requests from count
    - `blocked.statusCode` - HTTP status for blocked requests
    - `blocked.message` - Response body for blocked requests

## Key Patterns

- Environment detection via `NODE_ENV` (defaults to "dev")
- Local network requests bypass rate limiting and auth
- External requests require `X-Proxy-Authorization` header with base64-encoded credentials
- Config file is watched for changes and reloaded automatically
- Address and secret changes take effect immediately without restart
- Rate limiter changes require server restart (warning is logged when detected)

## Commands

```bash
npm start          # Run locally (dev mode)
npm run start:prod # Run via Docker (prod mode)
npm run eslint     # Lint and fix
npm run prettier   # Format code
```

## Testing

No unit tests currently exist in the project.
