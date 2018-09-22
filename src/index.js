import { Elm }  from './elm/Main.elm';
import io from 'socket.io-client';
import { parse } from 'id3-parser';
import { fetchFileAsBuffer } from 'id3-parser/lib/universal/helpers';

const socket = io();

let app = Elm.Main.init({});

let audioPlayer = new Audio();

window.ap = audioPlayer;

// events

socket.on('tracks', (msg) => {
    app.ports.incomingSocketMsg.send(msg);
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
    // myDebug(tr);
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
    fetchFileAsBuffer(tr.relativePath).then(parse).then(tag => {
        myDebug(tag);
        if (tag.title) {
            tr.title = tag.title;
        }
        if (tag.artist) {
            tr.artist = tag.artist;
        }
        if (tag.album) {
            tr.album = tag.album;
        }
        if (tag.image && tag.image.data) {
            tr.picture = btoa(String.fromCharCode.apply(null,tag.image.data));
        }
        app.ports.enhancedTrack.send(tr);
    });
});




let myDebug = function (x) {
    if (isDev) {
        console.log(x);
    }
};