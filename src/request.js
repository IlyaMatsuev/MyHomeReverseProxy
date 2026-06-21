const { createProxyMiddleware } = require('http-proxy-middleware');
const { fromLocalNetwork } = require('./auth');
const { getAddresses } = require('./config');
const { log, warn } = require('./logger');

const DEFAULT_PROTOCOL = 'http';
const DEFAULT_HOSTNAME = '127.0.0.1';
const DEFAULT_PORT = 80;

const proxyMiddleware = createProxyMiddleware({
    changeOrigin: false,
    ws: true,
    xfwd: true,
    router: request => getDestinationAddress(getAddresses()[getHost(request)], request.url),
    onError: (err, request, response) => {
        const host = getHost(request);
        warn(`Service "${host}" is not available: ${err.message}`);
        response.status(503).json({ message: `Service ${host} is not available` });
    },
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

    const addresses = getAddresses();
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

/**
 * Handles a WebSocket upgrade by validating the host and delegating to the proxy middleware
 * @param request HTTP upgrade request (raw http.IncomingMessage)
 * @param socket Underlying network socket
 * @param head First packet of the upgraded stream
 */
exports.handleUpgrade = function (request, socket, head) {
    const host = getHost(request);
    const remoteAddress = request.socket?.remoteAddress;
    log(`Received WS upgrade on "${host}" from "${remoteAddress}"`, true);

    const targetAddress = getAddresses()[host];
    if (!targetAddress) {
        warn(`Could not resolve host for WS upgrade: ${host}`);
        socket.destroy();
        return;
    }

    if (targetAddress.localOnly && !fromLocalNetwork(remoteAddress)) {
        warn(`WS access denied to local-only address "${host}" from external IP "${remoteAddress}"`);
        socket.destroy();
        return;
    }

    request.headers.host = host;
    proxyMiddleware.upgrade(request, socket, head);
};

function getHost(request) {
    if (typeof request.get === 'function') {
        return request.get('x-host') || request.get('host');
    }
    return request.headers['x-host'] || request.headers.host;
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
