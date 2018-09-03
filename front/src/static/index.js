let Elm = require( '../elm/Main' );

// let app = Elm.Main.embed(document.getElementById('main'));
let app = Elm.Main.fullscreen();

let audioPlayer = new Audio();

window.ap = audioPlayer;

// events

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



audioPlayer.oncanplaythrough = function () {
    console.log("can play");
    app.ports.playerEvent.send({
        event: "loaded",
        track: audioPlayer.src,
    });
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