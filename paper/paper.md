Dynamic Hover Detection
=======================
Attempts to Create GUIs in Elm
------------------------------

###Abstract

The language Elm was designed to be a practical application of Functional
Reactive Programming (FRP) to create Graphical User Interfaces (GUIs). We
attempted to create a menu bar as commonly seen on desktop operating systems,
and quickly discovered an apparent incompatibility between Elm's mouse-hover
detection primitive and the constraints of the language. This concern only
surfaces when dealing with highly dynamic data. We present a non-obvious
technique to address the issue without modifying the Elm compiler. It
generalizes to other functions in Elm's Graphics.Input library, which includes
(besides hover detection) GUI mainstays such as buttons, checkboxes, and text
fields. We also contribute techniques for the representation and display of
menus in Elm, and contrast our work with an existing Elm web app.

###Introduction
Why we're not doing a lit review: a brief history of Elm.

It is difficult for the authors to assess what level of knowledge should be
assumed on the part of the reader. Firstly, readers will range from Elm's
creators and experienced users, who are already familiar with its restrictions
and standard libraries, to those with no FRP background, who need an
introduction to signals. Secondly, while we have found no prior discussion on
either the problem we identify nor its solution, we cannot know for certain that
either are novel. We continue in the hopes of presenting new and non-trivial
techniques to the Elm community.

GUIs, why we chose menus.

There are two features of Elm we are deliberately avoiding. First is the
extensive raster drawing library, Graphics.Collage. Dynamic hover detection is
not problematic when using this library because it can be done purely on each
frame from the geometry. However, if we used this library, our GUI would be a
single raster animation and not a DOM tree. Secondly, the Graphics.Input library
contains wrappers around HTML checkboxes and dropdowns. While we refer to these
to show the generality of our technique, we avoid them when constructing our
menus.

Contributions, sections ahead.
We have opted for clarity and thoroughness over brevity.

###Signals: Time-varying values
State
No signals of signals
PLDI quote that's unclear

###A tour of Graphics.Input
Hoverable, hoverables, and the forum post
The similar type signatures

````hoverable : Element -> (Element, Signal Bool)````

````lift hoverable : Signal Element -> Signal (Element, Signal Bool)````

````lift hoverable (handwave) : Signal Element -> (Signal Element, Signal Signal
Bool)````

The result is a signal of signals, which are problematic for reasons previously
stated. There does not exist a general join function to operate on the Signal
Signal Bool. However, might it be possible to implement the following function
using less general techniques?

````hoverableJoin: Signal Element -> (Signal Element, Signal Bool)````

*Next sentence assumes we didn't get it working:* Surprisingly, hoverableJoin
can be implemented without modifying the Elm compiler, and in a way that is
sensible and type-correct -- but that does not work as desired.

hoverables
The Trick.
polymorphic ability that we don't use

With this power, it becomes easy to create an infinite loop. Suppose an Element
shrinks on hover. Suppose the cursor hovers on the Element, which is then
replaced by a smaller Element, so the cursor is no longer hovering on the
Element. Then the original Element is put back, but is now being hovered on!
This condition manifests itself as flickering between the two Elements. It is
unavoidable in any language or system that allows hover targets to change size
in response to hover events.

###Interlude: Analyzing TodoFRP

We examine [TodoFRP](https://github.com/evancz/TodoFRP), a simple Elm web app
created by Czapliki, to both pinpoint the problem and show its universality.
TodoFRP is the current state-of-the-art in highly reactive Elm GUIs. It provides
examples of different levels of reactivity, a familiar context for Elm veterans,
and a few dirty tricks of its own.

TodoFRP presents the user with a text field. Entered text becomes a DOM Element
which can be deleted with a "x" button. The button is implemented using the
Graphics.Input function  

```` customButtons : a -> { events : Signal a,  
                       customButton : a -> Element -> Element -> Element -> Element }````

Notice the similarity with `hoverables`. Each call of `customButton` provides
the identifier event when the button is clicked, and three (pure) Elements to
display: one normally, one on hover, and one on click. The result is an
Element, not a Signal Element, that nevertheless changes among those three in
response to the mouse. This is possible because the result Element's dimensions
are taken to be the maximum of the three inputs' dimensions. Even if the
Elements have different sizes, the hover surface remains fixed in size (citation
needed).

In the case of TodoFRP, these Elements are diferent colors of the "x" and the
same for each todo entry. The polymorphic `a`s are unique identifiers
(ascending integers) for each entry.

###Statically-known menus
Or however you want to present the actual menus. Your section, Eliot.
Three dirty tricks: spacers, ORing with parent, ORing with delay
State in the DOM, not foldp or Automatons, "Elm's implentation of Arrowized FRP"
How general?

others sections....?

###Conclusion: To the Elm Community
"of service"

###Acknowledgements
###References
