const express = require('express');
const bodyParser = require('body-parser');
const csvtoqr = require('./lib/csvtoqr');
const app = express();

app.use(express.static('../frontend'));
app.use(bodyParser.json());

app.use(function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});

app.post('/csvtoqr', (req, res) => {
    if(!req.body.list || !req.body.list.length) {
        res.sendStatus(400);
    } else {
        csvtoqr(req.body.list)
            .then(contents => res.send(JSON.stringify(contents)))
            .catch(e => console.log(e));
    }
});

app.post('/parsescanned', (req, res) => {
    res.send(200);
});

app.listen(3000, function () {
    console.log('Example app listening on port 3000!');
});
