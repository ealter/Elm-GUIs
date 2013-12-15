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

oneTree : Tree String
oneTree = Tree " " menuSpec

onlyJust : Maybe a -> a
onlyJust a = case a of
                  Just b -> b

--main = renderMenu <| map (treeMap constant) indexes
(menu, clickPath) = renderMenu <| map (treeMap constant) menuSpec

stringPath : Signal [String]
stringPath = lift (\p -> onlyJust <| treeAtPath oneTree p) clickPath

clickString : Signal Element
clickString = lift (\p -> plainText <| "You clicked: " ++ show p) stringPath

main = lift (flow down) (combine [clickString, menu])


