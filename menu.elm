import Window
import Graphics.Input (hoverable)

-- MODEL: Menu representation and monadic combinators
data Menu = Menu String [Menu]

return : String -> Menu
return s = Menu s []

(>>=) : Menu -> Menu -> Menu
(Menu t ms) >>= m2 = Menu t (ms ++ [m2])
infixl 2 >>=

(>>) : Menu -> String -> Menu
(Menu t ms) >> s = Menu t (ms ++ [return s])
infixl 1 >>

-- VIEW: Desktop and menu
menu_height = 20

desktop : (Int, Int) -> Element
desktop (w,h) = flow outward <|
    [ spacer w h |> color lightGrey
    , spacer w menu_height |> color darkGrey ]

render1 : String -> Signal (Element, Bool)
render1 s = let (elem, hover) = hoverable <| plainText s
                sel b = if b then color lightBlue else id
            in lift2 (,) (lift2 sel hover (constant elem)) hover

render : [Menu] -> Signal Element
render ms = let
    rendered : Signal [(Element, Bool)]
    rendered = combine <| map (render1 . (\(Menu s _) -> s)) ms
    labels = lift (map fst) rendered
        in labels
            |> lift (intersperse (spacer 15 menu_height))
            |> lift (\es -> spacer 10 menu_height :: es)
            |> lift (flow right)

-- MAIN
menus : [Menu]
menus =
    [ return "Main" >> "About" >> "Checkout for Updates"
    , return "File" >>= (return "Save" >> "Save as...") >> "Edit"
    ]

main = flow outward <~ combine
    [ desktop <~ Window.dimensions
    , render menus
    ]

