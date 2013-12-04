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

{- Converts a menu specification into a menu. The top level of the menu is
   horizontal, so the width of the elements are variable. At all sublevels, the
   width of the elements depends on the maximum width of the elements in each
   particular submenu. -}
convertMenu : MenuSpecification -> Menu
convertMenu = let
    topLevel : Element -> Element
    topLevel elem = container (widthOf elem + 10) title_height middle elem

    menuSpecTitle (MenuSpecification title _) = title

    maxOrZero : [Int] -> Int
    maxOrZero list = case list of
        [] -> 0
        _ -> maximum list

    convert : (Element -> Element) -> MenuSpecification -> Menu
    convert boxElement (MenuSpecification title children) = let
        maxChildrenWidth = maxOrZero <| map (widthOf . plainText . menuSpecTitle) children
        otherLevels elem = container (maxChildrenWidth + 20) (heightOf elem) midLeft elem
                           |> color lightCharcoal
        (elem, hover) = hoverable <| boxElement <| plainText title
      in Menu elem hover (map (convert otherLevels) children)
  in convert topLevel

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
renderTitle m = let (elem, isHovering) = (menuElement m, isOnScreen m)
                    sel b = if b then color lightCharcoal else id
                in lift2 sel isHovering (constant elem)

-- Renders the submenu into an element
renderItems : [Menu] -> Signal Element
renderItems ms = let highlight : Bool -> Element -> Element
                     highlight b = if b then color lightBlue else id

                     colored : Menu -> Signal Element
                     colored m = lift2 highlight (hoverInfo m) (constant <| menuElement m)
                in lift (flow down) (combine <| map colored ms)

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

    renderSubmenu : Menu -> Int -> Signal Element
    renderSubmenu m parentWidth = 
        let blank = spacer parentWidth 1
            onscreen = isOnScreen m
            --Warning: DIRTY HACK. Prevent a race condition of displaying a menu
            --if you are hovering over it by adding a delay to the signal check
            shouldDisplay = lift2 (||) onscreen <| delay (0.05*second) onscreen
        in case submenus m of
            [] -> constant blank
            _  ->  maybeDisplay shouldDisplay blank <| renderItems (submenus m)

    allSubmenus = addSpacersAndRender <~ combine (zipWith renderSubmenu ms <| map (widthOf . menuElement) ms)

    addSpacersAndRender menus = intersperse (spacer inBetweenPadding 1) menus
            |> \ts -> spacer initialPadding 1 :: ts
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

