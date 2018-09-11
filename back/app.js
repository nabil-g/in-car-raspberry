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

        files.filter(filterExtension).forEach((file, index, arr) => {

            // tracksList.push(file);
            mm.parseFile(musicDir + '/' + file, {native: true})
                .then(metadata => {
                    let augmentedTrack = getInfo(file, metadata);
                    tracksList.push(augmentedTrack);
                    if (tracksList.length === arr.length) {
                        ws.send(JSON.stringify(tracksList));
                        // console.log(tracksList);
                    }
                })
                .catch( err => {
                    console.error(err.message);
                });
        });
        // ws.send(JSON.stringify(tracksList));
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


let getInfo = function (file, md ) {
    md.common.relativePath = file;
    md.common.filename = path.basename(file);
    if (md.common.picture) {
       md.common.picture = artworkToBase64(md.common.picture[0].data);
    }
    return md.common;
};

let artworkToBase64 = function (req) {
    let data =  new Buffer(req);
    return data.toString('base64');
};