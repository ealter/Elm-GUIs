module Tree (Tree, leaf, treeMap, treeZipWith, treeGetPaths, treeData,
             treeSubtree, treeAtPath, extractTreeSignal) where
import open MaybeHelpers

data Tree a = Tree a [Tree a]

leaf : a -> Tree a
leaf a = Tree a []

treeMap : (a -> b) -> Tree a -> Tree b
treeMap f (Tree x y) = Tree (f x) (map (treeMap f) y)

treeZipWith : (a -> b -> c) -> Tree a -> Tree b -> Tree c
treeZipWith f (Tree x1 y1) (Tree x2 y2) = Tree (f x1 x2) (zipWith (treeZipWith f) y1 y2)

{- Creates a tree with the paths to each node -}
treeGetPaths : Tree a -> Tree ([Int])
treeGetPaths tree =
    let mapIndexes : Int -> [a] -> [(a, Int)]
        mapIndexes i list =
            case list of
                []      -> []
                x :: xs -> (x, i) :: mapIndexes (i + 1) xs

        applyTuple : (a -> b -> c) -> (a, b) -> c
        applyTuple f (a, b) = f a b

        treeGetPaths' : Tree a -> [Int] -> Tree ([Int])
        treeGetPaths' (Tree x xs) prefix = 
            let addPrefix : (a, Int) -> (a, [Int])
                addPrefix (a, i) = (a, i :: prefix)

                --TODO: add type annotation. Elm refuses the correct annotation?
                paths = map addPrefix <| mapIndexes 0 xs
            in Tree prefix <| map (applyTuple treeGetPaths') paths
    in treeMap reverse <| treeGetPaths' tree []

nth : Int -> [a] -> Maybe a
nth i list = maybeHead <| drop i list

recurseAtPath : [Int] -> Tree a -> Maybe [a]
recurseAtPath restOfPath node = maybeCons (treeData node)
                                    (treeAtPath node restOfPath)

revPath : Tree a -> [Int] -> Maybe [a]
revPath tree path =
    case path of
      []        -> Just [treeData tree]
      (x :: xs) -> maybeBind (recurseAtPath xs)
                             (nth x (treeSubtree tree))

treeAtPath : Tree a -> [Int] -> Maybe [a]
treeAtPath tree path = maybeMap reverse (revPath tree path)

treeData : Tree a -> a
treeData (Tree d _) = d

treeSubtree : Tree a -> [Tree a]
treeSubtree (Tree _ t) = t

{- Converts a tree of signals into a signal of tree. -}
extractTreeSignal : Tree (Signal a) -> Signal (Tree a)
extractTreeSignal (Tree sa ts) =
    let recursed = combine <| map extractTreeSignal ts
    in lift2 Tree sa recursed

