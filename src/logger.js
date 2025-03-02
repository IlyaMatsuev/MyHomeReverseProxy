/**
 * Returns a message for logging in stdout
 * @param message The message
 * @return {string}
 */
exports.log = function (message) {
    return `[${new Date().toISOString()}] - ${message}`;
};
