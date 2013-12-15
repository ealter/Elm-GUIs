module Menu (renderMenu) where

import Window
import Graphics.Input (hoverables)
import Mouse
import open Tree
import open SignalTricks

{- Steps:
    1. Signal tree of hover info
    2. tree (element, bool hoverInfo) -> tree (element, bool isOnScreen)
    3. tree (element, bool isOnScreen) -> tree (element or spacer)
    4. tree(element) -> element
-}

createElements : Tree (Signal String) -> Tree (Signal Element)
createElements spec =
    let topLevelWidth: Element -> Int
        topLevelWidth elem =
            if widthOf elem > 0
            then widthOf elem + 10
            else 0
                        
        topLevel : Element -> Element
        topLevel elem = color lightCharcoal
                     <| container (topLevelWidth elem) (heightOf elem) middle elem

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
                maxWidth = lift (\e -> map widthOf e |> maxOrZero) (combine elems)

                addContainer : Int -> Element -> Element
                addContainer w e = color lightCharcoal
                                <| container (w + 5) (heightOf e) topLeft e

                makeTree : Tree (Signal Element) -> Tree (Signal Element)
                makeTree t = Tree (lift2 addContainer maxWidth <| treeData t)
                                  (subLevels <| treeSubtree t)
            in map makeTree tree

        allLevels : Tree (Signal Element) -> Tree (Signal Element)
        allLevels t = Tree (topLevel <~ treeData t)
                           (subLevels <| treeSubtree t)
    in allLevels <| treeMap (lift plainText) spec

--Creates a signal with the element and its associated hover information
extractHoverInfo : Tree (Signal Element) -> Tree (Signal Element, Signal Bool)
extractHoverInfo =
    let makeNode (elem, hov) = (elem, delayFalse hov)
    in treeMap (makeNode . hoverablesJoin)

extractClickPaths : Tree (Signal ()) -> Signal [Int]
extractClickPaths elems =
    let paths : Tree (Signal [Int])
        paths = treeZipWith sampleOn
                            elems
                            (treeMap constant <| treeGetPaths elems)
        
        emptyClick : Signal [a]
        emptyClick = lift (\_ -> []) Mouse.clicks
    in merge (collapseTreeSignals paths) emptyClick

{- Takes in the element and the hover information. Returns whether or not its
   children should be displayed on the screen.

   Invariant: At most one of the input booleans is true (since only one element
   can be hovered upon at a time). -}
isOnScreen : Tree (Element, Bool) -> Bool
isOnScreen t =
    let hovering : Tree (Element, Bool) -> Bool
        hovering = snd . treeData

        anyChild = or <| map hovering <| treeSubtree t
        anyGrandchildren = or <| map isOnScreen <| treeSubtree t
    in or [hovering t, anyChild, anyGrandchildren]

{- Renders the top level menu and all of its submenus. Notice that this is a
   pure function (no signals). -}
renderTree : [Tree (Element, Bool)] -> Element
renderTree menu =
    let children : Tree (Element, Bool) -> [(Element, Bool)]
        children t = map treeData <| treeSubtree t

        horizontalSpacer : Element -> Element
        horizontalSpacer elem = spacer (widthOf elem) 1

        verticalSpacer : Element -> Element
        verticalSpacer elem = spacer 1 (heightOf elem)

        colorIfHighlighted : (Element, Bool) -> (Element, Bool)
        colorIfHighlighted (elem, high) = if high
                                          then (color lightBlue elem, high)
                                          else (elem, high)

        renderSubmenu : Tree (Element, Bool) -> Element
        renderSubmenu submenu = flow down <| map fst <| children submenu

        renderSubmenus : (Element -> Element) -> Tree (Element, Bool) -> Element
        renderSubmenus blank submenu =
            if isOnScreen submenu
            then flow right [ renderSubmenu submenu
                            , flow down
                                  <| map (renderSubmenus verticalSpacer)
                                  <| treeSubtree submenu
                            ]
            else blank . fst . treeData <| submenu

        renderTopMenu : Element
        renderTopMenu =
            let highlights = map (treeMap colorIfHighlighted) menu
                topLevel = map (fst . treeData) highlights
                nextLevel = map (renderSubmenus horizontalSpacer) highlights
            in flow down [ flow right topLevel
                         , flow right nextLevel
                         ]
    in renderTopMenu

renderMenu : [Tree (Signal String)] -> (Signal Element, Signal [Int])
renderMenu t =
    let hoverElements : [Tree (Signal Element, Signal Bool)]
        hoverElements = map (extractHoverInfo . createElements) t

        oneTree : Tree (Signal Element, Signal Bool)
        oneTree = Tree (constant <| spacer 1 1, constant False)
                       hoverElements

        clickPath : Signal [Int]
        clickPath = extractClickPaths <| treeMap (clicksFromHover . snd) oneTree

        signalPair : (Signal a, Signal b) -> Signal (a,b)
        signalPair (x,y) = lift2 (,) x y

        signalTrees : [Signal (Tree (Element, Bool))]
        signalTrees = map (\e -> extractTreeSignal <| treeMap signalPair e)
                          hoverElements
    in (renderTree <~ combine signalTrees, clickPath)

