module SignalTricks where
import Graphics.Input (hoverables, customButtons)

hoverablesJoin : Signal Element -> (Signal Element, Signal Bool)
hoverablesJoin elem =
    let pool = hoverables False
    in (lift (pool.hoverable id) elem, pool.events)

clicksJoin : Signal Element -> (Signal Element, Signal ())
clicksJoin elem =
    let pool = customButtons ()
    in (lift3 (pool.customButton ()) elem elem elem, pool.events)

delayFalse : Signal Bool -> Signal Bool
delayFalse b = lift2 (||) b <| delay millisecond b

