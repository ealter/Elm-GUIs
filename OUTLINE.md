# Signals Aren''t Monads: Failed Attempts to Create GUIs in Elm

## Abstract


## Literature Review
### Functional GUIs
* [eXene](http://alleystoughton.us/eXene/1993-trends.pdf) (1993)
* [Functional Reactive Animation](http://conal.net/papers/icfp97/icfp97.pdf) (most influential paper of ICFP97)
 * Allowed for future-dependent programs - interesting to trace trend of narrowing what is allowed
* [FranTk](http://pdf.aminer.org/000/310/109/frantk_a_declarative_gui_language_for_haskell.pdf) (ICFP00)
* Fruit (2001)
* [Yampa/Animas](http://www.haskell.org/haskellwiki/Yampa) (2008)
* [Flapjax](http://www.cis.upenn.edu/~mgree/papers/oopsla2009_flapjax.pdf) (OOPSLA09)
* [Reactive-Banana](http://www.haskell.org/haskellwiki/Reactive-banana)(2011)
* Elm (2012) (move to next section?)

### GUIs of the 1990s
What are we aiming for? What is a GUI?

## Elm overview
Including distinguishing between the canvas world and the DOM world

## Signals for Category Theorists
Signals are Applicative Functors  
Monads support join  
Signals do not support join (why)  

## Our work
Monadic combinators to create menus  
Hoverables: why it sucks, why we cannot do better  
Other `a -> Signal b` functions  

... other sections ...

## Conclusion
