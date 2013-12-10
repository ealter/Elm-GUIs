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

onlyJust : Maybe a -> a
onlyJust a = case a of
                  Just b -> b

stringsAgain : Tree String -> Tree String
stringsAgain tree = treeMap (show . onlyJust . treeAtPath tree) (treeGetPaths tree)

indexes : [Tree String]
indexes = map (\s -> treeMap show <| treeGetPaths s) menuSpec

--main = renderMenu <| map (treeMap constant) indexes
main = renderMenu <| map (treeMap constant . stringsAgain) menuSpec

