const { spawn } = require('child_process');
const { resolve: resolvePath } = require('path');

/**
 * Parse image input
 *
 * @param {Buffer} pic Buffer containing the image content
 * @returns {Promise} promise containing the parsed results
 */
const parsescanned = pic => {
    return new Promise((resolve, reject) => {
        const proc = spawn('fish', [resolvePath(__dirname, '../scripts/parsescan.sh')]);

        let stdout = '';
        proc.stdout.on('data', data => stdout += data.toString());
        proc.stdout.on('end', () => resolve(stdout));

        proc.on('close', code => code ? reject(code) : code);

        proc.stdin.write(pic);
        proc.stdin.end();
    });
};
module.exports = parsescanned;
