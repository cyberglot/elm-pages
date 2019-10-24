module StaticHttp exposing (..)

import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Pages.StaticHttpRequest exposing (Request(..))


type alias Request value =
    Pages.StaticHttpRequest.Request value


type alias RequestExample model rendered msg pathKey =
    Request
        { view :
            model
            -> rendered
            ->
                { title : String
                , body : Html msg
                }
        , head : List (Head.Tag pathKey)
        }


map : (a -> b) -> Request a -> Request b
map fn (Request ( urls, lookup )) =
    Request
        ( urls
        , \rawResponsesDict ->
            rawResponsesDict
                |> lookup
                |> Result.map fn
        )


map2 : (a -> b -> c) -> Request a -> Request b -> Request c
map2 fn (Request ( urlsA, lookupA )) (Request ( urlsB, lookupB )) =
    Request
        ( urlsA ++ urlsB
        , \dict -> Result.map2 fn (lookupA dict) (lookupB dict)
        )


succeed : a -> Request a
succeed value =
    Request
        ( []
        , \rawResponseDict -> Ok value
        )


jsonRequest : String -> Decoder a -> Request a
jsonRequest url decoder =
    Request
        ( [ url ]
        , \rawResponseDict ->
            rawResponseDict
                |> Dict.get url
                |> (\maybeResponse ->
                        case maybeResponse of
                            Just rawResponse ->
                                Ok rawResponse

                            Nothing ->
                                Err <| "Couldn't find response for url `" ++ url ++ "`"
                   )
                |> Result.andThen
                    (\rawResponse ->
                        rawResponse
                            |> Decode.decodeString decoder
                            |> Result.mapError Decode.errorToString
                    )
        )


twoRequestsExample : Request String
twoRequestsExample =
    map2
        view
        (jsonRequest (repoApiUrl "elm-pages") (Decode.field "stargazer_count" Decode.int))
        (jsonRequest (repoApiUrl "elm-pages-starter") (Decode.field "stargazer_count" Decode.int))


view stargazersNpm stargazersStarter =
    "elm-pages: "
        ++ String.fromInt stargazersNpm
        ++ "elm-pages-starter: "
        ++ String.fromInt stargazersStarter



--        (succeed 123)


repoApiUrl repoName =
    "https://api.github.com/repos/dillonkearns/" ++ repoName
