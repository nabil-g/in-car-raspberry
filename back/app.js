const express = require('express');
const app = express();
const mm = require('music-metadata');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

let musicDir = '/home/nabil/Musique/public/';
let workMusicDir = '/home/nabil/';

const wss = new WebSocket.Server({ port: 8082 });

app.listen(3000, function () {
    console.log('Example app listening on port 3000!')
});


app.use(express.static(workMusicDir));

wss.on('connection', function (ws) {
    console.log('----------> one guy is connected !!!');
    ws.on('message', function (message) {
        console.log('------> received: %s', message);
    });

    // '/home/nabil/Musique/public/4 Hero & Carina Anderson - Morning Child (Album Version) .mp3'

        fs.readdir(workMusicDir, function (err, files)  {

            let tracksList = [];

            files.filter(filterExtension).forEach(file => {

                mm.parseFile(workMusicDir + file, {native: true})
                    .then(function (metadata) {
                        var x = getInfo(file, metadata);
                        console.log(x);
                        tracksList.push(x);
                    })
                    .catch(function (err) {
                        console.error(err.message);
                    });
            });

            ws.send(JSON.stringify(tracksList));

            if (err) {
                console.log(err);
            }
        });


});

let filterExtension = function (element) {
    let extName = path.extname(element);
    return extName === '.mp3';
};


let getInfo = function (file, md ) {
    md.common.filename = file;
    return md.common;
};

// let readWriteFile = function (req) {
//     let data =  new Buffer(req);
//     fs.writeFile('fileName.jpg', data, 'binary', function (err) {
//         if (err) {
//             console.log("There was an error writing the image")
//         }
//         else {
//             console.log("The sheel file was written")
//         }
//     });
// };