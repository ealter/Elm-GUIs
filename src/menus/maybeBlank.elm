import open Tree
import open Menu
import Mouse
import Keyboard
import Char
import String

mousePosition : Signal String
mousePosition = lift show <| sampleOn Mouse.clicks Mouse.position

choose : Bool -> a -> a -> a
choose b ifTrue ifFalse = if b then ifTrue else ifFalse

maybeBlank = lift3 choose (lift ((<) 4) (fps 1))
                          (constant "")
                          (constant "barrrrrrrr")

menuSpec : [Tree (Signal String)]
menuSpec = [Tree maybeBlank [leaf (constant "About"), leaf mousePosition],
            Tree mousePosition [leaf (constant "File"), leaf (constant "o")],
            Tree (constant "ooo") [leaf (constant "New"), leaf mousePosition]]

main = fst <| renderMenu menuSpec

