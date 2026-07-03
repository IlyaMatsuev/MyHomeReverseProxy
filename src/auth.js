const { scryptSync, timingSafeEqual } = require('crypto');
const { getSecrets, getAddresses } = require('./config');
const { getHost } = require('./utils');

const AUTH_HEADER_NAME = 'X-Proxy-Authorization';

// Cached local address regex - invalidates when pattern changes
let localAddressPattern = { pattern: null, regex: null };

/**
 * Checks if the request is authorized to be forwarded via the proxy
 * @param request The Express.js request object
 * @return {boolean}
 */
exports.authorized = function (request) {
    const ip = request.ip || request.socket?.remoteAddress;
    if (module.exports.fromLocalNetwork(ip)) {
        return true;
    }
    const host = getHost(request);
    if (getAddresses()[host]?.skipAuth) {
        return true;
    }
    const authHeader =
        typeof request.header === 'function' ? request.header(AUTH_HEADER_NAME) : request.headers[AUTH_HEADER_NAME.toLowerCase()];
    if (!authHeader) {
        return false;
    }
    const secrets = getSecrets();
    const [username, password, secret] = Buffer.from(authHeader, 'base64').toString().split(':');
    return (
        username === secrets.username && compareCredential(secrets.passwordHash, password) && compareCredential(secrets.secretHash, secret)
    );
};

/**
 * Checks if the provided IP address is coming from the local network or not
 * @param remoteAddress The IP address to check
 * @return {boolean}
 */
exports.fromLocalNetwork = function (remoteAddress) {
    const secrets = getSecrets();
    const pattern = secrets.localAddressPattern;
    if (localAddressPattern.pattern !== pattern) {
        localAddressPattern = { pattern, regex: new RegExp(pattern) };
    }
    return localAddressPattern.regex.test(remoteAddress);
};

function compareCredential(storedHash, credential) {
    const [hashedCredential, salt] = storedHash.split('.');
    const hashBuffer = scryptSync(credential, salt, 64);
    return timingSafeEqual(Buffer.from(hashedCredential, 'hex'), hashBuffer);
}
