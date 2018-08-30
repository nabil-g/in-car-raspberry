let Elm = require( '../elm/Main' );

// let app = Elm.Main.embed(document.getElementById('main'));
let app = Elm.Main.fullscreen();

let audioPlayer = new Audio();

window.ap = audioPlayer;

// events

audioPlayer.onended = function() {
    console.log("The audio has ended");
    app.ports.playerEvent.send("ended");
};

audioPlayer.onpause = function() {
    console.log("The audio has been paused");
    app.ports.playerEvent.send("paused");
};

audioPlayer.onplay = function() {
    console.log("The audio is playing");
    app.ports.playerEvent.send("playing");
};
audioPlayer.canplay = function () {

    audioPlayer.play();
};
audioPlayer.onloadstart = function () {
    app.ports.playerEvent.send("loading");
};

// actionners

app.ports.playTrack.subscribe(function (tr) {
    // console.log(tr);
    audioPlayer.src = 'http://localhost:3000/' + tr;
    console.log(audioPlayer.src);
});

app.ports.pause.subscribe(function () {
    audioPlayer.pause();
});

app.ports.play.subscribe(function () {
    audioPlayer.play();
});