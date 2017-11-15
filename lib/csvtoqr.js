const { spawn } = require('child_process');
const { readFile, unlink } = require('fs');
const { resolve } = require('path');
const { promisify } = require('util');

/**
 * Convert an array of csv lines to an array of qr code matices
 *
 * @param {String[]} csv Array of comma-separated values
 * @returns {Promise} Array of PNG pictures, base64 encoded
 */
const csvtoqr = csv => {
    return new Promise((res, reject) => {
        const proc = spawn('fish', [resolve(__dirname, '../scripts/qr.sh')]);

        let stdout = '';
        proc.stdout.on('data', data => stdout += data.toString());
        proc.stdout.on('end', () => res(stdout.split('\n').slice(0, -1)));

        proc.on('close', code => code ? reject(code) : code);

        proc.stdin.write(csv.join('\n'));
        proc.stdin.end();
    }).then(paths => Promise.all(paths.map(path => promisify(readFile)(path).then(content => ({path, content})))))
        .then(contents => {
            contents.forEach(({path}) => unlink(path, (err) => console.log(path, err ? 'not deleted' : 'deleted sucessfully')));
            return contents.map(({content}) => content.toString('base64'));
        });
};
module.exports = csvtoqr;
