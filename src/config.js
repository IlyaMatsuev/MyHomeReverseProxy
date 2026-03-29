const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const { log, warn, error } = require('./logger');

const ENV = process.env.NODE_ENV || 'dev';
const CONFIG_FILE_PATH = path.resolve(__dirname, `../config/config.${ENV}.yaml`);

let config = {};
let watchDebounceTimer = null;
const DEBOUNCE_MS = 100;

function loadConfig() {
    try {
        const fileContents = fs.readFileSync(CONFIG_FILE_PATH, 'utf8');
        const newConfig = yaml.load(fileContents);
        config = newConfig || {};
        log(`Config loaded from ${CONFIG_FILE_PATH}`, true);
        return true;
    } catch (e) {
        error(`Failed to load config from ${CONFIG_FILE_PATH}: ${e.message}`);
        return false;
    }
}

function watchConfig() {
    try {
        fs.watch(CONFIG_FILE_PATH, eventType => {
            if (eventType === 'change') {
                if (watchDebounceTimer) {
                    clearTimeout(watchDebounceTimer);
                }
                watchDebounceTimer = setTimeout(() => {
                    log('Config file changed, reloading...', true);
                    const prevLimits = JSON.stringify(config.limits);
                    if (loadConfig()) {
                        if (JSON.stringify(config.limits) !== prevLimits) {
                            warn('Rate limiter config changed. Server restart required for changes to take effect.');
                        }
                    }
                }, DEBOUNCE_MS);
            }
        });
        log('Watching config file for changes', true);
    } catch (e) {
        error(`Failed to watch config file: ${e.message}`);
    }
}

loadConfig();
watchConfig();

module.exports = {
    getAddresses: () => config.addresses || {},
    getSecrets: () => config.secrets || {},
    getLimits: () => config.limits || {},
};
