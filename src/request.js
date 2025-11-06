const { createProxyMiddleware } = require('http-proxy-middleware');
const { log, warn } = require('./logger');

const DEFAULT_PROTOCOL = 'http';
const ENV = process.env.NODE_ENV || 'dev';
const addresses = require(`../config/addresses.${ENV}.json`) || {};

const proxyMiddleware = createProxyMiddleware({
    changeOrigin: false,
    ws: true,
    router: Object.keys(addresses).reduce((hostnames, service) => {
        const { protocol, hostname, port } = addresses[service];
        hostnames[service] = `${protocol || DEFAULT_PROTOCOL}://${hostname}:${port}`;
        return hostnames;
    }, {}),
});

/**
 * Forwards the HTTP request to the destination, using mappings from the config/addresses.{dev/prod}.json
 * @param request HTTP request
 * @param response HTTP response
 * @param next Express callback function
 * @return {Promise<void>}
 */
exports.proxyRequest = async function (request, response, next) {
    const host = request.get('x-host') || request.get('host');
    log(`Received request on "${host}" from "${request.ip}"`, true);

    const targetAddress = addresses[host];
    if (!targetAddress) {
        warn(`Could not resolve host: ${host}`);
        return response.status(404).json({ message: 'Not Found' });
    }
    log(`Resolved address: ${targetAddress.hostname}:${targetAddress.port}${request.url}`);

    return proxyMiddleware(request, response, next);
};
