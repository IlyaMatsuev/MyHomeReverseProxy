/**
 * Extracts the target host from a request, preferring the "x-host" header over "host"
 * @param request The Express.js request object or a raw http.IncomingMessage
 * @return {string|undefined}
 */
exports.getHost = function (request) {
    if (typeof request.get === 'function') {
        return request.get('x-host') || request.get('host');
    }
    return request.headers['x-host'] || request.headers.host;
};
