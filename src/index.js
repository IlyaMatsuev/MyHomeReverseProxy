const express = require('express');
const https = require('https');
const cors = require('cors');
const bodyParser = require('body-parser');
const { rateLimit } = require('express-rate-limit');
const { getSSLOptions } = require('./ssl');
const { httpRequest } = require('./request');
const { authorized, fromLocalNetwork } = require('./auth');
const { log, warn, error } = require('./logger');

const PORT = 443;
const PORT_HTTP = 80;
const ENV = process.env.NODE_ENV || 'dev';
const addresses = require(`../config/addresses.${ENV}.json`) || {};
const limits = require(`../config/limits.${ENV}.json`) || {};

const limiter = rateLimit({
    windowMs: limits.windowMs,
    limit: limits.requestsPerWindow,
    standardHeaders: false,
    legacyHeaders: false,
    statusCode: limits.blocked.statusCode,
    message: limits.blocked.message,
    skip: request => {
        const local = fromLocalNetwork(request.ip);
        if (local) {
            log(`Skipping rate limiter for local request from ${request.ip}`);
        }
        return local;
    },
});

const server = express();

server.use(cors());
server.use(bodyParser.json());
server.use(limiter);

server.use((request, response) => {
    const host = request.get('x-host') || request.get('host');
    const clientAddress = request.ip;
    log(`Received request on "${host}" from "${clientAddress}"`);

    if (!authorized(request)) {
        warn(`The incoming request from "${clientAddress}" was not authorized`);
        response.status(403).json({ message: 'Forbidden' });
        return;
    }

    const targetAddress = addresses[host];
    if (!targetAddress) {
        log(`Could not resolve host: ${host}`);
        response.status(404).json({ message: 'Not Found' });
        return;
    }
    log(`Resolved address: ${targetAddress.hostname}:${targetAddress.port}${request.url}`);

    const options = {
        hostname: targetAddress.hostname,
        port: targetAddress.port,
        uri: request.url,
        method: request.method,
        headers: request.headers,
        data: request.body,
    };

    httpRequest(options)
        .then(res => response.set(res.headers).status(res.statusCode).end(res.data))
        .catch(e => {
            error(`Error: ${e}`);
            error(`Stack Trace: ${e.stack}`);
            response.status(500).json({ message: e.message });
        });
});

const sslOptions = getSSLOptions();
if (sslOptions) {
    https.createServer(sslOptions, server).listen(PORT, '0.0.0.0', () => log(`Listening on port ${PORT}`));
} else {
    warn('Running HTTP server since no SSL certificate has been provided');
    server.listen(PORT_HTTP, '0.0.0.0', () => log(`Listening on port ${PORT_HTTP}`));
}
