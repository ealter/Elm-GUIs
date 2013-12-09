import Graphics.Input (hoverables)
import Mouse

hoverablesSig : Signal Element -> (Signal Element, Signal Bool)
hoverablesSig elem =
    let pool = hoverables False
    in (lift (pool.hoverable id) elem, pool.events)

(a, hov) = hoverablesSig (lift asText Mouse.position)

main = lift2 (\b e -> if b then color red e else color blue e) hov a
