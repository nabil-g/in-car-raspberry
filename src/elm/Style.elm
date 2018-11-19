module Style exposing (blackColor, blueColor, greenColor, greyColor, redColor, setPlayerPageStyle, whiteColor)

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


greyColor : Color
greyColor =
    Element.rgb255 144 144 144


setPlayerPageStyle : Maybe String -> H.Html msg
setPlayerPageStyle s =
    let
        ( pic, color ) =
            case s of
                Just picture ->
                    ( picture, 0.4 )

                Nothing ->
                    ( "", 1 )
    in
    H.node "style" [] [ H.text ("#xxx{transition:all 2s ease;background-color:rgba(0,0,0," ++ String.fromFloat color ++ ");}#xxx:before{content: '';background: url(" ++ pic ++ ") no-repeat fixed;background-size: cover;-webkit-filter: blur(30px);filter: blur(30px);position: absolute;top:0;bottom: 0;left: 0;right: 0;z-index: -1;}") ]
