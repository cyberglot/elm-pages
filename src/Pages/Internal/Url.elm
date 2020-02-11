module Pages.Internal.Url exposing (CanonicalUrl(..), urlFromValues)

import Maybe exposing (withDefault)
import Url exposing (Protocol(..), Url)


type CanonicalUrl
    = CanonicalUrl String String (Maybe Int) (Maybe String)


emptyUrl =
    { protocol = Https
    , host = ""
    , port_ = Nothing
    , path = ""
    , query = Nothing
    , fragment = Nothing
    }


urlFromValues : CanonicalUrl -> Url
urlFromValues (CanonicalUrl protocol host port_ path) =
    case String.toLower protocol of
        "http" ->
            { emptyUrl
                | protocol = Http
                , host = host
                , port_ = port_
                , path = withDefault "" path
            }

        _ ->
            { emptyUrl
                | host = host
                , port_ = port_
                , path = withDefault "" path
            }
