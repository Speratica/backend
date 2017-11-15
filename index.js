const express = require('express');
const bodyParser = require('body-parser');
const csvtoqr = require('./lib/csvtoqr');
const parsescanned = require('./lib/parsescanned');
const app = express();

app.use(express.static('../frontend'));
app.use(bodyParser.json({limit: '2mb'}));

app.use(function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});

app.post('/csvtoqr', (req, res) => {
    if (!req.body.list || !req.body.list.length) {
        res.sendStatus(400);
    } else {
        csvtoqr(req.body.list)
            .then(contents => res.send(JSON.stringify(contents)))
            .catch(e => console.log(e));
    }
});

app.post('/parsescanned', (req, res) => {
    if (!req.body.base64) res.sendStatus(400);
    else parsescanned(Buffer.from(req.body.base64, 'base64'))
        .then(result => {
            res.send(JSON.stringify({
                name: result.split('\n')[0],
                results: result.split('\n').slice(1, -1)
                    .reduce((obj, str) => Object.assign({[str.split(' ')[0]]: str.split(' ')[1]}, obj), {})
            }));
        })
        .catch(e => console.log(e));
});

app.listen(3000, function() {
    console.log('Example app listening on port 3000!');
});
