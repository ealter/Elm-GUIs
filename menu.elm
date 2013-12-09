import Window
import Graphics.Input (hoverables)
import open Tree
import open SignalTricks

{- Steps:
    1. Signal tree of hover info
    2. bool tree -> [int]
    3. tree (element, bool hoverInfo) -> [int] -> tree (element, bool isOnScreen)
    4. tree (element, bool isOnScreen) -> tree (element or spacer)
    5. tree(element) -> element
-}

createElements : Tree (Signal String) -> Tree (Signal Element)
createElements spec =
    let topLevel : Element -> Element
        topLevel elem = color lightCharcoal
                     <| container (widthOf elem + 10) (heightOf elem) middle elem

        --Needed because `maximum` errors on the empty list
        maxOrZero : [Int] -> Int
        maxOrZero list = case list of
            [] -> 0
            _ -> maximum list

        subLevels : [Tree (Signal Element)] -> [Tree (Signal Element)]
        subLevels tree =
            let elems : [Signal Element]
                elems = map treeData tree

                maxWidth : Signal Int
                maxWidth = lift (\e -> maxOrZero <| map widthOf e) (combine elems)

                addContainer : Int -> Element -> Element
                addContainer w e = color lightCharcoal
                                <| container (w + 5) (heightOf e) topLeft e

                makeTree : Tree (Signal Element) -> Tree (Signal Element)
                makeTree t = Tree (lift2 addContainer maxWidth <| treeData t)
                                  (subLevels <| treeSubtree t)
            in map makeTree tree
        
        allLevels : Tree (Signal Element) -> Tree (Signal Element)
        allLevels t = Tree (lift topLevel <| treeData t)
                           (subLevels <| treeSubtree t)
    in allLevels <| treeMap (lift plainText) spec

--Creates a signal with the element and its associated hover information
extractHoverInfo : Tree (Signal Element) -> Signal (Tree (Element, Bool))
extractHoverInfo elements =
    let makeNode (x, y) = lift2 (,) x (delayFalse y)
        elementsHover = treeMap (makeNode . hoverablesSig) elements
    in extractTreeSignal elementsHover

{- Takes in the element and the hover information. Returns the same element and
   whether or not it should be displayed on the screen.

   Invariant: At most one of the input booleans is true (since only one element
   can be hovered upon at a time). -}
isOnScreen : Tree (Element, Bool) -> Bool
isOnScreen t =
    let hovering : Tree (Element, Bool) -> Bool
        hovering = snd . treeData

        anyChild = or <| map hovering <| treeSubtree t
        anyGrandchildren = or <| map isOnScreen <| treeSubtree t
    in or [hovering t, anyChild, anyGrandchildren]

{- Renders the top level menu and all of its submenus -}
renderTree : [Tree (Element, Bool)] -> Element
renderTree menu =
    let children : Tree (Element, Bool) -> [(Element, Bool)]
        children t = map treeData <| treeSubtree t

        horizontalSpacer : Element -> Element
        horizontalSpacer elem = spacer (widthOf elem) 1

        colorIfHighlighted : (Element, Bool) -> (Element, Bool)
        colorIfHighlighted (elem, high) = if high
                                          then (color lightBlue elem, high)
                                          else (elem, high)

        --TODO: work with depth > 2
        renderSubmenu : Tree (Element, Bool) -> Element
        renderSubmenu submenu =
            if isOnScreen submenu
            then flow down <| map fst <| children submenu
            else horizontalSpacer <| fst <| treeData submenu
        
        flowLevel : [Element] -> Element
        flowLevel = flow right

        --TODO: add spacing between the elements
        renderTopMenu : Element
        renderTopMenu =
            let highlights = map (treeMap colorIfHighlighted) menu
            in flow down [flowLevel <| map (fst . treeData) highlights, 
                          flowLevel <| map renderSubmenu highlights]
    in renderTopMenu

renderSpec : [Tree (Signal String)] -> Signal Element
renderSpec t =
    let elements : [Signal (Tree (Element, Bool))]
        elements = map (extractHoverInfo . createElements) t

        rendered : [Tree (Element, Bool)] -> Element
        rendered tree = renderTree tree
    in lift rendered <| combine elements

menuSpec : [Tree String]
menuSpec = [Tree "Main" [leaf "About", leaf "Updates"],
            Tree "File" [leaf "New", leaf "Open"]]

main = renderSpec <| map (treeMap constant) menuSpec

