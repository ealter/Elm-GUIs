import open Tree
import open Menu

menuSpec : [Tree String]
menuSpec = [Tree "Main" [leaf "About", leaf "Updates"],
         Tree "File" [leaf "New", leaf "Open"]]

main = renderMenu <| map (treeMap constant) menuSpec

