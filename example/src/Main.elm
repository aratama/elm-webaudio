module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import WebAudio



---- MODEL ----


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



---- UPDATE ----


type Msg
    = AssetLoaded (List String)
    | Tick Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AssetLoaded assets ->
            ( model, Cmd.none )

        Tick audioTIme ->
            ( model, Cmd.none )



---- VIEW ----


node : Int -> Float -> WebAudio.AudioNode
node nodeNumber pos =
    { id = WebAudio.AudioNodeId ("oscillator-" ++ String.fromInt nodeNumber ++ "-" ++ String.fromFloat pos)
    , output = WebAudio.Output (WebAudio.AudioNodeId "gain")
    , properties =
        WebAudio.Oscillator
            { frequency = WebAudio.Constant (440 * (2 ^ (toFloat nodeNumber / 12)))
            , startTime = WebAudio.AudioTime pos
            , stopTime = WebAudio.AudioTime (pos + 1)
            }
    }


graph : WebAudio.AudioGraph
graph =
    [ { id = WebAudio.AudioNodeId "gain"
      , output = WebAudio.output
      , properties = WebAudio.Gain { gain = WebAudio.Constant 0.01 }
      }
    , node 0 1
    , node 2 2
    , node 4 3
    , node 5 4
    , node 4 5
    , node 2 6
    , node 0 7
    ]


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , WebAudio.toHtml
            { graph =
                graph
            , assets = []
            , onAssetLoaded = AssetLoaded
            , onTick = Tick
            }
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
