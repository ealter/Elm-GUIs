data TreeOfSig = TreeOfSig (Signal Bool) [TreeOfSig]
data Tree      = Tree              Bool  [Tree]

extract : TreeOfSig -> Signal Tree
extract (TreeOfSig sb ts) = let recursed = combine <| map extract ts
                            in (\b r -> Tree b r) <~ sb ~ recursed
