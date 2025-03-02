const { scryptSync, timingSafeEqual } = require('crypto');

const ENV = process.env.NODE_ENV || 'dev';
const secrets = require(`../config/secrets.${ENV}.json`) || {};

const AUTH_HEADER_NAME = 'X-Proxy-Authorization';

/**
 * Checks if the request is authorized to be forwarded via the proxy
 * @param request The Express.js request object
 * @return {boolean}
 */
exports.authorized = function (request) {
    if (fromLocalNetwork(request.socket.address().address)) {
        return true;
    }
    const authHeader = request.header(AUTH_HEADER_NAME);
    if (!authHeader) {
        return false;
    }
    const [username, passwordHash, secretHash] = Buffer.from(authHeader, 'base64').toString().split(':');
    return (
        username === secrets.username && compareCredential(secrets.password, passwordHash) && compareCredential(secrets.secret, secretHash)
    );
};

function fromLocalNetwork(remoteAddress) {
    return new RegExp(secrets.localAddressPattern, 'g').test(remoteAddress);
}

function compareCredential(credential, hash) {
    const [hashedCredential, salt] = hash.split('.');
    const credentialHashBuffer = scryptSync(credential, salt, 64);
    return timingSafeEqual(Buffer.from(hashedCredential, 'hex'), credentialHashBuffer);
}
