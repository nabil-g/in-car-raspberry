const express = require('express');
const app = express();
const mm = require('music-metadata');
const io = require('socket.io')(8090);
const fs = require('fs');
const path = require('path');

let musicDir = process.env.MUSIC_DIR || '/home/nabil/Musique';

let serverPort = 8082;

app.use(express.static('static'));

app.use(express.static('dist'));

app.use(express.static(musicDir));

app.listen(serverPort, function () {
    console.log(`App listening on port ${serverPort}!`);
});

app.get('/', function (req, res) {
    res.sendFile('index.html');
});


io.on('connection', function (sock) {
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
                        io.emit('tracks',JSON.stringify(tracksList));
                        // console.log(tracksList);
                    }
                })
                .catch( err => {
                    console.error(err.message);
                });
        });
        // io.emit('tracks',JSON.stringify(tracksList));
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