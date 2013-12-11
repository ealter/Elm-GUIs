import open Tree
import open Menu

menuSpec : [Tree String]
menuSpec = [Tree "Main" [leaf "About",
                         leaf "Updates"],
            Tree "File" [leaf "New",
                         Tree "Foo" [leaf "Text",
                                     Tree "Phone" [leaf "bar",
                                                   leaf "baz"],
                                    leaf "Open"]]]

main = fst <| renderMenu <| map (treeMap constant) menuSpec

