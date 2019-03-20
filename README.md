# elm-webaudio

**elm-webaudio** provides methods to play audio in Elm.
elm-webaudio interacts with out of port in the same manner as [elm-canvas](https://github.com/joakin/elm-canvas).
It supports not only representing an audio graph with data types but also passing the graph to JS side through custom element and rendering actual audio graph.


## Minimal Example

```elm
    render =
        WebAudio.toHtml 
            { graph = 
                [ Oscillator { id = "osci", frequency = 440, output = [ WebAudio.output ] } ] }
```

## Tick

elm-webausio provides `tick` custom event.


## See Also

- [API docs for virtual-audio-graph](https://github.com/benji6/virtual-audio-graph/blob/master/docs/standard-nodes.md)
- [pd-andy/elm-audio-graph](https://package.elm-lang.org/packages/pd-andy/elm-audio-graph/latest/)
- [flowlang-cc/elm-audio-graph](https://package.elm-lang.org/packages/flowlang-cc/elm-audio-graph/latest/)

