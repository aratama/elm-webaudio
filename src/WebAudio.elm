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
    , OscillatorType(..)
    , Destination(..)
    , toHtml
    , output
    , dynamicsCompressor
    , dynamicsCompressorDefaults
    , parallel
    , serial
    , serial_
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

@docs OscillatorType

@docs Destination


# Rendering

@docs toHtml


# Utilities

@docs output

@docs dynamicsCompressor

@docs dynamicsCompressorDefaults

@docs parallel

@docs serial

@docs serial_

-}

import Html
import Html.Attributes
import Html.Events
import Json.Decode
import Json.Encode exposing (Value, bool, float, int, list, null, object, string)
import List
import List.Extra as List


{-| Unique identifier of audio nodes in the audio graph.
-}
type NodeId
    = NodeId String


{-| Audio output.
-}
type Output
    = Output NodeId
    | OutputToProp { key : NodeId, destination : Destination }


type alias Outputs =
    List Output


{-| Propertiy name as a audio output destination.
-}
type Destination
    = FrequencyProp
    | DetuneProp
    | GainProp
    | DelayTimeProp
    | PanProp


{-| -}
type OscillatorType
    = Sine
    | Square
    | Sawtooth
    | Triangle
    | Custom


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
        { type_ : OscillatorType
        , frequency : Param
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
    , output : Outputs
    , props : Props
    }


{-| Audio graph.
-}
type alias Graph =
    List Node


{-| Properties of DynamicsCompresor.
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


{-| Special identifier representing terminatory destination. This is just a shorthand for `[ Output (NodeId "output") ]`.
-}
output : Outputs
output =
    [ Output (NodeId "output") ]


{-| Render an audio graph as HTML.

NOTE: Each audio nodes should have unique id. If two nodes have the same id, the second node overwrites the first node.

-}
toHtml :
    { graph : Graph
    , assets : List Url
    , onTick : Time -> msg
    , onProgress : List Url -> msg
    }
    -> Html.Html msg
toHtml { graph, assets, onTick, onProgress } =
    Html.node "elm-webaudio"
        [ Html.Attributes.property "graph" (encode graph)
        , Html.Attributes.property "assets" (Json.Encode.list encodeUrl assets)
        , Html.Events.on "tick" <| Json.Decode.map (onTick << Time) (Json.Decode.at [ "detail" ] Json.Decode.float)
        , Html.Events.on "assetLoaded" <| Json.Decode.map onProgress (Json.Decode.at [ "detail" ] (Json.Decode.list (Json.Decode.map Url Json.Decode.string)))
        ]
        []



-- encoding


encodeUrl : Url -> Value
encodeUrl (Url url) =
    Json.Encode.string url


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


encodeOscillatorType : OscillatorType -> Value
encodeOscillatorType t =
    Json.Encode.string <|
        case t of
            Sine ->
                "sine"

            Square ->
                "square"

            Triangle ->
                "triangle"

            Sawtooth ->
                "sawtooth"

            Custom ->
                "custom"


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


encodeOutputs : Outputs -> Value
encodeOutputs outputs =
    case outputs of
        [] ->
            null

        o :: [] ->
            encodeOutput o

        _ ->
            list encodeOutput outputs


encodeGraphEntry : Node -> ( String, Value )
encodeGraphEntry nodep =
    ( case nodep.id of
        NodeId id ->
            id
    , case nodep.props of
        Analyser node ->
            object
                [ ( "node", string "Analyser" )
                , ( "output", encodeOutputs nodep.output )
                , ( "fftSize", int node.fftSize )
                , ( "minDecibels", float node.minDecibels )
                , ( "maxDecibels", float node.maxDecibels )
                , ( "smoothingTimeConstant", float node.smoothingTimeConstant )
                ]

        BufferSource node ->
            object
                [ ( "node", string "BufferSource" )
                , ( "output", encodeOutputs nodep.output )
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
                , ( "output", encodeOutputs nodep.output )
                , ( "buffer", bufferUrl node.buffer )
                , ( "normalize", bool node.normalize )
                ]

        DynamicsCompressor node ->
            object
                [ ( "node", string "DynamicsCompressor" )
                , ( "output", encodeOutputs nodep.output )
                ]

        Gain node ->
            object
                [ ( "node", string "Gain" )
                , ( "output", encodeOutputs nodep.output )
                , ( "gain", encodeAudioParam node.gain )
                ]

        MediaElementSource node ->
            object [ ( "node", string "MediaElementSource" ) ]

        MediaStreamDestination ->
            object [ ( "node", string "MediaStreamDestination" ) ]

        Oscillator node ->
            object
                [ ( "node", string "Oscillator" )
                , ( "output", encodeOutputs nodep.output )
                , ( "type", encodeOscillatorType node.type_ )
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


{-| Name nodes automatically and connect them serially. An audio graph

    serial (NodeId "x") out x [ a, b, c ]

is converted into a audio grapha as:

```js
[ { id = "x", output = out, props = x }
, { id = "x/0", output = "x", props = a }
, { id = "x/0/0", output = "x/0", props = b }
, { id = "x/0/0/0", output = "x/0/0", props = c }
]
```

-}
serial : NodeId -> Outputs -> List Props -> List Node
serial id out nodes =
    serial_ id out <| List.map (\props -> ( True, props )) nodes


{-| An another version of `serial`. A tuple with `False` is bypassed.

    serial_ (NodeId "x") out x [ ( True, a ), ( False, b ), ( True, c ) ]

is converted into a audio grapha as:

```js
[ { id = "x", output = out, props = x }
, { id = "x/0", output = "x", props = a }
, { id = "x/0/0", output = "x/0", props = b }
, { id = "x/0/0/0", output = "x/0", props = c }
]
```

-}
serial_ : NodeId -> Outputs -> List ( Bool, Props ) -> List Node
serial_ firstNodeId out pairs =
    case firstNodeId of
        NodeId firstNodeIdStr ->
            Tuple.second <|
                List.mapAccuml
                    (\( str, dest ) ( enabled, props ) ->
                        ( ( str ++ "/0"
                          , if enabled then
                                [ Output (NodeId str) ]

                            else
                                dest
                          )
                        , { id = NodeId str, output = dest, props = props }
                        )
                    )
                    ( firstNodeIdStr, out )
                    pairs


{-| Name nodes automatically and connect in parallel. An audio graph

    parallel (NodeId "x") out x [ a, b, c ]

is converted into a audio graph as:

```js
[ { id = "x", output = out, props = x }
, { id = "x/0", output = "x", props = a }
, { id = "x/1", output = "x", props = b }
, { id = "x/2", output = "x", props = c }
]
```

-}
parallel : NodeId -> Outputs -> Props -> List Props -> List Node
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
                        , output = [ Output id ]
                        , props = child
                        }
                    )
                    children
