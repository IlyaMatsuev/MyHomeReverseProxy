const express = require('express');
const https = require('https');
const { rateLimit } = require('express-rate-limit');
const { getSSLOptions } = require('./ssl');
const { proxyRequest } = require('./request');
const { authorized, fromLocalNetwork } = require('./auth');
const { log, warn, error } = require('./logger');

const PORT = 443;
const PORT_HTTP = 80;
const ENV = process.env.NODE_ENV || 'dev';
const limits = require(`../config/limits.${ENV}.json`) || {};

const limiter = rateLimit({
    windowMs: limits.windowMs,
    limit: limits.requestsPerWindow,
    standardHeaders: false,
    legacyHeaders: false,
    statusCode: limits.blocked.statusCode,
    message: limits.blocked.message,
    skipSuccessfulRequests: limits.skipSuccessful,
    skip: request => {
        const local = fromLocalNetwork(request.ip);
        if (local) {
            log(`Skipping rate limiter for local request from ${request.ip}`);
        }
        return local;
    },
});

const server = express();

server.use(limiter);

server.use((request, response, next) => {
    if (!authorized(request)) {
        warn(`The incoming request from "${request.ip}" was not authorized`);
        response.status(403).json({ message: 'Forbidden' });
        return;
    }

    proxyRequest(request, response, next).catch(e => {
        error(`Error: ${e}`);
        error(`Stack Trace: ${e.stack}`);
        response.status(500).json({ message: e.message });
    });
});

const sslOptions = getSSLOptions();
if (sslOptions) {
    https.createServer(sslOptions, server).listen(PORT, '0.0.0.0', () => log(`Listening on port ${PORT}`, true));
} else {
    warn('Running HTTP server since no SSL certificate has been provided');
    server.listen(PORT_HTTP, '0.0.0.0', () => log(`Listening on port ${PORT_HTTP}`, true));
}
