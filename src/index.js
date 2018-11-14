import { Elm }  from './elm/Main.elm';
import io from 'socket.io-client';
import style from './assets/styles/main.scss';

const socket = io();

let app = Elm.Main.init({ flags:window.innerHeight });

let audioPlayer = new Audio();

window.ap = audioPlayer;

// events

socket.on('tracks', (msg) => {
    app.ports.incomingSocketMsg.send(msg);
});

socket.on('parsedTrack', (tr) => {
    app.ports.enhancedTrack.send(JSON.parse(tr));
});

audioPlayer.onended = function() {
    myDebug("The audio has ended");
    app.ports.playerEvent.send({
        event: "ended",
        track: audioPlayer.src,
    });
};

audioPlayer.onpause = function() {
    myDebug("The audio has been paused");
    app.ports.playerEvent.send({
        event: "paused",
        track: audioPlayer.src,
    });
};

audioPlayer.onplay = function() {
    myDebug("The audio is playing");
    app.ports.playerEvent.send({
        event: "playing",
        track: audioPlayer.src,
    });
};

audioPlayer.ondurationchange = function () {
    myDebug("can play");
    app.ports.playerEvent.send({
        event: "loaded",
        track: audioPlayer.src,
    });
};


audioPlayer.onerror = function () {
    myDebug("error");
    myDebug(audioPlayer.error.code);
    app.ports.playerEvent.send({
        event: "error",
        track: audioPlayer.src,
        error: audioPlayer.error.code,
    });
};


// actionners

app.ports.setTrack.subscribe(function (tr) {
    audioPlayer.src = tr;
    myDebug(audioPlayer.src);
});

app.ports.pause.subscribe(function () {
    audioPlayer.pause();
});

app.ports.play.subscribe(function () {
    audioPlayer.play();
});


app.ports.getMetadata.subscribe(function (tr) {
    socket.emit('metadataRequest', JSON.stringify(tr));
});

app.ports.scrollToTrack.subscribe(function (s) {
    console.log(s);
    let tracksList = document.getElementById('tracksList');
    tracksList.scrollTo(0,document.getElementById(s).scrollTop);
});



let myDebug = function (x) {
    if (isDev) {
        console.log(x);
    }
};