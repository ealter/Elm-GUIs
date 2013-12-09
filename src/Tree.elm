module Tree where

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

{- Converts a tree of signals into a signal of tree. -}
extractTreeSignal : Tree (Signal a) -> Signal (Tree a)
extractTreeSignal (Tree sb ts) = 
    let recursed = combine <| map extractTreeSignal ts
    in lift2 Tree sb recursed

