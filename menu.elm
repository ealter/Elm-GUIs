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

-- Renders an element of the top level menu and maybe its submenu
renderTitle : Menu -> Signal (Element, [Menu])
renderTitle m = let (elem, isHovering) = hoverable <| plainText (title m)
                    sel b = if b then color lightCharcoal else id
                    toRender b = if b then submenus m else []
                in lift2 (,) (lift2 sel isHovering (constant elem))
                             (lift  toRender isHovering)

render1 : [Menu] -> Element
render1 m = let labels = map (plainText . title) <| m
                maxWidth = maximum <| map widthOf labels
                spacers = map (\_ -> (color lightCharcoal (spacer (maxWidth + 20) item_height))) labels
                items = zipWith (\s l -> layers [s,l]) spacers labels
            in flow down items

render : Direction -> Direction -> Int -> Int -> [Menu] -> Signal Element
render flowDirection submenuFlowDirection initialPadding inBetweenPadding ms = let
    -- rendered : [Signal (Element, Bool)]
    rendered = map renderTitle ms
    renderSubmenu (elem, submenu) = case submenu of
            [] -> spacer (widthOf elem) 10
            otherwise ->  render1 submenu

    allSubmenus = lift addSpacersAndRender (combine (map (lift renderSubmenu) rendered))

    addSpacersAndRender menus = intersperse (spacer inBetweenPadding menu_height) menus
            |> \es -> spacer initialPadding menu_height :: es
            |> flow flowDirection

    titles = lift (map fst) (combine rendered)
            |> lift addSpacersAndRender
        in lift (flow submenuFlowDirection) (combine [titles, allSubmenus])

renderTopLevel = render right down 10 15

-- MAIN
menus : [Menu]
menus =
    [ return "Main" >> "About" >> "Checkout for Updates"
    , return "File" >>= (return "Save" >> "Save as...") >> "Edit"
    ]

main = flow outward <~ combine
    [ desktop <~ Window.dimensions
    , renderTopLevel menus
    ]

