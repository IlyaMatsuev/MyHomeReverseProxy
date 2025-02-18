const express = require('express');

const PORT = process.env.PORT || 80;
const ENV = process.env.NODE_ENV || 'dev';

const addresses = require(`../config/addresses.${ENV}.json`) || {};

const server = express();

server.use((request, response) => {
    const host = request.get('host');
    console.log(`Received request on ${host}`);

    const targetAddress = addresses[host];
    console.log(`Resolved address: ${targetAddress}`);
    if (targetAddress) {
        response.redirect(301, `${targetAddress}${request.url}`);
    } else {
        response.status(404).json({ message: 'Not Found' });
    }
});

server.listen(PORT, () => console.info(`Listening on port ${PORT}`));
