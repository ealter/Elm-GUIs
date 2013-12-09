module SignalTricks where
import Graphics.Input (hoverables)

hoverablesJoin : Signal Element -> (Signal Element, Signal Bool)
hoverablesJoin elem =
    let pool = hoverables False
    in (lift (pool.hoverable id) elem, pool.events)

delayFalse : Signal Bool -> Signal Bool
delayFalse b = lift2 (||) b <| delay millisecond b

