import Window
import Graphics.Input (hoverable)

-- MODEL: Menu representation and monadic combinators
data MenuSpecification = MenuSpecification String [MenuSpecification]
data Menu = Menu Element (Signal Bool) [Menu]

return : String -> MenuSpecification
return s = MenuSpecification s []

(>>=) : MenuSpecification -> MenuSpecification -> MenuSpecification
(MenuSpecification t ms) >>= m2 = MenuSpecification t (ms ++ [m2])
infixl 2 >>=

(>>) : MenuSpecification -> String -> MenuSpecification
m >> s = m >>= return s
infixl 1 >>

submenus : Menu -> [Menu]
submenus (Menu _ _ ms) = ms

menuElement : Menu -> Element
menuElement (Menu e _ _) = e

hoverInfo : Menu -> Signal Bool
hoverInfo (Menu _ h _) = h

{- TODO: possible bug:
      Since we're using plainText (instead of a container), this could
      potentially mess up the hover information. -}
convertMenu : MenuSpecification -> Menu
convertMenu (MenuSpecification title children) = let
    (elem, hover) = hoverable <| mkContainer <| plainText title
  in Menu elem hover (map convertMenu children)

mkContainer elem = container (widthOf elem) (heightOf elem + 5) midBottom elem

-- Calculates whether a submenu should be shown on the screen
-- Parameters: parent, submenu
isOnScreen : Menu -> Signal Bool
isOnScreen m = let
    children = submenus m
    hoveringMe = hoverInfo m
    hoveringChildren = lift or <| combine <| map hoverInfo children
    hoveringGrandchildren =
        if isEmpty children
        then constant False
        else lift or
            <| combine
            <| map isOnScreen children
  in lift or <| combine [hoveringMe, hoveringChildren, hoveringGrandchildren]

-- VIEW: Desktop and menu
title_height = 20
item_height = 30

desktop : (Int, Int) -> Element
desktop (w,h) = flow outward <|
    [ spacer w h |> color lightGrey
    , spacer w title_height |> color darkGrey ]

{- Takes a menu, renders its title, and returns the submenus to render
   Also returns the width of the element, whether the element is being hovered
   over, and the submenu of the element. The extra parameters (such as width)
   are needed so that they can be used in "lifted" functions -}
renderTitle : Menu -> Signal Element
renderTitle m = let (elem, isHovering) = (menuElement m, hoverInfo m)
                    label = container (widthOf elem + 10) title_height middle elem
                    sel b = if b then color lightCharcoal else id
                in lift2 sel isHovering (constant label)

-- Renders the submenu into an element
renderItems : [Menu] -> Signal Element
renderItems m = let labels = map menuElement <| m
                    maxWidth = maximum <| map widthOf labels
                    items : [Element]
                    --items = map (\el -> (container (maxWidth + 20) item_height midLeft el)
                    items = map (\el -> (container (maxWidth + 20) (heightOf el) midLeft el)
                                |> color lightCharcoal) labels
                in constant <| flow down <| items

-- Replaces the element with the default when the signal is false
maybeDisplay : Signal Bool -> Element -> Signal Element -> Signal Element
maybeDisplay shouldDisplay defaultElement elem = let
        choose : Bool -> a -> a -> a
        choose b ifTrue ifFalse = if b then ifTrue else ifFalse
    in lift3 choose shouldDisplay elem (constant defaultElement)

render : Direction -> Direction -> Int -> Int -> [Menu] -> Signal Element
render flowDirection submenuFlowDirection initialPadding inBetweenPadding ms = let
    rendered : [Signal Element]
    rendered = map renderTitle ms

    renderSubmenu : Menu -> Signal Element
    renderSubmenu m = 
        let blank = spacer (widthOf <| menuElement m) 1
            onscreen = isOnScreen m
            shouldDisplay = lift2 (||) onscreen <| delay (0.25*second) onscreen
        in case submenus m of
            [] -> constant blank
            _  ->  maybeDisplay shouldDisplay blank <| renderItems (submenus m)

    allSubmenus = addSpacersAndRender <~ combine (map renderSubmenu ms)

    addSpacersAndRender menus = intersperse (spacer inBetweenPadding title_height) menus
            |> \ts -> spacer initialPadding title_height :: ts
            |> flow flowDirection

    titles = lift addSpacersAndRender <| combine rendered
  in lift (flow submenuFlowDirection) (combine [titles, allSubmenus])

renderTopLevel = render right down 10 15

-- MAIN
menus : [Menu]
menus = map convertMenu
    [ return "Main" >> "About" >> "Check for Updates"
    , return "File" >>= (return "Save" >> "Save as...") >> "Edit"
    ]

main = flow outward <~ combine
    [ desktop <~ Window.dimensions
    , renderTopLevel menus
    ]

