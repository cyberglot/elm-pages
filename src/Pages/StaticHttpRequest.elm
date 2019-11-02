module Pages.StaticHttpRequest exposing (Error(..), Request(..), errorToString, permanentError, resolve, resolveUrls, toBuildError, urls)

import BuildError exposing (BuildError)
import Dict exposing (Dict)
import Pages.Internal.Secrets exposing (UrlWithSecrets)
import Secrets exposing (Secrets)
import TerminalText as Terminal


type Request value
    = Request ( List UrlWithSecrets, Dict String String -> Result Error (Request value) )
    | Done value


errorToString : Error -> String
errorToString error =
    case error of
        MissingHttpResponse string ->
            string

        DecoderError string ->
            string


type Error
    = MissingHttpResponse String
    | DecoderError String


urls : Request value -> List UrlWithSecrets
urls request =
    case request of
        Request ( urlList, lookupFn ) ->
            urlList

        Done value ->
            []


toBuildError : String -> Error -> BuildError
toBuildError path error =
    { message =
        [ Terminal.text path
        , Terminal.text "\n\n"
        , Terminal.text (errorToString error)
        ]
    }


permanentError : Request value -> Dict String String -> Maybe Error
permanentError request rawResponses =
    case request of
        Request ( urlList, lookupFn ) ->
            case lookupFn rawResponses of
                Ok nextRequest ->
                    permanentError nextRequest rawResponses

                Err error ->
                    case error of
                        MissingHttpResponse _ ->
                            Nothing

                        DecoderError _ ->
                            Just error

        Done value ->
            Nothing


resolve : Request value -> Dict String String -> Result Error value
resolve request rawResponses =
    case request of
        Request ( urlList, lookupFn ) ->
            case lookupFn rawResponses of
                Ok nextRequest ->
                    resolve nextRequest rawResponses

                Err error ->
                    Err error

        Done value ->
            Ok value


resolveUrls : Request value -> Dict String String -> ( Bool, List Pages.Internal.Secrets.UrlWithSecrets )
resolveUrls request rawResponses =
    case request of
        Request ( urlList, lookupFn ) ->
            case lookupFn rawResponses of
                Ok nextRequest ->
                    resolveUrls nextRequest rawResponses
                        |> Tuple.mapSecond ((++) urlList)

                Err error ->
                    ( False
                    , urlList
                    )

        Done value ->
            ( True, [] )
