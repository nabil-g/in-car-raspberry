const express = require('express');
const app = express();
const http = require('http').Server(app);
const io = require('socket.io')(http);
const fs = require('fs');
const path = require('path');
const glob = require('glob');

let musicDir = process.env.MUSIC_DIR || '/home/nabil/Musique';
let isDev = process.argv[2] === "dev";
let serverPort = 8082;

let index = isDev ? fs.readFileSync('static/indexDev.html') : fs.readFileSync('static/indexProd.html');

app.use(express.static(musicDir));

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


let myDebug = function (x) {
    if (isDev) {
        console.log("[LOG] " + new Date().toLocaleString() + " : " + x);
    }
};