const express = require('express');
const app = express();
const http = require('http').Server(app);
const io = require('socket.io')(http);
const fs = require('fs-extra');
const path = require('path');
const glob = require('glob');
const mm = require('music-metadata');
var md5 = require('md5');


let musicDir = process.env.MUSIC_DIR || '/home/nabil/Musique';
let isDev = process.argv[2] === "dev";
let serverPort = 8082;

let index = isDev ? fs.readFileSync('static/indexDev.html') : fs.readFileSync('static/indexProd.html');

app.use(express.static(musicDir));

app.use(express.static('artworks'));
app.use(express.static('dist'));

http.listen(serverPort, function () {
    console.log(`App listening on port ${serverPort}`);
    console.log(isDev ? "DEVELOPMENT MODE" : "PRODUCTION MODE");
});


app.get('*', function (req, res) {
    myDebug(req.method + " " + req.originalUrl);
    res.set('Content-Type', 'text/html');
    res.send(index);
});

io.on('connection', function (sock) {
    myDebug(' one guy is connected through the socket!!!');

    glob("**", {cwd: musicDir},function (err, files) {

        let tracksList = [];

        files.filter(filterExtension).forEach(file => {
            tracksList.push(getInfo(file));
        });
        io.emit('tracks',JSON.stringify(tracksList));

        if (err) {
            myDebug(err);
        }
    });


    sock.on('metadataRequest',function (tr) {
        tr = JSON.parse(tr);
        mm.parseFile(musicDir + '/' + (tr.relativePath), {native: true})
            .then(metadata => {
                let augmentedTrack = getMetadata(tr, metadata);
                io.emit('parsedTrack',JSON.stringify(augmentedTrack));
            })
            .catch( err => {
                console.error(err.message);
            });
    });

});



let filterExtension = function (element) {
    let extName = path.extname(element);
    let excluded = element.includes('#');
    return (extName === '.mp3' || extName === '.wav' || extName === '.ogg') && !excluded ;
};

let getInfo = function (file) {
    return {
        relativePath: file,
        filename: path.basename(file)
    };
};

let getMetadata = function (tr, md ) {
    if (md.common) {
        if (md.common.title) {
            tr.title = md.common.title;
        }
        if (md.common.artist) {
            tr.artist = md.common.artist;
        }
        if (md.common.album) {
            tr.album = md.common.album;
        }
        if (md.common.picture) {
            tr.picture = saveArtwork(md.common.picture[0].data);
        }
    }
    return tr;
};



let saveArtwork = function (req) {
    let hash = md5(req);
    let filename = hash + ".jpg";
    fs.ensureDirSync('artworks');
    let files = fs.readdirSync('artworks');
    if (!files.includes(filename)) {
        fs.outputFile(`artworks/${hash}.jpg`, req, 'binary', function (err) {
            if (err) {
                console.log("There was an error writing the image " + filename);
            }
        });
    }
    return filename;
};




let myDebug = function (x) {
    if (isDev) {
        console.log("[LOG] " + new Date().toLocaleString() + " : " + x);
    }
};