import Graphics.Input (hoverable)

w = 50
(topRect, topHover) = hoverable <| color red <| spacer w 30
(bottomGreen, bottomHover) = hoverable <| container w 40 middle (color green <| spacer w 40)
bottomOrange = color orange <| spacer w 20

chooseBottom : Signal Element
chooseBottom = let
        hover: Signal Bool
        hover = lift2 (||) topHover bottomHover

        choose : Bool -> a -> a -> a
        choose b ifTrue ifFalse = if b then ifTrue else ifFalse
    in lift3 choose hover (constant bottomGreen) (constant bottomOrange)

main = lift (flow down) (combine [constant topRect, chooseBottom])