module WebAudio exposing
    ( AudioBufferUrl(..)
    , AudioGraph
    , AudioNode
    , AudioNodeId(..)
    , AudioNodeProps(..)
    , AudioOutput(..)
    , AudioParam(..)
    , AudioParamMethod(..)
    , AudioTime(..)
    , DynamicsCompressorProps
    , Float32Array
    , Oversample(..)
    , dynamicsCompressor
    , dynamicsCompressorDefaults
    , output
    , toHtml
    )

{-| elm-webaudio provides methods to play audio in Elm.
elm-webaudio interacts with out of port in the same manner as [elm-canvas](https://github.com/joakin/elm-canvas).
It supports not only representing an audio graph with data types but also passing the graph to JS side through custom element and rendering actual audio graph.


## Minimal Example

    render =
        WebAudio.toHtml { graph = [ Oscillator { id = "osci", frequency = 440, output = [ WebAudio.output ] } ] }


## Tick

elm-webausio provides `tick` custom event.


## Related Packages

  - [pd-andy/elm-audio-graph](https://package.elm-lang.org/packages/pd-andy/elm-audio-graph/latest/)
  - [flowlang-cc/elm-audio-graph](https://package.elm-lang.org/packages/flowlang-cc/elm-audio-graph/latest/)

-}

import Html
import Html.Attributes
import Html.Events
import Json.Decode
import Json.Encode exposing (Value, bool, float, int, list, null, object, string)
import List



-- types


type AudioNodeId
    = AudioNodeId String


type AudioOutput
    = Output AudioNodeId
    | Outputs (List AudioNodeId)
    | KeyWithDestination { key : AudioNodeId, destination : Destination }


type Destination
    = FrequencyProp
    | DetuneProp
    | GainProp
    | DelayTimeProp
    | PanProp


type AudioBufferUrl
    = AudioBufferUrl String


type AudioTime
    = AudioTime Float


type MediaElementId
    = MediaElementId String


type AudioParam
    = Constant Float
    | Methods (List AudioParamMethod)


type AudioParamMethod
    = SetValueAtTime Float AudioTime
    | LinearRampToValueAtTime Float AudioTime
    | ExponentialRampToValueAtTime Float AudioTime
    | SetTargetAtTime Float AudioTime Float
    | SetValueCurveAtTime (List Float) AudioTime Float


type BiquadFilterType
    = Lowpass
    | Highpass
    | Bandpass
    | Lowshelf
    | Highshelf
    | Peaking
    | Notch
    | Allpass


type PanningModel
    = Equalpower
    | HRTF


type DistanceModel
    = Linear
    | Inverse
    | Exponential


type alias Float32Array =
    List Float


type Oversample
    = OversampleNone
    | Oversample2x
    | Oversample4x


type AudioNodeProps
    = Analyser
        { fftSize : Int
        , minDecibels : Float
        , maxDecibels : Float
        , smoothingTimeConstant : Float
        }
    | BufferSource
        { buffer : AudioBufferUrl
        , startTime : AudioTime
        , stopTime : Maybe AudioTime
        , detune : Int
        }
    | BiquadFilter
        { type_ : BiquadFilterType
        , frequency : AudioParam
        , detune : AudioParam
        , q : AudioParam
        }
    | ChannelMerger
    | ChannelSplitter
    | Convolver
        { buffer : AudioBufferUrl
        , normalize : Bool
        }
    | Delay
        { delayTime : AudioParam
        , maxDelayTime : AudioParam
        }
    | DynamicsCompressor DynamicsCompressorProps
    | Gain
        { gain : AudioParam
        }
    | MediaElementSource
        { mediaElement : MediaElementId
        }
    | MediaStreamDestination
    | Oscillator
        { frequency : AudioParam
        , startTime : AudioTime
        , stopTime : AudioTime
        }
    | Panner
        { coneInnerAngle : Float
        , coneOuterAngle : Float
        , coneOuterGain : Float
        , distanceModel : DistanceModel
        , orientationX : AudioParam
        , orientationY : AudioParam
        , orientationZ : AudioParam
        , panningModel : PanningModel
        , positionX : AudioParam
        , positionY : AudioParam
        , positionZ : AudioParam
        , maxDistance : Float
        , refDistance : Float
        , rolloffFactor : Float
        }
    | StereoPanner
        { pan : AudioParam
        }
    | WaveShaper
        { curve : Float32Array
        , oversample : Oversample
        }


type alias AudioNode =
    { id : AudioNodeId
    , output : AudioOutput
    , properties : AudioNodeProps
    }


type alias AudioGraph =
    List AudioNode


type alias DynamicsCompressorProps =
    { attack : AudioParam
    , knee : AudioParam
    , ratio : AudioParam
    , release : AudioParam
    , threshold : AudioParam
    }


dynamicsCompressorDefaults : DynamicsCompressorProps
dynamicsCompressorDefaults =
    { attack = Constant 0.003
    , knee = Constant 30
    , ratio = Constant 12
    , release = Constant 0.25
    , threshold = Constant -24
    }


dynamicsCompressor : (DynamicsCompressorProps -> DynamicsCompressorProps) -> AudioNodeProps
dynamicsCompressor f =
    DynamicsCompressor (f dynamicsCompressorDefaults)


output : AudioOutput
output =
    Output (AudioNodeId "output")



-- html


toHtml :
    { graph : AudioGraph
    , assets : List String
    , onTick : Float -> msg
    , onInstrumentLoaded : List String -> msg
    }
    -> Html.Html msg
toHtml { graph, assets, onTick, onInstrumentLoaded } =
    Html.node "elm-webaudio"
        [ Html.Attributes.property "graph" (encode graph)
        , Html.Attributes.property "assets" (Json.Encode.list Json.Encode.string assets)
        , Html.Events.on "tick" <| Json.Decode.map onTick (Json.Decode.at [ "detail" ] Json.Decode.float)
        , Html.Events.on "instrumentloaded" <| Json.Decode.map onInstrumentLoaded (Json.Decode.at [ "detail" ] (Json.Decode.list Json.Decode.string))
        ]
        []



-- encoding


encodeAudioParamMethod : AudioParamMethod -> Value
encodeAudioParamMethod method =
    case method of
        SetValueAtTime value (AudioTime startTime) ->
            list identity [ string "setValueAtTime", float value, float startTime ]

        LinearRampToValueAtTime value (AudioTime endTime) ->
            list identity [ string "linearRampToValueAtTime", float value, float endTime ]

        ExponentialRampToValueAtTime value (AudioTime endTime) ->
            list identity [ string "exponentialRampToValueAtTime", float value, float endTime ]

        SetTargetAtTime target (AudioTime startTime) timeConstant ->
            list identity [ string "setTargetAtTime", float target, float startTime, float timeConstant ]

        SetValueCurveAtTime values (AudioTime startTime) duration ->
            list identity [ string "setValueCurveAtTime", list float values, float startTime, float duration ]


encodeAudioParam : AudioParam -> Value
encodeAudioParam param =
    case param of
        Constant value ->
            float value

        Methods methods ->
            list encodeAudioParamMethod methods


nodeId : AudioNodeId -> Value
nodeId (AudioNodeId id) =
    string id


encodeOutput : AudioOutput -> Value
encodeOutput out =
    case out of
        Output (AudioNodeId id) ->
            string id

        KeyWithDestination { key, destination } ->
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


bufferUrl : AudioBufferUrl -> Value
bufferUrl (AudioBufferUrl url) =
    string url


audioTime : AudioTime -> Value
audioTime (AudioTime time) =
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


encodeGraphEntry : AudioNode -> ( String, Value )
encodeGraphEntry nodep =
    ( case nodep.id of
        AudioNodeId id ->
            id
    , case nodep.properties of
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


encode : AudioGraph -> Value
encode graph =
    object <| List.map encodeGraphEntry graph
