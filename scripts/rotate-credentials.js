const { scryptSync, randomBytes } = require('crypto');
const { resolve } = require('path');
const fs = require('fs');

const [username, password, secret] = process.argv.slice(2);

if (!username || !password || !secret) {
    console.error('Usage: node scripts/rotate-credentials.js <username> <password> <secret>');
    process.exit(1);
}

function hashCredential(credential) {
    const salt = randomBytes(16).toString('hex');
    const hash = scryptSync(credential, salt, 64).toString('hex');
    return hash + '.' + salt;
}

const secretsPath = resolve(__dirname, '../config/secrets.prod.json');
const existing = JSON.parse(fs.readFileSync(secretsPath, 'utf8'));
const updated = {
    ...existing,
    username,
    password: hashCredential(password),
    secret: hashCredential(secret),
};

fs.writeFileSync(secretsPath, JSON.stringify(updated, null, 2) + '\n');
console.log('Credentials updated in ' + secretsPath);
