module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, text)
import Html.Attributes exposing (class, src)
import Html.Events exposing (onClick)
import WebAudio



---- MODEL ----


type alias Model =
    { now : Float
    , ex1 : Maybe Float
    , ex1Type : WebAudio.OscillatorType
    , ex2 : Maybe Float
    , ex3 : Maybe Float
    , ex4 : Maybe Float
    }


init : ( Model, Cmd Msg )
init =
    ( { now = 0
      , ex1 = Nothing
      , ex1Type = WebAudio.Sine
      , ex2 = Nothing
      , ex3 = Nothing
      , ex4 = Nothing
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = AssetLoaded (List WebAudio.Url)
    | Tick WebAudio.Time
    | PlayEx1
    | StopEx1
    | SelectType WebAudio.OscillatorType
    | PlayEx2
    | StopEx2
    | PlayEx3
    | StopEx3
    | PlayEx4
    | StopEx4


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AssetLoaded assets ->
            ( model, Cmd.none )

        Tick (WebAudio.Time audioTIme) ->
            ( { model | now = audioTIme }, Cmd.none )

        PlayEx1 ->
            ( { model | ex1 = Just model.now }, Cmd.none )

        StopEx1 ->
            ( { model | ex1 = Nothing }, Cmd.none )

        SelectType t ->
            ( { model | ex1Type = t }, Cmd.none )

        PlayEx2 ->
            ( { model | ex2 = Just model.now }, Cmd.none )

        StopEx2 ->
            ( { model | ex2 = Nothing }, Cmd.none )

        PlayEx3 ->
            ( { model | ex3 = Just model.now }, Cmd.none )

        StopEx3 ->
            ( { model | ex3 = Nothing }, Cmd.none )

        PlayEx4 ->
            ( { model | ex4 = Just model.now }, Cmd.none )

        StopEx4 ->
            ( { model | ex4 = Nothing }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "elm-webaudio Examples" ]
        , h2 [] [ text "Example 1: Oscillator Node" ]
        , case model.ex1 of
            Nothing ->
                button [ onClick PlayEx1 ] [ text "Play" ]

            Just _ ->
                button [ onClick StopEx1 ] [ text "Stop" ]
        , div []
            [ button [ class "osci", onClick (SelectType WebAudio.Sine) ] [ text "Sine" ]
            , button [ class "osci", onClick (SelectType WebAudio.Square) ] [ text "Square" ]
            , button [ class "osci", onClick (SelectType WebAudio.Triangle) ] [ text "Triangle" ]
            , button [ class "osci", onClick (SelectType WebAudio.Sawtooth) ] [ text "Sawtooth" ]
            ]
        , h2 [] [ text "Example 2: BufferSource Node" ]
        , case model.ex2 of
            Nothing ->
                button [ onClick PlayEx2 ] [ text "Play" ]

            Just _ ->
                button [ onClick StopEx2 ] [ text "Stop" ]
        , h2 [] [ text "Example 3: Convolver Node" ]
        , case model.ex3 of
            Nothing ->
                button [ onClick PlayEx3 ] [ text "Play" ]

            Just _ ->
                button [ onClick StopEx3 ] [ text "Stop" ]
        , h2 [] [ text "Example 4: Gain Node With Dynamic Frequency" ]
        , case model.ex4 of
            Nothing ->
                button [ onClick PlayEx4 ] [ text "Play" ]

            Just _ ->
                button [ onClick StopEx4 ] [ text "Stop" ]
        , WebAudio.toHtml
            { graph =
                List.concat
                    [ case model.ex1 of
                        Nothing ->
                            []

                        Just start ->
                            let
                                node : Int -> Float -> WebAudio.Props
                                node nodeNumber pos =
                                    WebAudio.Oscillator
                                        { type_ = model.ex1Type
                                        , frequency = WebAudio.Constant (440 * (2 ^ (toFloat nodeNumber / 12)))
                                        , startTime = WebAudio.Time (start + pos)
                                        , stopTime = WebAudio.Time (start + pos + 1)
                                        }
                            in
                            WebAudio.parallel (WebAudio.NodeId "gain")
                                WebAudio.output
                                (WebAudio.Gain { gain = WebAudio.Constant 0.05 })
                                [ node 0 0
                                , node 2 1
                                , node 4 2
                                , node 5 3
                                , node 4 4
                                , node 2 5
                                , node 0 6

                                --
                                , node 4 8
                                , node 5 9
                                , node 7 10
                                , node 9 11
                                , node 7 12
                                , node 5 13
                                , node 4 14

                                --
                                , node 0 16
                                , node 0 18
                                , node 0 20
                                , node 0 22

                                --
                                , node 0 24
                                , node 0 24.5
                                , node 2 25
                                , node 2 25.5
                                , node 4 26
                                , node 4 26.5
                                , node 5 27
                                , node 5 27.5
                                , node 4 28
                                , node 2 29
                                , node 0 30
                                ]
                    , case model.ex2 of
                        Nothing ->
                            []

                        Just start ->
                            WebAudio.serial (WebAudio.NodeId "buffersource-test")
                                WebAudio.output
                                [ WebAudio.Gain { gain = WebAudio.Constant 1 }
                                , WebAudio.BufferSource
                                    { buffer = WebAudio.Url "New_Place_of_Work.mp3"
                                    , detune = 0
                                    , startTime = WebAudio.Time start
                                    , stopTime = Nothing
                                    }
                                ]
                    , case model.ex3 of
                        Nothing ->
                            []

                        Just start ->
                            WebAudio.serial (WebAudio.NodeId "ex3")
                                WebAudio.output
                                [ WebAudio.Convolver { buffer = WebAudio.Url "s1_r1_b.mp3", normalize = False }
                                , WebAudio.Gain { gain = WebAudio.Constant 1 }
                                , WebAudio.BufferSource
                                    { buffer = WebAudio.Url "New_Place_of_Work.mp3"
                                    , detune = 0
                                    , startTime = WebAudio.Time start
                                    , stopTime = Nothing
                                    }
                                ]
                    , case model.ex4 of
                        Nothing ->
                            []

                        Just start ->
                            [ { id = WebAudio.NodeId "0"
                              , output = WebAudio.output
                              , props = WebAudio.Gain { gain = WebAudio.Constant 0.2 }
                              }
                            , { id = WebAudio.NodeId "1"
                              , output = [ WebAudio.Output (WebAudio.NodeId "0") ]
                              , props =
                                    WebAudio.Oscillator
                                        { type_ = WebAudio.Sine
                                        , frequency = WebAudio.Constant 440
                                        , startTime = WebAudio.Time start
                                        , stopTime = WebAudio.Time (start + 3)
                                        }
                              }
                            , { id = WebAudio.NodeId "2"
                              , output = [ WebAudio.OutputToProp { key = WebAudio.NodeId "1", destination = WebAudio.FrequencyProp } ]
                              , props = WebAudio.Gain { gain = WebAudio.Constant 350 }
                              }
                            , { id = WebAudio.NodeId "3"
                              , output = [ WebAudio.Output (WebAudio.NodeId "0"), WebAudio.Output (WebAudio.NodeId "output") ]
                              , props =
                                    WebAudio.Oscillator
                                        { type_ = WebAudio.Sine
                                        , frequency = WebAudio.Constant 1
                                        , startTime = WebAudio.Time start
                                        , stopTime = WebAudio.Time (start + 3)
                                        }
                              }
                            ]
                    ]
            , assets = []
            , onProgress = AssetLoaded
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
