const { scryptSync, timingSafeEqual } = require('crypto');
const { getSecrets } = require('./config');

const AUTH_HEADER_NAME = 'X-Proxy-Authorization';

// Cached local address regex - invalidates when pattern changes
let localAddressPattern = { pattern: null, regex: null };

/**
 * Checks if the request is authorized to be forwarded via the proxy
 * @param request The Express.js request object
 * @return {boolean}
 */
exports.authorized = function (request) {
    if (module.exports.fromLocalNetwork(request.ip)) {
        return true;
    }
    const authHeader = request.header(AUTH_HEADER_NAME);
    if (!authHeader) {
        return false;
    }
    const secrets = getSecrets();
    const [username, password, secret] = Buffer.from(authHeader, 'base64').toString().split(':');
    return username === secrets.username && compareCredential(secrets.password, password) && compareCredential(secrets.secret, secret);
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
