const express = require('express');
const app = express();
const mm = require('music-metadata');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

let workMusicDir = '/home/nabil/';
let homeMusicDir = '/home/nabil/Musique/public/';

let musicDir = homeMusicDir;



const wss = new WebSocket.Server({ port: 8082 });

app.listen(3000, function () {
    console.log('Example app listening on port 3000!')
});


app.use(express.static(musicDir));

wss.on('connection', function (ws) {

    console.log('----------> one guy is connected !!!');

    // ws.on('message', function (message) {
    //     console.log('------> received: %s', message);
    // });


        fs.readdir(musicDir, function (err, files)  {

            let tracksList = [];

            files.filter(filterExtension).forEach((file, index, arr) => {
                tracksList.push(file);
                // mm.parseFile(musicDir + file, {native: true})
                //     .then(metadata => {
                //         let x = getInfo(file, metadata);
                //         tracksList.push(x);
                //         if (tracksList.length === arr.length) {
                //             ws.send(JSON.stringify(tracksList));
                //         }
                //     })
                //     .catch( err => {
                //         console.error(err.message);
                //     });
            });
            ws.send(JSON.stringify(tracksList));



            if (err) {
                console.log(err);
            }
        });


});

let filterExtension = function (element) {
    let extName = path.extname(element);
    return extName === '.mp3' || extName === '.wav' || extName === '.ogg' ;
};


let getInfo = function (file, md ) {
    md.common.filename = file;
    // if (md.common.picture) {
    //    md.common.picture = artworkToBase64(md.common.picture[0].data);
    // }
    delete md.common.picture;
    return md.common;
};

let artworkToBase64 = function (req) {
    let data =  new Buffer(req);
    return data.toString('base64');
};