const http = require('http');

const METHODS_WITH_BODY = ['POST', 'PUT', 'PATCH'];

/**
 * Sends HTTP request
 * @param options {{
 *     hostname: string,
 *     port: number,
 *     uri: string,
 *     method: string,
 *     headers: Record<string, string>,
 *     data: any
 * }} Configuration for the HTTP request
 * @return {Promise<IncomingMessage & { data: string }>}
 */
exports.httpRequest = function (options) {
    const requestData = getNormalizedData(options);
    const requestOptions = {
        hostname: options.hostname,
        port: options.port,
        path: options.uri,
        method: options.method,
        headers: getNormalizedHeaders(options.method, options.headers, requestData),
    };

    return new Promise((resolve, reject) => {
        const request = http.request(requestOptions, response => {
            let data = '';
            response.on('data', chunk => data += chunk);
            response.on('end', () => resolve({ ...response, headers: response.headers, data }));
        });
        request.on('error', error => reject(error));

        if (requestData && METHODS_WITH_BODY.includes(options.method)) {
            request.write(requestData);
        }
        request.end();
    });
};

function getNormalizedData(options) {
    const data = typeof options.data === 'string' ? options.data : JSON.stringify(options.data);
    return data === '{}' ? undefined : data;
}

function getNormalizedHeaders(method, headers, data) {
    delete headers['Content-Length'];
    delete headers['content-length'];
    if (data && METHODS_WITH_BODY.includes(method)) {
        headers['Content-Length'] = Buffer.byteLength(data);
    }
    return headers;
}
