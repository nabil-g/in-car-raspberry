module Utils exposing (dateToFrench, formatSingleDigit)

import Time exposing (Month(..), Posix, Weekday(..), Zone)


dateToFrench : Zone -> Posix -> String
dateToFrench zone ct =
    (weekDayToFrench <| Time.toWeekday zone ct) ++ " " ++ (String.fromInt <| Time.toDay zone ct) ++ " " ++ (monthToFrench <| Time.toMonth zone ct) ++ " " ++ (String.fromInt <| Time.toYear zone ct)


formatSingleDigit : Int -> String
formatSingleDigit num =
    if num >= 0 && num < 10 then
        "0" ++ String.fromInt num

    else
        String.fromInt num


monthToFrench : Month -> String
monthToFrench num =
    case num of
        Jan ->
            "janv."

        Feb ->
            "fev."

        Mar ->
            "mars"

        Apr ->
            "avr."

        May ->
            "mai"

        Jun ->
            "juin"

        Jul ->
            "juil."

        Aug ->
            "août"

        Sep ->
            "sept."

        Oct ->
            "oct."

        Nov ->
            "nov."

        _ ->
            "déc."


weekDayToFrench : Weekday -> String
weekDayToFrench d =
    case d of
        Mon ->
            "Lun."

        Tue ->
            "Mar."

        Wed ->
            "Mer."

        Thu ->
            "Jeu."

        Fri ->
            "Ven."

        Sat ->
            "Sam."

        Sun ->
            "Dim."
