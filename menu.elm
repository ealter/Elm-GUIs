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

convertMenu : MenuSpecification -> Menu
convertMenu (MenuSpecification title children) = let
    (elem, hover) = hoverable <| plainText title
  in Menu elem hover (map convertMenu children)

-- Calculates whether a submenu should be shown on the screen
-- Parameters: parent, submenu
isOnScreen : Maybe Menu -> [Menu] -> Signal Bool
isOnScreen m children = let
    hoveringMe = case m of
                    Just parent -> hoverInfo parent
                    Nothing -> constant False
    hoveringChildren = lift or <| combine <| map hoverInfo children
    hoveringGrandchildren =
        if isEmpty children
        then constant False
        else lift or
            <| combine
            <| map (\c -> isOnScreen (Just c) (submenus c)) children
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
renderTitle : Menu -> (Signal Element, Int, Signal Bool, [Menu])
renderTitle m = let (elem, isHovering) = hoverable <| menuElement m
                    label = container (widthOf elem + 10) title_height middle elem
                    sel b = if b then color lightCharcoal else id
                    toRender b = if b then submenus m else []
                in (lift2 sel isHovering (constant label),
                    widthOf elem,
                    isHovering,
                    submenus m)

{- * The first parameter denotes whether the submenu should be rendered at all.
   * The second parameter is the default value for the element (i.e. when the
     boolean signal evaluates to false)
   * The third parameter is the submenu itself
   * Returns the rendered submenu -}
renderItems : Signal Bool -> Element -> [Menu] -> Signal Element
renderItems parentHovered blankElement m = let
                    labels = map menuElement <| m
                    maxWidth = maximum <| map widthOf labels
                    items : [(Element, Signal Bool)]
                    items = map (\el -> (container (maxWidth + 20) item_height midLeft el)
                                |> color lightCharcoal |> hoverable) labels
                    fullMenu = flow down <| map fst items
                    submenuIsHovered = lift or (combine (map snd items))
                    shouldDisplay = lift2 (||) submenuIsHovered parentHovered
                  in lift (\b -> if b then fullMenu else blankElement) shouldDisplay

render : Direction -> Direction -> Int -> Int -> [Menu] -> Signal Element
render flowDirection submenuFlowDirection initialPadding inBetweenPadding ms = let
    rendered : [(Signal Element, Int, Signal Bool, [Menu])]
    rendered = map renderTitle ms
    renderSubmenu (elem, elemWidth, isHovering, submenu) =
        let blank = spacer elemWidth 1
        in case submenu of
            [] -> constant blank
            _  ->  renderItems isHovering blank submenu

    allSubmenus = addSpacersAndRender <~ combine (map renderSubmenu rendered)

    addSpacersAndRender menus = intersperse (spacer inBetweenPadding title_height) menus
            |> \ts -> spacer initialPadding title_height :: ts
            |> flow flowDirection

    titles = combine (map (\(e, _, _, _) -> e) rendered)
            |> lift addSpacersAndRender
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

