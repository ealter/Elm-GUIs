import Window

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

render : [Menu] -> Element
render ms = map (plainText . (\(Menu s _) -> s)) ms
            |> intersperse (spacer 15 menu_height)
            |> (\es -> spacer 10 menu_height :: es)
            |> flow right

-- MAIN
menus : [Menu]
menus =
    [ return "Main" >> "About" >> "Checkout for Updates"
    , return "File" >>= (return "Save" >> "Save as...") >> "Edit"
    ]

main = flow outward <~ combine
    [ desktop <~ Window.dimensions
    , render <~ constant menus
    ]

