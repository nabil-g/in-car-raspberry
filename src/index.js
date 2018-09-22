import { Elm }  from './elm/Main.elm';
import io from 'socket.io-client';
const socket = io();

let app = Elm.Main.init({});

let audioPlayer = new Audio();

window.ap = audioPlayer;

// events

socket.on('tracks', (msg) => {
    app.ports.incomingSocketMsg.send(msg);
});

audioPlayer.onended = function() {
    console.log("The audio has ended");
    app.ports.playerEvent.send({
        event: "ended",
        track: audioPlayer.src,
    });
};

audioPlayer.onpause = function() {
    console.log("The audio has been paused");
    app.ports.playerEvent.send({
        event: "paused",
        track: audioPlayer.src,
    });
};

audioPlayer.onplay = function() {
    console.log("The audio is playing");
    app.ports.playerEvent.send({
        event: "playing",
        track: audioPlayer.src,
    });
};

audioPlayer.ondurationchange = function () {
    console.log("can play");
    app.ports.playerEvent.send({
        event: "loaded",
        track: audioPlayer.src,
    });
};


audioPlayer.onerror = function () {
    console.log("error");
    console.log(audioPlayer.error.code);
    app.ports.playerEvent.send({
        event: "error",
        track: audioPlayer.src,
        error: audioPlayer.error.code,
    });
};


// actionners

app.ports.setTrack.subscribe(function (tr) {
    // console.log(tr);
    audioPlayer.src = tr;
    console.log(audioPlayer.src);
});

app.ports.pause.subscribe(function () {
    audioPlayer.pause();
});

app.ports.play.subscribe(function () {
    audioPlayer.play();
});
