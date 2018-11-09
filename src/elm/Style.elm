module Style exposing (blackColor, blueColor, greenColor, redColor, whiteColor, setPlayerPageStyle)

import Element exposing (Color, rgb)
import Html as H


blackColor : Color
blackColor =
    rgb 0 0 0


whiteColor : Color
whiteColor =
    rgb 255 255 255


redColor : Color
redColor =
    rgb 255 0 0


greenColor : Color
greenColor =
    rgb 0 255 0


blueColor : Color
blueColor =
    rgb 0 0 255


setPlayerPageStyle : H.Html msg
setPlayerPageStyle =
    H.node "style" [] [ H.text "#xxx{background-color:rgba(0,0,0,.4);}#xxx:before{content: '';background: url(497090093d07e907f2255c503c50905d.jpg) no-repeat fixed;background-size: cover;-webkit-filter: blur(5px);-moz-filter: blur(5px);-ms-filter: blur(5px);-o-filter: blur(5px);filter: blur(5px);position: absolute;top:0;bottom: 0;left: 0;right: 0;z-index: -1;}" ]
