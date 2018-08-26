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


app.use(express.static(musicDir));

wss.on('connection', function (ws) {
    console.log('----------> one guy is connected !!!');
    ws.on('message', function (message) {
        console.log('------> received: %s', message);
    });

    // '/home/nabil/Musique/public/4 Hero & Carina Anderson - Morning Child (Album Version) .mp3'

        fs.readdir(musicDir, function (err, files)  {

            let tracksList = [];

            files.filter(filterExtension).forEach((file, index, arr) => {

                mm.parseFile(musicDir + file, {native: true})
                    .then(metadata => {
                        let x = getInfo(file, metadata);
                        tracksList.push(x);
                        if (tracksList.length === arr.length) {
                            ws.send(JSON.stringify(tracksList));
                        }
                    })
                    .catch( err => {
                        console.error(err.message);
                    });
            });



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
    // if (md.common.picture) {
    //     readWriteFile(md.common.picture[0].data);
    // }
    delete md.common.picture;
    return md.common;
};

// let readWriteFile = function (req) {
//     let data =  new Buffer(req);
//     console.log(data.toString('base64'));
//     fs.writeFile('fileName.jpg', data, 'binary', function (err) {
//         if (err) {
//             console.log("There was an error writing the image")
//         }
//         else {
//             console.log("The sheel file was written")
//         }
//     });
// };