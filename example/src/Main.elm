module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, input, text)
import Html.Attributes as Html exposing (class, src)
import Html.Events as Html exposing (onClick)
import Json.Decode as Decode
import List.Extra as List
import Svg
import Svg.Attributes as SvgA
import Svg.Keyed
import WebAudio


sample : WebAudio.Url
sample =
    WebAudio.Url "New_Place_of_Work.mp3"



---- MODEL ----


type alias Model =
    { now : Float
    , ex1 : Maybe Float
    , ex1Type : WebAudio.OscillatorType
    , ex2 : Maybe Float
    , ex3 : { playing : Maybe Float, reverb : Bool, delay : Bool, pan : Float }
    , ex4 : Maybe Float
    }


init : ( Model, Cmd Msg )
init =
    ( { now = 0
      , ex1 = Nothing
      , ex1Type = WebAudio.Sine
      , ex2 = Nothing
      , ex3 = { playing = Nothing, reverb = False, delay = False, pan = 0.0 }
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
    | SetReverb Bool
    | SetDelay Bool
    | SetPan Float
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
            let
                ex3 =
                    model.ex3
            in
            ( { model | ex3 = { ex3 | playing = Just model.now } }, Cmd.none )

        StopEx3 ->
            let
                ex3 =
                    model.ex3
            in
            ( { model | ex3 = { ex3 | playing = Nothing } }, Cmd.none )

        SetReverb value ->
            let
                ex3 =
                    model.ex3
            in
            ( { model | ex3 = { ex3 | reverb = value } }, Cmd.none )

        SetDelay value ->
            let
                ex3 =
                    model.ex3
            in
            ( { model | ex3 = { ex3 | delay = value } }, Cmd.none )

        SetPan value ->
            let
                ex3 =
                    model.ex3
            in
            ( { model | ex3 = { ex3 | pan = value } }, Cmd.none )

        PlayEx4 ->
            ( { model | ex4 = Just model.now }, Cmd.none )

        StopEx4 ->
            ( { model | ex4 = Nothing }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        graph =
            audioGraph model
    in
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
        , case model.ex3.playing of
            Nothing ->
                button [ onClick PlayEx3 ] [ text "Play" ]

            Just _ ->
                button [ onClick StopEx3 ] [ text "Stop" ]
        , div []
            [ input [ Html.type_ "checkbox", Html.checked model.ex3.reverb, Html.on "input" (Decode.map SetReverb Html.targetChecked) ] []
            , text "Reverb"
            ]
        , div []
            [ input [ Html.type_ "checkbox", Html.checked model.ex3.delay, Html.on "input" (Decode.map SetDelay Html.targetChecked) ] []
            , text "Delay"
            ]
        , div []
            [ input
                [ Html.type_ "range"
                , Html.min "-1"
                , Html.max "1"
                , Html.step "0.02"
                , Html.value (String.fromFloat model.ex3.pan)
                , Html.on "input"
                    (Decode.andThen
                        (\str ->
                            case String.toFloat str of
                                Nothing ->
                                    Decode.fail "invalid value"

                                Just value ->
                                    Decode.succeed (SetPan value)
                        )
                        Html.targetValue
                    )
                ]
                []
            , text "Pan"
            ]
        , h2 [] [ text "Example 4: Gain Node With Dynamic Frequency" ]
        , case model.ex4 of
            Nothing ->
                button [ onClick PlayEx4 ] [ text "Play" ]

            Just _ ->
                button [ onClick StopEx4 ] [ text "Stop" ]
        , renderSvg graph
        , WebAudio.toHtml <|
            { graph = graph
            , assets = [ sample ]
            , onProgress = AssetLoaded
            , onTick = Tick
            }
        ]


audioGraph : Model -> WebAudio.Graph
audioGraph model =
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
                    ]
        , case model.ex2 of
            Nothing ->
                []

            Just start ->
                WebAudio.serial (WebAudio.NodeId "buffersource-test")
                    WebAudio.output
                    [ WebAudio.Gain { gain = WebAudio.Constant 1 }
                    , WebAudio.BufferSource
                        { buffer = sample
                        , detune = 0
                        , startTime = WebAudio.Time start
                        , stopTime = Nothing
                        }
                    ]
        , case model.ex3.playing of
            Nothing ->
                []

            Just start ->
                List.concat
                    [ List.filterMap identity
                        [ Just
                            { id = WebAudio.NodeId "ex3-pan"
                            , output = WebAudio.output
                            , props = WebAudio.StereoPanner { pan = WebAudio.Constant model.ex3.pan }
                            }
                        , Just { id = WebAudio.NodeId "ex3-comp", output = [ WebAudio.Output (WebAudio.NodeId "ex3-pan") ], props = WebAudio.dynamicsCompressor identity }
                        , if model.ex3.reverb then
                            Just { id = WebAudio.NodeId "ex3-conv", output = [ WebAudio.Output (WebAudio.NodeId "ex3-comp") ], props = WebAudio.Convolver { buffer = WebAudio.Url "s1_r1_b.mp3", normalize = False } }

                          else
                            Nothing
                        , if model.ex3.reverb then
                            Just { id = WebAudio.NodeId "ex3-gain", output = [ WebAudio.Output (WebAudio.NodeId "ex3-conv") ], props = WebAudio.Gain { gain = WebAudio.Constant 2.5 } }

                          else
                            Nothing
                        , Just
                            { id = WebAudio.NodeId "ex3-buf"
                            , output =
                                List.concat
                                    [ [ WebAudio.Output <|
                                            WebAudio.NodeId <|
                                                if model.ex3.reverb then
                                                    "ex3-gain"

                                                else
                                                    "ex3-comp"
                                      ]
                                    , if model.ex3.delay then
                                        [ WebAudio.Output (WebAudio.NodeId "ex3-delay") ]

                                      else
                                        []
                                    ]
                            , props =
                                WebAudio.BufferSource
                                    { buffer = sample
                                    , detune = 0
                                    , startTime = WebAudio.Time (start + 0.5)
                                    , stopTime = Nothing
                                    }
                            }
                        ]
                    , if model.ex3.delay then
                        WebAudio.delay 0.2 0.5 (WebAudio.NodeId "ex3-delay") [ WebAudio.Output (WebAudio.NodeId "ex3-comp") ]

                      else
                        []
                    ]
        , case model.ex4 of
            Nothing ->
                []

            Just start ->
                [ { id = WebAudio.NodeId "ex4-0"
                  , output = WebAudio.output
                  , props = WebAudio.Gain { gain = WebAudio.Constant 0.2 }
                  }
                , { id = WebAudio.NodeId "ex4-1"
                  , output = [ WebAudio.Output (WebAudio.NodeId "ex4-0") ]
                  , props =
                        WebAudio.Oscillator
                            { type_ = WebAudio.Sine
                            , frequency = WebAudio.Constant 440
                            , startTime = WebAudio.Time start
                            , stopTime = WebAudio.Time (start + 3)
                            }
                  }
                , { id = WebAudio.NodeId "ex4-3"
                  , output = [ WebAudio.Output (WebAudio.NodeId "output"), WebAudio.Output (WebAudio.NodeId "ex4-0") ]
                  , props =
                        WebAudio.Oscillator
                            { type_ = WebAudio.Sine
                            , frequency = WebAudio.Constant 1
                            , startTime = WebAudio.Time start
                            , stopTime = WebAudio.Time (start + 3)
                            }
                  }
                , { id = WebAudio.NodeId "ex4-2"
                  , output = [ WebAudio.OutputToProp { key = WebAudio.NodeId "ex4-1", destination = WebAudio.FrequencyProp } ]
                  , props = WebAudio.Gain { gain = WebAudio.Constant 350 }
                  }
                ]
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


type Tree a
    = Tree a (List (Tree a))


audioGraphToAudioTree : WebAudio.Graph -> List (Tree WebAudio.Node)
audioGraphToAudioTree graph =
    let
        go : WebAudio.Node -> Tree WebAudio.Node
        go parent =
            Tree parent
                (List.filterMap
                    (\child ->
                        case child.output of
                            (WebAudio.Output out) :: _ ->
                                if out == parent.id then
                                    Just (go child)

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )
                    graph
                )
    in
    List.filterMap
        (\node ->
            case node.output of
                [] ->
                    Just (go node)

                _ ->
                    Nothing
        )
        graph


treeWidth : Tree a -> Int
treeWidth (Tree _ children) =
    max 1 <| List.sum (List.map treeWidth children)


renderSvg : WebAudio.Graph -> Html msg
renderSvg graph =
    let
        radius =
            24

        spanX =
            100

        spanY =
            100

        graph_ =
            { id = WebAudio.NodeId "output", output = [], props = WebAudio.Gain { gain = WebAudio.Constant 0 } } :: graph

        tree =
            audioGraphToAudioTree graph_

        renderTree : Int -> Int -> List (Tree WebAudio.Node) -> List ( String, Svg.Svg msg )
        renderTree x0 y0 nodes =
            List.concat <|
                Tuple.second <|
                    List.mapAccuml
                        (\( x, y ) (Tree node children) ->
                            case node.id of
                                WebAudio.NodeId idStr ->
                                    let
                                        h =
                                            spanY * treeWidth (Tree node children)
                                    in
                                    ( ( x, y + h )
                                    , ( idStr
                                      , Svg.circle
                                            [ SvgA.id idStr
                                            , SvgA.fill "lightgrey"
                                            , SvgA.r (String.fromInt radius)

                                            --, SvgA.cx (String.fromInt x)
                                            --, SvgA.cy (String.fromInt y)
                                            , SvgA.style <| "cx : " ++ String.fromInt x ++ "; cy: " ++ String.fromInt (y + h // 2)
                                            ]
                                            []
                                      )
                                        :: renderTree (x + spanX) y children
                                    )
                        )
                        ( x0, y0 )
                        nodes

        renderConnections : List ( String, Svg.Svg msg )
        renderConnections =
            List.concatMap
                (\node ->
                    case node.id of
                        WebAudio.NodeId idStr ->
                            List.map
                                (\out ->
                                    case out of
                                        WebAudio.Output (WebAudio.NodeId outId) ->
                                            ( "connection-" ++ idStr ++ "-" ++ outId
                                            , Svg.path
                                                [ SvgA.id <| "connection-" ++ idStr ++ "-" ++ outId
                                                , Html.attribute "data-from" idStr
                                                , Html.attribute "data-to" outId
                                                , SvgA.stroke "black"
                                                , SvgA.strokeWidth "3"
                                                , SvgA.strokeLinecap "round"
                                                , SvgA.markerEnd "url(#triangle)"
                                                ]
                                                []
                                            )

                                        WebAudio.OutputToProp entry ->
                                            ( "", Svg.path [] [] )
                                )
                                node.output
                )
                graph_
    in
    Svg.svg []
        [ Svg.defs []
            [ Svg.marker
                [ SvgA.id "triangle"
                , SvgA.viewBox "0 0 10 10"
                , SvgA.refX "1"
                , SvgA.refY "5"
                , SvgA.markerUnits "strokeWidth"
                , SvgA.markerWidth "3"
                , SvgA.markerHeight "3"
                , SvgA.orient "auto"
                ]
                [ Svg.path [ SvgA.d "M 0 0 L 10 5 L 0 10 z", SvgA.fill "black" ] []
                ]
            ]
        , Svg.g [ SvgA.transform "translate(50, 50)" ]
            [ Svg.Keyed.node "g" [ SvgA.id "connection-layer" ] renderConnections
            , Svg.Keyed.node "g" [ SvgA.id "circle-layer" ] (renderTree 0 0 tree)
            ]
        ]
