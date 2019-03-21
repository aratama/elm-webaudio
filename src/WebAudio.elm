module WebAudio exposing
    ( Url(..)
    , Time(..)
    , Float32Array
    , Graph
    , Node
    , Props(..)
    , NodeId(..)
    , Output(..)
    , Param(..)
    , Method(..)
    , DynamicsCompressorProps
    , Oversample(..)
    , toHtml
    , output
    , dynamicsCompressor
    , dynamicsCompressorDefaults
    , parallel
    , serial
    , Destination(..)
    )

{-| elm-webaudio provides methods to play audio in Elm.


# Basic Types

@docs Url

@docs Time

@docs Float32Array


# Audio Graph

@docs Graph

@docs Node

@docs Props

@docs NodeId

@docs Output

@docs Param

@docs Method

@docs DynamicsCompressorProps

@docs Oversample


# Rendering

@docs toHtml


# Utilities

@docs output

@docs dynamicsCompressor

@docs dynamicsCompressorDefaults

@docs parallel

@docs serial

-}

import Html
import Html.Attributes
import Html.Events
import Json.Decode
import Json.Encode exposing (Value, bool, float, int, list, null, object, string)
import List


{-| Unique identifier of audio nodes in the audio graph.
-}
type NodeId
    = NodeId String


{-| Audio output.
-}
type Output
    = Output NodeId
    | Outputs (List NodeId)
    | OutputToProp { key : NodeId, destination : Destination }


{-| Propertiy name as a audio output destination.
-}
type Destination
    = FrequencyProp
    | DetuneProp
    | GainProp
    | DelayTimeProp
    | PanProp


{-| URL for an audio buffer.

Elm can't deal `AudioBuffer` objects directly
and use URL instead of `AudioBuffer`.

-}
type Url
    = Url String


{-| Float value representing audio time.
-}
type Time
    = Time Float


{-| Identifier for MediaElement.
-}
type MediaElementId
    = MediaElementId String


{-| AudioParam.
-}
type Param
    = Constant Float
    | Methods (List Method)


{-| Methods for AudioParam.
-}
type Method
    = SetValueAtTime Float Time
    | LinearRampToValueAtTime Float Time
    | ExponentialRampToValueAtTime Float Time
    | SetTargetAtTime Float Time Float
    | SetValueCurveAtTime (List Float) Time Float


{-| An enumerated value for `type` property of `BiquadFilter`.
-}
type BiquadFilterType
    = Lowpass
    | Highpass
    | Bandpass
    | Lowshelf
    | Highshelf
    | Peaking
    | Notch
    | Allpass


{-| -}
type PanningModel
    = Equalpower
    | HRTF


{-| -}
type DistanceModel
    = Linear
    | Inverse
    | Exponential


{-| -}
type alias Float32Array =
    List Float


{-| -}
type Oversample
    = OversampleNone
    | Oversample2x
    | Oversample4x


{-| -}
type Props
    = Analyser
        { fftSize : Int
        , minDecibels : Float
        , maxDecibels : Float
        , smoothingTimeConstant : Float
        }
    | BufferSource
        { buffer : Url
        , startTime : Time
        , stopTime : Maybe Time
        , detune : Int
        }
    | BiquadFilter
        { type_ : BiquadFilterType
        , frequency : Param
        , detune : Param
        , q : Param
        }
    | ChannelMerger
    | ChannelSplitter
    | Convolver
        { buffer : Url
        , normalize : Bool
        }
    | Delay
        { delayTime : Param
        , maxDelayTime : Param
        }
    | DynamicsCompressor DynamicsCompressorProps
    | Gain
        { gain : Param
        }
    | MediaElementSource
        { mediaElement : MediaElementId
        }
    | MediaStreamDestination
    | Oscillator
        { frequency : Param
        , startTime : Time
        , stopTime : Time
        }
    | Panner
        { coneInnerAngle : Float
        , coneOuterAngle : Float
        , coneOuterGain : Float
        , distanceModel : DistanceModel
        , orientationX : Param
        , orientationY : Param
        , orientationZ : Param
        , panningModel : PanningModel
        , positionX : Param
        , positionY : Param
        , positionZ : Param
        , maxDistance : Float
        , refDistance : Float
        , rolloffFactor : Float
        }
    | StereoPanner
        { pan : Param
        }
    | WaveShaper
        { curve : Float32Array
        , oversample : Oversample
        }


{-| Audio node.
-}
type alias Node =
    { id : NodeId
    , output : Output
    , props : Props
    }


{-| Audio graph.
-}
type alias Graph =
    List Node


{-| Data type for DynamicsCompresor.
-}
type alias DynamicsCompressorProps =
    { attack : Param
    , knee : Param
    , ratio : Param
    , release : Param
    , threshold : Param
    }


{-| -}
dynamicsCompressorDefaults : DynamicsCompressorProps
dynamicsCompressorDefaults =
    { attack = Constant 0.003
    , knee = Constant 30
    , ratio = Constant 12
    , release = Constant 0.25
    , threshold = Constant -24
    }


{-| Utility constructor for a DynaicCompressor.
-}
dynamicsCompressor : (DynamicsCompressorProps -> DynamicsCompressorProps) -> Props
dynamicsCompressor f =
    DynamicsCompressor (f dynamicsCompressorDefaults)


{-| Special identifier representing final destination. This is just a `Output (NodeId "output")`.
-}
output : Output
output =
    Output (NodeId "output")


{-| Render an audio graph as HTML.

NOTE: Each audio nodes should have unique id. If two nodes have the same id, the second node overwrites the first node.

-}
toHtml :
    { graph : Graph
    , assets : List String
    , onTick : Float -> msg
    , onProgress : List String -> msg
    }
    -> Html.Html msg
toHtml { graph, assets, onTick, onProgress } =
    Html.node "elm-webaudio"
        [ Html.Attributes.property "graph" (encode graph)
        , Html.Attributes.property "assets" (Json.Encode.list Json.Encode.string assets)
        , Html.Events.on "tick" <| Json.Decode.map onTick (Json.Decode.at [ "detail" ] Json.Decode.float)
        , Html.Events.on "assetLoaded" <| Json.Decode.map onProgress (Json.Decode.at [ "detail" ] (Json.Decode.list Json.Decode.string))
        ]
        []



-- encoding


encodeAudioParamMethod : Method -> Value
encodeAudioParamMethod method =
    case method of
        SetValueAtTime value (Time startTime) ->
            list identity [ string "setValueAtTime", float value, float startTime ]

        LinearRampToValueAtTime value (Time endTime) ->
            list identity [ string "linearRampToValueAtTime", float value, float endTime ]

        ExponentialRampToValueAtTime value (Time endTime) ->
            list identity [ string "exponentialRampToValueAtTime", float value, float endTime ]

        SetTargetAtTime target (Time startTime) timeConstant ->
            list identity [ string "setTargetAtTime", float target, float startTime, float timeConstant ]

        SetValueCurveAtTime values (Time startTime) duration ->
            list identity [ string "setValueCurveAtTime", list float values, float startTime, float duration ]


encodeAudioParam : Param -> Value
encodeAudioParam param =
    case param of
        Constant value ->
            float value

        Methods methods ->
            list encodeAudioParamMethod methods


nodeId : NodeId -> Value
nodeId (NodeId id) =
    string id


encodeOutput : Output -> Value
encodeOutput out =
    case out of
        Output (NodeId id) ->
            string id

        OutputToProp { key, destination } ->
            object [ ( "key", nodeId key ), ( "destination", string (destinationToString destination) ) ]

        Outputs os ->
            list nodeId os


destinationToString : Destination -> String
destinationToString dest =
    case dest of
        FrequencyProp ->
            "frequency"

        DetuneProp ->
            "detune"

        GainProp ->
            "gain"

        DelayTimeProp ->
            "delayTime"

        PanProp ->
            "pan"


bufferUrl : Url -> Value
bufferUrl (Url url) =
    string url


audioTime : Time -> Value
audioTime (Time time) =
    float time


encodePannerModel : PanningModel -> Value
encodePannerModel value =
    string <|
        case value of
            Equalpower ->
                "equalpower"

            HRTF ->
                "HRTF"


encodeDistanceModel : DistanceModel -> Value
encodeDistanceModel value =
    string <|
        case value of
            Linear ->
                "linear"

            Inverse ->
                "inverse"

            Exponential ->
                "xponential"


encodeBiquadFilterType : BiquadFilterType -> Value
encodeBiquadFilterType value =
    string <|
        case value of
            Lowpass ->
                "lowpass"

            Highpass ->
                "highpass"

            Bandpass ->
                "bandpass"

            Lowshelf ->
                "lowshelf"

            Highshelf ->
                "highshelf"

            Peaking ->
                "peaking"

            Notch ->
                "notch"

            Allpass ->
                "allpass"


encodeGraphEntry : Node -> ( String, Value )
encodeGraphEntry nodep =
    ( case nodep.id of
        NodeId id ->
            id
    , case nodep.props of
        Analyser node ->
            object
                [ ( "node", string "Analyser" )
                , ( "output", encodeOutput nodep.output )
                , ( "fftSize", int node.fftSize )
                , ( "minDecibels", float node.minDecibels )
                , ( "maxDecibels", float node.maxDecibels )
                , ( "smoothingTimeConstant", float node.smoothingTimeConstant )
                ]

        BufferSource node ->
            object
                [ ( "node", string "BufferSource" )
                , ( "output", encodeOutput nodep.output )
                , ( "buffer", bufferUrl node.buffer )
                , ( "startTime", audioTime node.startTime )
                , ( "stopTime", Maybe.withDefault null <| Maybe.map audioTime node.stopTime )
                , ( "detune", int node.detune )
                ]

        BiquadFilter node ->
            object
                [ ( "node", string "BiquadFilter" )
                , ( "type_", encodeBiquadFilterType node.type_ )
                , ( "frequency", encodeAudioParam node.frequency )
                , ( "detune", encodeAudioParam node.detune )
                , ( "q", encodeAudioParam node.q )
                ]

        ChannelMerger ->
            object [ ( "node", string "ChannelMerger" ) ]

        ChannelSplitter ->
            object [ ( "node", string "ChannelSplitter" ) ]

        Delay node ->
            object
                [ ( "node", string "Delay" )
                , ( "delayTime", encodeAudioParam node.delayTime )
                , ( "maxDelayTime", encodeAudioParam node.maxDelayTime )
                ]

        Convolver node ->
            object
                [ ( "node", string "Convolver" )
                , ( "output", encodeOutput nodep.output )
                , ( "buffer", bufferUrl node.buffer )
                , ( "normalize", bool node.normalize )
                ]

        DynamicsCompressor node ->
            object
                [ ( "node", string "DynamicsCompressor" )
                , ( "output", encodeOutput nodep.output )
                ]

        Gain node ->
            object
                [ ( "node", string "Gain" )
                , ( "output", encodeOutput nodep.output )
                , ( "gain", encodeAudioParam node.gain )
                ]

        MediaElementSource node ->
            object [ ( "node", string "MediaElementSource" ) ]

        MediaStreamDestination ->
            object [ ( "node", string "MediaStreamDestination" ) ]

        Oscillator node ->
            object
                [ ( "node", string "Oscillator" )
                , ( "output", encodeOutput nodep.output )
                , ( "frequency", encodeAudioParam node.frequency )
                , ( "startTime", audioTime node.startTime )
                , ( "stopTime", audioTime node.stopTime )
                ]

        Panner node ->
            object
                [ ( "node", string "Panner" )
                , ( "coneInnerAngle", float node.coneInnerAngle )
                , ( "coneOuterAngle", float node.coneOuterAngle )
                , ( "coneOuterGain", float node.coneOuterGain )
                , ( "distanceModel", encodeDistanceModel node.distanceModel )
                , ( "orientationX", encodeAudioParam node.orientationX )
                , ( "orientationY", encodeAudioParam node.orientationY )
                , ( "orientationZ", encodeAudioParam node.orientationZ )
                , ( "panningModel", encodePannerModel node.panningModel )
                , ( "positionX", encodeAudioParam node.positionX )
                , ( "positionY", encodeAudioParam node.positionY )
                , ( "positionZ", encodeAudioParam node.positionZ )
                , ( "maxDistance", float node.maxDistance )
                , ( "refDistance", float node.refDistance )
                , ( "rolloffFactor", float node.rolloffFactor )
                ]

        StereoPanner node ->
            object
                [ ( "node", string "StereoPanner" )
                , ( "pan", encodeAudioParam node.pan )
                ]

        WaveShaper node ->
            object
                [ ( "node", string "WaveShaper" )
                , ( "curve", list float node.curve )
                , ( "oversample"
                  , string <|
                        case node.oversample of
                            OversampleNone ->
                                "none"

                            Oversample2x ->
                                "2x"

                            Oversample4x ->
                                "4x"
                  )
                ]
    )


encode : Graph -> Value
encode graph =
    object <| List.map encodeGraphEntry graph



-- utils


{-| Name nodes automatically and connect them serially.

    serial (NodeId "x") output x [ a, b, c ]

is converted into a audio grapha as:

```js
[ { id = "x", output = "output", props = x }
, { id = "x/0", output = "x", props = a }
, { id = "x/0/0", output = "x/0", props = b }
, { id = "x/0/0/0", output = "x/0/0", props = c }
]
```

-}
serial : NodeId -> Output -> List Props -> List Node
serial id out nodes =
    case id of
        NodeId idStr ->
            case nodes of
                [] ->
                    []

                head :: rem ->
                    let
                        go : String -> List Props -> List Node
                        go previous remaining =
                            case remaining of
                                [] ->
                                    []

                                y :: [] ->
                                    [ { id = NodeId (previous ++ "/0")
                                      , output = Output (NodeId previous)
                                      , props = y
                                      }
                                    ]

                                y :: ys ->
                                    let
                                        nid =
                                            previous ++ "/0"
                                    in
                                    { id = NodeId nid
                                    , output = Output (NodeId previous)
                                    , props = y
                                    }
                                        :: go nid ys
                    in
                    { id = id
                    , output = out
                    , props = head
                    }
                        :: go idStr rem


{-| Name nodes automatically and connect in parallel.

    parallel (NodeId "x") output x [ a, b, c ]

is converted into a audio graph as:WW

```js
[ { id = "x", output = "output", props = x }
, { id = "x/0", output = "x", props = a }
, { id = "x/1", output = "x", props = b }
, { id = "x/2", output = "x", props = c }
]
```

-}
parallel : NodeId -> Output -> Props -> List Props -> List Node
parallel id out parent children =
    case id of
        NodeId idStr ->
            { id = id
            , output = out
            , props = parent
            }
                :: List.indexedMap
                    (\i child ->
                        { id = NodeId (idStr ++ "/" ++ String.fromInt i)
                        , output = Output id
                        , props = child
                        }
                    )
                    children
