const express = require('express');
const app = express();
const musicMd = require('music-metadata');
const WebSocket = require('ws');

app.get('/', function (req, res) {
    res.send('Hello World!')
});

app.listen(3000, function () {
    console.log('Example app listening on port 3000!')
});

app.use(express.static('/home/nabil/Musique/public'));


const wss = new WebSocket.Server({ port: 8082 });

wss.on('connection', function (ws) {
    console.log('one guy is connected !!!');
    ws.on('message', function (message) {
        console.log('received: %s', message);
    });

    ws.send('something');
});