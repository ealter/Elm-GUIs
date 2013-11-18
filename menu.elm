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
m >> s = m >>= return s
infixl 1 >>

title : Menu -> String
title (Menu t _) = t

submenus : Menu -> [Menu]
submenus (Menu _ ms) = ms

-- VIEW: Desktop and menu
menu_height = 20
item_height = 30

desktop : (Int, Int) -> Element
desktop (w,h) = flow outward <|
    [ spacer w h |> color lightGrey
    , spacer w menu_height |> color darkGrey ]

renderTitle : Menu -> Signal (Element, Maybe [Menu])
renderTitle m = let (elem, isHovering) = hoverable <| plainText (title m)
                    sel b = if b then color lightCharcoal else id
                    toRender b = if b then Just (submenus m) else Nothing
                in lift2 (,) (lift2 sel isHovering (constant elem))
                             (lift  toRender isHovering)

render1 : Menu -> Element
render1 m = let labels = map (plainText . title) <| submenus m
                maxWidth = maximum <| map widthOf labels
                spacers = map (\_ -> spacer (maxWidth + 20) item_height) labels
                items = zipWith (\l s -> layers [l,s]) labels spacers
            in flow down items


render : [Menu] -> Signal Element
render ms = let
    -- rendered : Signal [(Element, Bool)]
    rendered = combine <| map renderTitle ms
    --selected = filter snd <~ rendered
    titles = lift (map fst) rendered
            |> lift (intersperse (spacer 15 menu_height))
            |> lift (\es -> spacer 10 menu_height :: es)
            |> lift (flow right)
        in titles

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

