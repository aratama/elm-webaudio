module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import WebAudio



---- MODEL ----


type alias Model =
    { now : Float
    , kaeru : Maybe Float
    , playing : Maybe Float
    }


init : ( Model, Cmd Msg )
init =
    ( { now = 0
      , kaeru = Nothing
      , playing = Nothing
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = AssetLoaded (List String)
    | Tick Float
    | PlayKaeru
    | StopKaeru
    | Play
    | Stop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AssetLoaded assets ->
            ( model, Cmd.none )

        Tick audioTIme ->
            ( { model | now = audioTIme }, Cmd.none )

        PlayKaeru ->
            ( { model | kaeru = Just model.now }, Cmd.none )

        StopKaeru ->
            ( { model | kaeru = Nothing }, Cmd.none )

        Play ->
            ( { model | playing = Just model.now }, Cmd.none )

        Stop ->
            ( { model | playing = Nothing }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "elm-webaudio Example" ]
        , h2 [] [ text "Oscillator Node" ]
        , case model.kaeru of
            Nothing ->
                button [ onClick PlayKaeru ] [ text "Play Music" ]

            Just _ ->
                button [ onClick StopKaeru ] [ text "Stop Music" ]
        , h2 [] [ text "BufferSource Node" ]
        , case model.playing of
            Nothing ->
                button [ onClick Play ] [ text "Play Music" ]

            Just _ ->
                button [ onClick Stop ] [ text "Stop Music" ]
        , WebAudio.toHtml
            { graph =
                List.concat
                    [ case model.kaeru of
                        Nothing ->
                            []

                        Just start ->
                            let
                                node : Int -> Float -> WebAudio.AudioNodeProps
                                node nodeNumber pos =
                                    WebAudio.Oscillator
                                        { frequency = WebAudio.Constant (440 * (2 ^ (toFloat nodeNumber / 12)))
                                        , startTime = WebAudio.AudioTime (start + pos)
                                        , stopTime = WebAudio.AudioTime (start + pos + 1)
                                        }
                            in
                            WebAudio.parallel
                                { id = WebAudio.AudioNodeId "gain"
                                , output = WebAudio.output
                                , properties = WebAudio.Gain { gain = WebAudio.Constant 0.05 }
                                }
                                [ node 0 0
                                , node 2 1
                                , node 4 2
                                , node 5 3
                                , node 4 4
                                , node 2 5
                                , node 0 6
                                ]
                    , case model.playing of
                        Nothing ->
                            []

                        Just start ->
                            WebAudio.serial "buffersource-test"
                                WebAudio.output
                                (WebAudio.Gain { gain = WebAudio.Constant 1 })
                                [ WebAudio.BufferSource
                                    { buffer = WebAudio.AudioBufferUrl "New_Place_of_Work.mp3"
                                    , detune = 0
                                    , startTime = WebAudio.AudioTime start
                                    , stopTime = Nothing
                                    }
                                ]
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
