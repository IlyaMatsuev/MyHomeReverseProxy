const { createProxyMiddleware } = require('http-proxy-middleware');
const { fromLocalNetwork } = require('./auth');
const { log, warn } = require('./logger');

const DEFAULT_PROTOCOL = 'http';
const DEFAULT_HOSTNAME = '127.0.0.1';
const DEFAULT_PORT = 80;
const ENV = process.env.NODE_ENV || 'dev';
const addresses = require(`../config/addresses.${ENV}.json`) || {};

const proxyMiddleware = createProxyMiddleware({
    changeOrigin: false,
    ws: true,
    router: request => getDestinationAddress(addresses[getHost(request)], request.url),
});

/**
 * Forwards the HTTP request to the destination, using mappings from the config/addresses.{dev/prod}.json
 * @param request HTTP request
 * @param response HTTP response
 * @param next Express callback function
 * @return {Promise<void>}
 */
exports.proxyRequest = async function (request, response, next) {
    const host = getHost(request);
    log(`Received request on "${host}" from "${request.ip}"`, true);

    const targetAddress = addresses[host];
    if (!targetAddress) {
        warn(`Could not resolve host: ${host}`);
        return response.status(404).json({ message: 'Not Found' });
    }

    if (targetAddress.localOnly && !fromLocalNetwork(request.ip)) {
        warn(`Access denied to local-only address "${host}" from external IP "${request.ip}"`);
        return response.status(403).json({ message: 'Forbidden' });
    }

    request.headers.host = host;
    return proxyMiddleware(request, response, next);
};

function getHost(request) {
    return request.get('x-host') || request.get('host');
}

function getDestinationAddress(address, requestUrl) {
    const addressParts = [
        `${address.protocol || DEFAULT_PROTOCOL}://`,
        `${address.hostname || DEFAULT_HOSTNAME}:`,
        address.port || DEFAULT_PORT,
        address.startUrl && requestUrl === '/' ? address.startUrl : '',
    ];
    const resolvedAddress = addressParts.join('');
    log(`Resolved address: ${resolvedAddress}${requestUrl}`);
    return resolvedAddress;
}
