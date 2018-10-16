const express = require('express');
const app = express();
const mm = require('music-metadata');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

let musicDir = process.env.MUSIC_DIR || '/home/nabil/Musique';

let serverPort = 3000;

const wss = new WebSocket.Server({ port: 8090 });

app.listen(serverPort, function () {
    console.log('Example app listening on port 3000!')
});


app.use(express.static(musicDir));

wss.on('connection', function (ws) {

    console.log('----------> one guy is connected !!!');

    fs.readdir(musicDir, function (err, files)  {
        let tracksList = [];

        files.filter(filterExtension).forEach(file => {
            tracksList.push(file);
        });
        ws.send(JSON.stringify(tracksList));
        // console.log(tracksList);

        if (err) {
            console.log(err);
        }
    });
});



let filterExtension = function (element) {
    let extName = path.extname(element);
    let excluded = element.startsWith('#');
    return (extName === '.mp3' || extName === '.wav' || extName === '.ogg') && !excluded ;
};


