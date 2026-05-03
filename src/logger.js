const chalk = require('chalk');

const DEV_ENV = 'dev';
const ENV = process.env.NODE_ENV || DEV_ENV;

/**
 * Logs an informational message to stdout
 * @param message The message
 * @param forcePrint Print the message even, no matter what environment it is
 */
exports.log = function (message, forcePrint = false) {
    printLog(message, 'white', ENV === DEV_ENV || forcePrint);
};

/**
 * Logs a warning message to stdout
 * @param message The message
 */
exports.warn = function (message) {
    printLog(message, 'yellow', true);
};

/**
 * Logs an error message to stdout
 * @param message The message
 */
exports.error = function (message) {
    printLog(message, 'red', true);
};

function printLog(message, color, forcePrint) {
    if (forcePrint) {
        console.log(`${printDateTime()} - ${chalk[color](message)}`);
    }
}

function printDateTime() {
    const now = new Date();
    const local = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
    return chalk.green(`[${local.toISOString().slice(0, -1)}]`);
}
