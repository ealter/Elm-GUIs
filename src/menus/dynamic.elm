import open Tree
import open Menu
import Mouse
import Keyboard
import Char

mousePosition : Signal String
mousePosition = lift show <| sampleOn Mouse.clicks Mouse.position

keystrokes = foldp (::) [] Keyboard.lastPressed
             |> lift reverse
             |> lift (show . (map Char.fromCode))

menuSpec : [Tree (Signal String)]
menuSpec = [Tree (constant "Main") [leaf (constant "About"), leaf mousePosition],
            Tree mousePosition [leaf (constant "File"), leaf keystrokes],
            Tree keystrokes [leaf (constant "New"), leaf mousePosition]]

main = fst <| renderMenu menuSpec

