const chalk = require('chalk');

/**
 * Logs an informational message to stdout
 * @param message The message
 */
exports.log = function (message) {
    printLog(message, 'white');
};

/**
 * Logs a warning message to stdout
 * @param message The message
 */
exports.warn = function (message) {
    printLog(message, 'yellow');
};

/**
 * Logs an error message to stdout
 * @param message The message
 */
exports.error = function (message) {
    printLog(message, 'red');
};

function printLog(message, color) {
    console.log(`${printDateTime()} - ${chalk[color](message)}`);
}

function printDateTime() {
    return chalk.green(`[${[new Date().toISOString()]}]`);
}
