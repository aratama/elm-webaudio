module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import WebAudio



---- MODEL ----


type alias Model =
    { playing : Bool }


init : ( Model, Cmd Msg )
init =
    ( { playing = False }, Cmd.none )



---- UPDATE ----


type Msg
    = AssetLoaded (List String)
    | Tick Float
    | Play
    | Stop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AssetLoaded assets ->
            ( model, Cmd.none )

        Tick audioTIme ->
            ( model, Cmd.none )

        Play ->
            ( { model | playing = True }, Cmd.none )

        Stop ->
            ( { model | playing = False }, Cmd.none )



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


kaeru : WebAudio.AudioGraph
kaeru =
    [ { id = WebAudio.AudioNodeId "gain"
      , output = WebAudio.output
      , properties = WebAudio.Gain { gain = WebAudio.Constant 0.05 }
      }
    , node 0 1
    , node 2 2
    , node 4 3
    , node 5 4
    , node 4 5
    , node 2 6
    , node 0 7
    ]


graph : WebAudio.AudioGraph
graph =
    [ { id = WebAudio.AudioNodeId "buffersource"
      , output = WebAudio.output
      , properties =
            WebAudio.BufferSource
                { buffer = WebAudio.AudioBufferUrl "New_Place_of_Work.mp3"
                , detune = 0
                , startTime = WebAudio.AudioTime 1
                , stopTime = Nothing
                }
      }
    ]


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , if model.playing then
            button [ onClick Stop ] [ text "Stop Music" ]

          else
            button [ onClick Play ] [ text "Play Music" ]
        , WebAudio.toHtml
            { graph =
                List.concat
                    [ kaeru
                    , if model.playing then
                        graph

                      else
                        []
                    ]
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
