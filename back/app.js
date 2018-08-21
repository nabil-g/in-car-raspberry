const express = require('express');
const app = express();
const mm = require('music-metadata');
const WebSocket = require('ws');
const fs = require('fs');

app.get('/', function (req, res) {
    res.send('Hello World!')
});

app.listen(3000, function () {
    console.log('Example app listening on port 3000!')
});

let musicDir = '/home/nabil/Musique/public/';

app.use(express.static(musicDir));


const wss = new WebSocket.Server({ port: 8082 });

wss.on('connection', function (ws) {
    console.log('one guy is connected !!!');
    ws.on('message', function (message) {
        console.log('received: %s', message);
    });

    // mm.parseFile('/home/nabil/Musique/public/4 Hero & Carina Anderson - Morning Child (Album Version) .mp3', {native: true})
    mm.parseFile('/home/nabil/Musique/public/4hero.wav', {native: true})
        .then(function (metadata) {
            let songMd = getInfo("4hero.wav", metadata);
            console.log(songMd);
            ws.send(JSON.stringify(songMd));
        })
        .catch(function (err) {
            console.error(err.message);});

});


fs.readdir(musicDir, function (err, files)  {
    files.forEach(file => {
        mm.parseFile(musicDir + file, {native: true})
            .then(function (metadata) {
                console.log(file);
            })
            .catch(function (err) {
                console.error(err.message);});
    });
    if (err) {
        console.log(err);
    }
});

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

let getInfo = function (filen, md ) {
    return {
      filename : filen,
        common: md.common,
    };
}