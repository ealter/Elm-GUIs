module MaybeHelpers where

maybeHead : [a] -> Maybe a
maybeHead xs = case xs of
                    []     -> Nothing
                    x :: _ -> Just x

{- The same as the maybe monad, with the first 2 parameters switched -}
maybeBind : (a -> Maybe b) -> Maybe a -> Maybe b
maybeBind f may = case may of
                      Nothing -> Nothing
                      Just a  -> f a

maybeMap : (a -> b) -> Maybe a -> Maybe b
maybeMap f = maybeBind (Just . f)

maybeCons : a -> Maybe [a] -> Maybe [a]
maybeCons x xs = maybeMap ((::) x) xs

