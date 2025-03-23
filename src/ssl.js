const { log } = require('./logger');
const fs = require('fs');

const SSL_KEY_FILE_PATH = './ssl/key.pem';
const SSL_CERT_FILE_PATH = './ssl/fullchain.pem';

/**
 * Returns the SSL options containing key and certificate, necessary for HTTPS protocol. Returns `null` if either of the files does not exist
 * @return { null | { cert: Buffer | string, key: Buffer | string } }
 */
exports.getSSLOptions = function () {
    if (!fs.existsSync(SSL_KEY_FILE_PATH) || !fs.existsSync(SSL_CERT_FILE_PATH)) {
        console.error(log(`No SSL certificate files found under the /ssl directory`));
        return null;
    }
    return {
        key: fs.readFileSync(SSL_KEY_FILE_PATH, 'utf-8'),
        cert: fs.readFileSync(SSL_CERT_FILE_PATH, 'utf-8'),
    };
};
