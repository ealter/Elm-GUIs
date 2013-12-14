Dynamic Hover Detection  
Attempts to Create GUIs in Elm

Abstract

The language Elm was designed to be a practical application of Functional
Reactive Programming (FRP) to create Graphical User Interfaces (GUIs). We
attempted to create a menu bar as commonly seen on desktop operating systems,
and quickly discovered an apparent incompatibility between Elm's mouse-hover
detection primitive and the constraints of the language. This concern only
surfaces when dealing with highly dynamic data. We present a non-obvious
technique to address the issue without modifying the Elm compiler. It
generalizes to other functions in Elm's `Graphics.Input` library, which includes
(besides hover detection) GUI mainstays such as buttons, checkboxes, and text
fields. We also contribute techniques for the representation and display of
menus in Elm, and contrast our work with an existing Elm web application.

#Introduction
Elm was introduced in March 2012 in Evan Czaplicki's senior thesis, *Concurrent
FRP for GUIs*. He and his adviser, Stephen Chong, published *Asynchronous FRP
for GUIs* at PLDI 2013. Both papers are comprehensive overviews of Elm, and
additionally provide excellent literature reviews of previous FRP GUI endeavors,
of which there are several.

We chose menus as an example GUI to implement in Elm. The particular design
places the top-level menu at the top of the screen, similar to Mac OS X and many
Linux distributions, with selections coming down from the top. Menus extend when
the top-level item is hovered upon, and remain extended while the mouse hovers
over any item in the menu. Therefore it is necessary to know hover information
about each menu item. This time-varying information is also used to detect
selections upon click and highlight the moused-over item. It is simple to do
this when the hover-detecting area is constant. Our paper describes the much
more difficult task of managing time-varying hover information about
time-varying areas.

There are two features of Elm we are deliberately avoiding. First is the
extensive raster drawing library, `Graphics.Collage`. Dynamic hover detection is
not problematic when using this library because it can be done purely through
manual collision detection. However, if we used this library, our GUI would be a
single raster animation and not a DOM tree. Secondly, the `Graphics.Input`
library contains wrappers around HTML checkboxes and dropdowns. We consider
creating GUIs with these to be uninteresting and wanted to persue something more
general. This led to the choice of an interface typically found in the operating
system rather than the browser. We do refer to the native GUI constructs to show
how the technique we develop for hovering generalizes, as the API for buttons
and hover detection is very similar.

It is difficult for the authors to assess what level of knowledge should be
assumed on the part of the reader. Firstly, readers will range from Elm's
creators and experienced users, who are already familiar with its restrictions
and standard libraries, to those with no FRP background, who need an
introduction to signals. Secondly, while we have found no prior discussion on
either the problem we identify nor its solution, we cannot know for certain that
either are novel. We continue in the hopes of presenting new and non-trivial
techniques to the Elm community.

We contribute:

* The identification of an apparent limitation in Elm's hover detection library,
 solved by a non-trivial usage pattern that does not require modifications to
 the Elm compiler or runtime, and that generalizes to other functions in
 `Graphics.Input`.
* An implementation of desktop-style menu in Elm, which incorporates several
 noteworthy "tricks" as well as general style practices.
* An analysis of TodoFRP, the current state-of-the-art in dynamic Elm GUIs. We
 demonstrate how it operates in the absence of our technique, and how it could
 operate in its presence.

<!-- TODO: when we do LaTeX, make sure these are actually section references -->
Section 2 introduces Elm, signals, and the prohibition on signals of signals. It
is targeted to readers familiar with functional programming but not FRP, and may
be skipped by those already familiar with Elm. Section 3 presents a first
attempt at a menu and details the issue we encountered. Section 4 presents Elm's
hover detection for DOM elements and how it can be extended to meet our needs.
Section 5 explains our menu implementation in detail. Section 6 analyzes
TodoFRP. Section 7 concludes with a notice to the Elm community.

Sentences that need a home:
We have opted for clarity and thoroughness over brevity.  
This paper uses both general, theory-bound techniques and practical hacks to
achieve its goals.  
Elm compiles down to JavaScript to run in the browser. Executing Elm programs
requires the compiled code as well as `elm-runtime.js` which is included with
the compiler.

# Elm for Functional Programmers

A typical functional program is *transformative*: all input is available at the
start of execution, and after a hopefully finite amount of time the program
terminates with some output. In contrast, Elm programs are *reactive*: not all
input is available immediately and the program may indefinitely adjust output
with each input. In simple programs, the inputs at a given time fully determine
the output. More complex programs will take advantage of Elm's ability to
remember state.

## Signals: Time-varying values

A time-varying value of a polymorphic type `a` is represented by `Signal a`. For
example, the term `constant 150` has type `Signal Int`. The combinator
`constant` creates a signal whose value never changes. A more interesting signal
is the primitive `Window.dimensions : Signal (Int, Int)`. This signal represents
the browser window size and updates whenever it is resized. Signals are
asynchronous in that they update at no set time, just as the window may remain
the same size idefinitely. Signals update in discrete events, but are continuous
in the sense that they are always defined.

The function `lift` allows us to execute a pure function on a signal of inputs,
producing a signal of outputs. (Although lifting is a general functional
concept, in Elm it has only this meaning.)

````
lift : (a -> b) -> Signal a -> Signal b
````

For example, we can multiply the width and height of the window together to find
its area.

````
area : Signal Int
area = lift (uncurry (*)) Window.dimensions
````

In this case, the lifted function is multiplication, uncurried as to operate on
pairs. As the Window library exposes width and height as both a pair and
individually, we can also write `area2 = lift2 (*) Window.width Window.height`.

We can print the current area to the screen with `main = lift asText area`. The
primitive `asText : a -> Element` renders almost anything into an Element,
which represents a DOM element. **Footnote** *Those following along in an Elm
compiler, such as the one available at `elm-lang.org/try`, should add `import
Window` to the top of the file.*

The signals in an Elm program can be thought of as a Directed Acyclic Graph
(DAG). Many signals depend on other signals for their output. For example, the
`area` signal depends on `Window.dimensions` signal. Similarly, the `area2`
signal depends on both the values of the `Window.width` and the `Window.height`
signals. When an event is fired on a signal, it propogates down the DAG to all
signals who depend on that signal and the outputs of those signals are
reevaluated.

## Remembering State

Signals can remember state by using the `foldp` combinator. Familiar list
folds apply a binary operation of an element and an accumulator to produce a new
accumulator, over each list element in sequence. Folding from the *past*
operates on all of the values of a signal as they occur and produces a signal of
the accumulator.

````
foldr : (a -> b -> b) -> b -> [a]      -> b
foldp : (a -> b -> b) -> b -> Signal a -> Signal b
````

When the event signal updates, a pure function is called with the new event and
the old accumulator (a default is supplied), producing a new accumulator that is
the new value of the output signal. For example, `foldp max 0 Window.width` is a
signal of the maximum width ever obtained by the window. With `foldp`, it is
possible to create signals that depend on every event to ever occur on a signal.
However, most folded functions do not store every value explicitly (cons is an
exception) and space can be saved by remembering only the accumulator.

## No Signals of Signals

The ability to create a signal dependent on past state has a potentially
disastrous implication for space performance. Czaplicki and Chong explain the
preventive measure and the problem:

> The type system rules out programs that use signals of signals, for the
following reason. Intuitively, if we have signals of signals, then after a
program has executed for, say 10 minutes, we might create a signal that (through
the use of `foldp`) depends on the history of an input signal, say
`Window.width`.

That is, we can define a clock that measures the amount of time since program
execution began:

````
clock : Signal Time
clock = foldp (+) 0 (fps 10)
````

The `fps n` combinator produces a signal of the time elapsed since its last
event, updated `n` times a second. We sum these deltas starting with zero. Then
we create a function from a time to one of two signals, one of which is trivial
and one of which depends on the history of `Window.width`:

````
switcher : Time -> Signal Int
switcher t = if t < 10*minute
             then constant 0
             else foldp max 0 Window.width
````

We could, were the type system not principled on disallowing it, create

````
switched : Signal (Signal Int)
switched = lift switched clock
````

Why is this problematic? Czaplicki and Chong continue,

> To compute the current value of this signal, should we use the
entire history of `Window.width`? But that would require saving all history of
`Window.width` from the beginning of execution, even though we do not know
whether the history will be needed later. Alternatively, we could compute the
current value of the signal just using the current and new values of
`Window.width` (i.e., ignoring the history). But this would allow the
possibility of having two identically defined signals that have different
values, based on when they were created. We avoid these issues by ruling out
signals of signals.

<!--This paragraph feels duplicative-->
That is, in order to have both state and signals of signals, the program must
either remember indefinitely every event to ever occur, so that a newly created
signal can use them, or tolerate signals that vary based only on when they were
created, losing referential transparency. Elm's creators declined either option
and disallowed signals of signals.

To a reader familiar with Haskell, this means signals are functors (and in fact
applicative functors) but not monads, as monads support the following operation:

````
join :: Monad m => m (m a) -> m a
````

Such an operation for signals would condense a `Signal (Signal a)` into a mere
`Signal a`, but it cannot exist in general.

#A Naïve Menu
A menu can be thought of as an instance of a tree

````
data Tree a = Tree a [a]
````

Because the look-and-feel of submenus can change dynamically (such as
highlighting on mouse hovering), menus cannot simply be represented with type
`Element`. Therefore, every submenu can be represented as a `Signal Element`.
Because we need to detect hover information about each submenu, our menu data
type becomes

`type Menu = Tree (Signal Element, Signal Bool)`.

When an Element is hovered upon, its submenu needs to be displayed in the GUI. A
naïve implementation would create a function with the following type signature:

`displaySubmenu : Bool -> Signal Element`

However, if we try to `lift` this function on a value of type `Signal Bool`, we
get a signal of signals (of Elements). Therefore, with this implementation, it
is impossible to display dynamic elements in response to the `hoverable` signal.

# Detecting Hover Information

Elm provides a function to obtain the hover information from an Element.

````hoverable : Element -> (Element, Signal Bool)````

The returned Element is visually identical to argument, but now detects hover
information. The signals of Booleans reflects the hover status of the this
Element, not the original. This function works well when the Element is pure
(not a signal). However, when we try to lift it, we get

````lift hoverable : Signal Element -> Signal (Element, Signal Bool)````

Although it may not appear to be so at first, the result type is a signal of
signals. It is possible to transform the result into `Signal Signal (Element,
Bool)`, but a more mentally convenient type is `(Signal Element, Signal Signal
Bool)`. There does not exist a general join function to operate on the `Signal
Signal Bool`. However, it is possible to implement the following function:

````hoverableJoin: Signal Element -> (Signal Element, Signal Bool)````

It is done using the more general `hoverables` (note the plural) primitive, of
the following type:

````
hoverables : a -> { events : Signal a,
                    hoverable : (Bool -> a) -> Element -> Element }
````

The polymorphic `a` type can serve as an identifier. The first value supplies
the default value of `events` (signals must always be defined and so a default
value is required). The returned record includes the `events` signals and the
`hoverable` function, which in general may be applied multiple times so that
multiple elements report on `events`. The `(Bool -> a)` is used to identify
which Element experienced the event; a common use is `a = (Int, Bool)` where the
integer identifies the Element and the Bool is the event. Additionally,
`hoverables` is used to implement `hoverable`:

````
hoverable : Element -> (Element, Signal Bool)
hoverable elem =
    let pool = hoverables False
        in  (pool.hoverable id elem, pool.events)
````

It ignores the polymorphism (`a = Bool`) and instead create a Boolean signal
that is originally false and use the identity function to not alter the
hoverable information. With a simple change, we can create a function that acts
on `Signal Element` instead of `Element`:

````
hoverablesJoin : Signal Element -> (Signal Element, Signal Bool)
hoverablesJoin elem =
    let pool = hoverables False
    in (lift (pool.hoverable id) elem, pool.events)
````

Notice that `pool.hoverable` is partially applied to `id` purely,
and then lifted on to the argument. This is possible, utlimately, because
`pool.hoverable` is pure.

Just how novel is this small, but hugely significant change? The
[documentation](http://docs.elm-lang.org/library/Graphics/Input.elm#hoverables)
for `hoverables` states that it allows users to "create and destroy elements
dynamically and still detect hover information," but gives no further indicators
on how to do so. Though the Elm website is full of examples, there are none for
either `hoverable` or `hoverables`. Moreover, in the [mailing list
post](https://groups.google.com/d/msg/elm-discuss/QgowLy5jdhA/CZQfjkbjMsEJ) that
introduced these functions, Czaplicki said that "`hoverables` is very low level,
but the idea is that you can build any kind of nicer abstraction on top of it."
We have done just that.

When a element changes, `hoverablesJoin` attaches the same hovering signal to
the new element. If we were to display both the old and the new elements on the
screen, hovering over either would trigger the signal.

More dangerously, it becomes easy to create an infinite loop. Suppose an Element
shrinks on hover. Suppose the cursor hovers on the Element, which is then
replaced by a smaller Element, so the cursor is no longer hovering on the
Element. Then the original Element is put back, but is now being hovered on!
This condition manifests itself as flickering between the two Elements. It is
unavoidable in any language or system that allows hover targets to change size
in response to hover events.
<!-- Maybe put the code for this example in the appendix? -->

## Generalized joins on `Graphics.Input`

#Implementing Menus

*Note: Here are some various paragraphs without order*  
*Yeah, really. Some good pieces but it needs a structure.*

Using `hoverablesJoin`, we created a structure of type
`Tree (Signal Element, Signal Bool)` to represent our menus.
Using the combinator `combine : [Signal a] -> Signal [a]`, we were able to turn
this structure into a `Signal (Tree (Element, Bool))`. Once we had that
structure, we could render the menu using a pure function from
`Tree (Element, Bool) -> Element` and then lift it. Similarly to limiting the
use of the IO monad in Haskell code, it is advantageous to limit the use of
signals in Elm code.

Our first trick was to replace submenus not shown on the screen with spacers. A
spacer is simply a blank rectangle with a specified with and height
(`spacer : Int -> Int -> Element`). For every menu item, we create both the
menu Element and a spacer. The spacer has the same width as the Element, but a
height of 1. We then switch between menu and the spacer based on hover
information. This helped in two ways. First of all, it allowed us to choose
between two options without creating a signal of signals. Secondly, the spacer
helped to align the submenu with its parent element.

<!-- Do you describe the race condition anywhere? Also I think it's part of the
problem and not languager or implementation -dependent. -->
Our second trick fixed a race condition. A submenu was rendered to the screen if
one of three conditions was met: the mouse was hovering upon its parent, the
mouse was hovering upon it, or the mouse was hovering upon any of its
descendents. As the mouse moved from the parent to the child, the child was
often replaced with a spacer before it could detect that the mouse was hovering
over it. To fix this problem, we created the following function:

<!-- I think this can have a better name, maybe `extend`? -->
````
extend : Signal Bool -> Signal Bool
extend b = lift2 (||) b (delay millisecond b)
````

`extend` makes a `Signal Bool` wait a millisecond to transition from True to
False. By applying this function to every hovering Boolean in the Menu
structure, we gave the mouse time to move from a menu Element to its submenu
before that submenu disappeared.

Interestingly enough, we were able to implement menus without explicitly storing
the state of the menu. There are two ways to remember state in Elm code:
`foldp`, or Elm's implementation of Arrowized FRP known as `Automaton`. However,
in our implementation we use the current browser DOM state to remember our
state. Instead of storing the menu currently being displayed on the screen, we
can derive it based on which Element (if any) the mouse is currently hovering
over. The elimination of state from our code allows it to be much cleaner.

Note that the input to our menu is a `Tree (Signal String)`, but not a `Signal
(Tree String)`. We are able to map from
`Signal Element -> (Signal Element, Signal Bool)`, but not from
`Element -> (Element, Bool)`. Therefore, if we tried to turn a `Signal (Tree
String)` into a `Signal (Tree (Element, Bool))`, we would need to lift an
impossible hoverable function of type `Element -> (Element, Bool)` on each
element. Therefore, each individual menu element can contain dynamic
information, but the menu structure must be static. We can, in practice, get
around this restriction by creating a tree that is larger than necessary and
filling the unused nodes with empty string, which our implementation handles
appropriately. <!-- Right? -->

A possible solution for that issue would be to write a function of type
`Signal (Tree a) -> Tree (Signal a)`. Although the `combine` combinator can turn
a list of signals into a signal of lists, there isn't an inverse to turn a
signal of lists into a list of signals. It is impossible to write the function
`split : Signal [a] -> [Signal a]` because the size of the list in the input is
dynamic, whereas the size of the output list is static. Since the `Tree` data
structure contains lists, it is therefore impossible to write a function of type
`Signal (Tree a) -> Tree (Signal a)`.

#Related Work: TodoFRP

We examine [TodoFRP](https://github.com/evancz/TodoFRP), a simple Elm web app
created by Czapliki, to both pinpoint the problem and show its universality.
TodoFRP is the current state-of-the-art in highly reactive Elm GUIs. It provides
examples of different levels of reactivity, a familiar context for Elm veterans,
and a few dirty tricks of its own.

TodoFRP presents the user with a text field asking, "what needs to be done?".
Entered todo entries become DOM elements, which can be deleted with a "x"
button, also a DOM element. The button is implemented using the `Graphics.Input`
function  

```` customButtons : a -> { events : Signal a,  
                      customButton : a -> Element -> Element -> Element -> Element }````

Notice the similarity with `hoverables`. Each call of `customButton` provides
the identifier event when the button is clicked, and three (pure) Elements to
display: one normally, one on hover, and one on click. The result is an
`Element`, not a `Signal Element`, that nevertheless changes among those three in
response to the mouse. This is possible because the result Element's dimensions
are taken to be the maximum of the three inputs' dimensions. Even if the
Elements have different sizes, the resulting element and therefore the
hover surface remains fixed in size.

In the case of TodoFRP, these Elements are diferent colors of the "x" and the
same for each todo entry. The polymorphic `a`s are unique identifiers
(ascending integers) for each entry.

The todo label Elements are dynamic and do not detect hover information. The
button Elements that do detect hover information are known statically. Without
`hoverablesJoin`, it would be impossible to dismiss a todo by clicking on its
text label.

#Conclusion: To the Elm Community
"of service"

It's true that we've used the hoverables function in a way that it was
(probably) never meant to be used, and there are some caveats involved in doing
so. Many small GUIs do not require dynamic, hover-detecting elements. However,
most large mouse-based GUIs do, and creating them in Elm will necessarily
encounter the obstacles we have described.

Although we have implemented all of this without language modifications, it is
hoped that as the community becomes more familiar with functional GUIs, new
libraries are added to incorporate some of our tricks, or even make them
unnecessary.

##Acknowledgements
We would like to thank Evan Czaplicki and Stephen Chong for creating Elm, and
the Elm community for growing it. We thank Norman Ramsey for his guidance
through functional programming, and our paper reviewers, ...  .

##References
