const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { httpRequest } = require('./request');

const PORT = process.env.PORT || 80;
const ENV = process.env.NODE_ENV || 'dev';

const addresses = require(`../config/addresses.${ENV}.json`) || {};

const server = express();

server.use(cors());
server.use(bodyParser.json());

server.use((request, response) => {
    const host = request.get('host');
    console.log(`Received request on ${host}`);

    const targetAddress = addresses[host];
    if (!targetAddress) {
        console.log(`Could not resolve host: ${host}`);
        response.status(404).json({ message: 'Not Found' });
        return;
    }
    console.log(`Resolved address: ${targetAddress.hostname}:${targetAddress.port}${request.url}`);

    const options = {
        hostname: targetAddress.hostname,
        port: targetAddress.port,
        uri: request.url,
        method: request.method,
        headers: request.headers,
        data: request.body,
    };

    httpRequest(options)
        .then(res => response.set(res.headers).status(res.statusCode).end(res.data))
        .catch(error => {
            console.error(`Error: ${error}`);
            console.error(`Stack Trace: ${error.stack}`);
            response.status(500).json({ message: error.message });
        });
});

server.listen(PORT, () => console.info(`Listening on port ${PORT}`));
