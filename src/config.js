const fsPromises = require('fs/promises');
const path = require('path');
const yaml = require('js-yaml');
const { log, warn, error } = require('./logger');

const ENV = process.env.NODE_ENV || 'dev';
const CONFIG_FILE_PATH = path.resolve(__dirname, `../config/config.${ENV}.yaml`);

let config = {};
let watchDebounceTimer = null;
const DEBOUNCE_MS = 100;

async function loadConfig() {
    try {
        const fileContents = await fsPromises.readFile(CONFIG_FILE_PATH, 'utf8');
        const newConfig = yaml.load(fileContents);
        config = newConfig || {};
        log(`Config loaded from ${CONFIG_FILE_PATH}`, true);
        return true;
    } catch (e) {
        error(`Failed to load config from ${CONFIG_FILE_PATH}: ${e.message}`);
        return false;
    }
}

async function watchConfig() {
    try {
        const watcher = fsPromises.watch(CONFIG_FILE_PATH);
        log('Watching config file for changes', true);
        for await (const event of watcher) {
            if (event.eventType !== 'change') {
                continue;
            }
            if (watchDebounceTimer) {
                clearTimeout(watchDebounceTimer);
            }
            watchDebounceTimer = setTimeout(async () => {
                log('Config file changed, reloading...', true);
                const prevLimits = JSON.stringify(config.limits);
                if (await loadConfig()) {
                    if (JSON.stringify(config.limits) !== prevLimits) {
                        warn('Rate limiter config changed. Server restart required for changes to take effect.');
                    }
                }
            }, DEBOUNCE_MS);
        }
    } catch (e) {
        error(`Failed to watch config file: ${e.message}`);
    }
}

module.exports = {
    loadConfig,
    watchConfig,
    getAddresses: () => config.addresses || {},
    getSecrets: () => config.secrets || {},
    getLimits: () => config.limits || {},
};
