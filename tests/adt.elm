import Graphics.Input (hoverable)
data Tree a = Tree a [Tree a]

treeData : Tree a -> a
treeData (Tree d _) = d

treeSubtree : Tree a -> [Tree a]
treeSubtree (Tree _ t) = t

nth : [a] -> Int -> a
nth xs c = head <| drop c xs

extractTreeSignal : Tree (Signal a) -> Signal (Tree a)
extractTreeSignal (Tree sb ts) = 
    let recursed = combine <| map extractTreeSignal ts
    in Tree <~ sb ~ recursed

rawElems = [hoverable <| color green <| spacer 40 40
          , hoverable <| color orange <| spacer 40 40
          , hoverable <| color blue <| spacer 40 40]

elems : [Signal Element]
elems = map (\(e, h) -> lift2 (\e b -> if b then color red e else e) (constant e) h) rawElems
n = nth elems

tree = Tree (n 0) [Tree (n 1) [], Tree (n 2) []]

tree2 = extractTreeSignal tree

displayTree : Tree Element -> Element
displayTree (Tree t ts) = flow down ([t] ++ (map treeData ts))

main = lift displayTree tree2

