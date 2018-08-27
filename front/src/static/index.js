var Elm = require( '../elm/Main' );

let app = Elm.Main.fullscreen();

let audioPlayer = new Audio();


app.ports.subscribe(function (x) {
    console.log(x);
});