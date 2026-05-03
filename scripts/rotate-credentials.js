const { scryptSync, randomBytes } = require('crypto');
const path = require('path');
const fs = require('fs');

main();

function main() {
    const [username, password, secret] = process.argv.slice(2);

    if (!username || !password || !secret) {
        console.error('Usage: node scripts/rotate-credentials.js <username> <password> <secret>');
        process.exit(1);
    }

    const prodConfigPath = getConfigFilePath('prod');

    if (!fs.existsSync(prodConfigPath)) {
        const devConfigPath = getConfigFilePath('dev');
        fs.copyFileSync(devConfigPath, prodConfigPath);
        console.log(`Created prod config file: ${prodConfigPath}`);
    }

    // Update text content instead of parsing to keep the comments in the yaml file
    let contents = fs.readFileSync(prodConfigPath, 'utf8');
    contents = replaceSecret(contents, 'username', username);
    contents = replaceSecret(contents, 'passwordHash', hashCredential(password));
    contents = replaceSecret(contents, 'secretHash', hashCredential(secret));

    fs.writeFileSync(prodConfigPath, contents);

    console.log(`Updated credentials in ${prodConfigPath}`);
}

function hashCredential(credential) {
    const salt = randomBytes(16).toString('hex');
    const hash = scryptSync(credential, salt, 64).toString('hex');
    return hash + '.' + salt;
}

function replaceSecret(source, key, value) {
    const re = new RegExp(`^(\\s*${key}:\\s*).*$`, 'm');
    if (!re.test(source)) {
        throw new Error(`Could not find "${key}" entry under secrets in ${configPath}`);
    }
    return source.replace(re, `$1"${value}"`);
}

function getConfigFilePath(env) {
    return path.resolve(__dirname, `../config/config.${env}.yaml`);
}
