import Window
import Graphics.Input (hoverables)

--{{{ TREE
data Tree a = Tree a [Tree a]

leaf : a -> Tree a
leaf a = Tree a []

treeMap : (a -> b) -> Tree a -> Tree b
treeMap f (Tree x y) = Tree (f x) (map (treeMap f) y)

treeZipWidth : (a -> b -> c) -> Tree a -> Tree b -> Tree c
treeZipWidth f (Tree x1 y1) (Tree x2 y2) = Tree (f x1 x2) (zipWith (treeZipWidth f) y1 y2)

treeData : Tree a -> a
treeData (Tree d _) = d

treeSubtree : Tree a -> [Tree a]
treeSubtree (Tree _ t) = t

{- Converts a tree of signals into a signal of tree.
   TODO: Make this more readable. -}
extractTreeSignal : Tree (Signal a) -> Signal (Tree a)
extractTreeSignal (Tree sb ts) = 
    let recursed = combine <| map extractTreeSignal ts
    in (\b r -> Tree b r) <~ sb ~ recursed

--}}}

hoverablesSig : Signal Element -> (Signal Element, Signal Bool)
hoverablesSig elem =
    let pool = hoverables False
    in (lift (pool.hoverable id) elem, pool.events)

{- Steps:
    1. Signal tree of hover info
    2. bool tree -> [int]
    3. tree (element, bool hoverInfo) -> [int] -> tree (element, bool isOnScreen)
    4. tree (element, bool isOnScreen) -> tree (element or spacer)
    5. tree(element) -> element
-}

{- TODO: can this be made pure?
   TODO: create the containers -}
createElements : Tree (Signal String) -> Tree (Signal Element)
createElements = treeMap (lift plainText)

--Creates a signal with the element and its associated hover information
extractHoverInfo : Tree (Signal Element) -> Signal (Tree (Element, Bool))
extractHoverInfo elements =
    let combineTuple (x, y) = lift2 (,) x y
        elementsHover = treeMap (combineTuple . hoverablesSig) elements
    in extractTreeSignal elementsHover

{- Takes in the element and the hover information. Returns the same element and
   whether or not it should be displayed on the screen.

   Invariant: At most one of the input booleans is true (since only one element
   can be hovered upon at a time). -}
elementsOnScreen : Tree (Element, Bool) -> Tree (Element, Bool)
elementsOnScreen menu =
    let hovering : Tree (Element, Bool) -> Bool
        hovering = snd . treeData

        isOnScreen : Tree (Element, Bool) -> Bool
        isOnScreen t =
            let anyChild = or <| map hovering <| treeSubtree menu
                anyGrandchildren = or <| map isOnScreen <| treeSubtree t
            in or [hovering t, anyChild, anyGrandchildren]

    in Tree (fst <| treeData menu, isOnScreen menu)
            (map elementsOnScreen <| treeSubtree menu)

{- Renders the top level menu and all of its submenus -}
renderTree : [Tree (Element, Bool)] -> Element
renderTree menu =
    let children : Tree (Element, Bool) -> [(Element, Bool)]
        children t = map treeData <| treeSubtree t

        shouldRenderChildren : Tree (Element, Bool) -> Bool
        shouldRenderChildren m = or <| map snd <| children m

        horizontalSpacer : Element -> Element
        horizontalSpacer elem = spacer (widthOf elem) 1

        colorIfHighlighted : (Element, Bool) -> Element
        colorIfHighlighted (elem, high) = if high then color blue elem else elem

        --TODO: work with depth > 2
        renderSubmenu : Tree (Element, Bool) -> Element
        renderSubmenu submenu =
            if shouldRenderChildren submenu
            then flow down <| map colorIfHighlighted <| children submenu
            else horizontalSpacer <| fst <| treeData submenu
        
        --TODO: add spacing between the elements
        renderTopMenu : Element
        renderTopMenu = flow down [flow right <| map (fst . treeData) menu, 
                                   flow right <| map renderSubmenu menu]
    in renderTopMenu

renderSpec : [Tree (Signal String)] -> Signal Element
renderSpec t =
    let elements : [Signal (Tree (Element, Bool))]
        elements = map (extractHoverInfo . createElements) t

        rendered : [Tree (Element, Bool)] -> Element
        rendered tree = renderTree <| map elementsOnScreen tree
    in lift rendered <| combine elements

menus : [Tree String]
menus = [Tree "Main" [leaf "About", leaf "Updates"],
         Tree "File" [leaf "New", leaf "Open"]]

main = renderSpec <| map (treeMap constant) menus

