# elm-webaudio

**elm-webaudio** provides methods to play audio in Elm via [Web Audio API](https://developer.mozilla.org/docs/Web/API/Web_Audio_API).
It supports not only representing an audio graph with Elm's data types but also rendering actual an audio graph and playing audio. 
elm-webaudio uses [benji6/virtual-audio-graph](https://github.com/benji6/virtual-audio-graph/) internally. 
elm-webaudio intend to provide full access to Web Audio API, however it lacks some features right now.

elm-webaudio interacts with JavaScript in the same manner as [elm-canvas](https://github.com/joakin/elm-canvas): passing the graph to JS side through a custom element. 
Therefore, you also need to install the JavaScript module with `npm i aratama/elm-webaudio` and import it with `import "elm-webaudio";`.


## Basic Examples 


```elm  
view : Model -> Html Msg
view model = WebAudio.toHtml
    { graph = WebAudio.serial (WebAudio.NodeId "basic-example")
        WebAudio.output
        [ WebAudio.Gain { gain = WebAudio.Constant 1 }
        , WebAudio.BufferSource
            { buffer = WebAudio.Url "New_Place_of_Work.mp3"
            , detune = 0
            , startTime = WebAudio.Time 0
            , stopTime = Nothing
            }
        ]
    , assets = []
    , onProgress = AssetLoaded
    , onTick = Tick
    }
```

* `toHtml` converts a audio graph definition into Elm's HTML nodes. 
* If you want to refer an JavaScript's `AudioBuffer` object, just use an `Url` as a wapper of `String` instead of `AudioBuffer` object. 
elm-webaudio fetch the resource as `ArrayBuffer` and decode it into `AudioBuffer`, re-render the audio graph after completing load automatically. 
* You can preload audio resources by listing up urls in the `asset` property.
* You can get current audio time via `onTick` property. 
* All audio nodes must have their identifiers. `serial` utility function gives their ids automatically and connect them serially. So only one node needs its id in the example. 

See [the example](example) for more information.


## See Also

- [API docs for virtual-audio-graph](https://github.com/benji6/virtual-audio-graph/blob/master/docs/standard-nodes.md)
- [pd-andy/elm-audio-graph](https://package.elm-lang.org/packages/pd-andy/elm-audio-graph/latest/)
- [flowlang-cc/elm-audio-graph](https://package.elm-lang.org/packages/flowlang-cc/elm-audio-graph/latest/)

