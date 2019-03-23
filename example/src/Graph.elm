module Graph exposing (Graph)


type Id
    = Id String


type alias Graph a =
    List { id : Id, output : List Id, value : a }


renderGraph : Int -> Int -> Graph a -> List { id : Id, x : Int, y : Int }
renderGraph xSpan ySpan _ =
    []
