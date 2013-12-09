module SignalTricks where
import Graphics.Input (hoverables)

hoverablesSig : Signal Element -> (Signal Element, Signal Bool)
hoverablesSig elem =
    let pool = hoverables False
    in (lift (pool.hoverable id) elem, pool.events)

delayFalse : Signal Bool -> Signal Bool
delayFalse b = lift2 (||) b <| delay (0.05 * second) b

