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
Elm was introduced in March 2012 in Evan Czaplicki's senior thesis, "Concurrent
FRP for GUIs". He and his advisor, Stephen Chong, published "Asynchronous FRP
for GUIs" at PLDI 2013. Both papers are comprehensive overviews of Elm, and
additionally provide excellent literature reviews of previous FRP GUI endeavors,
of which there are several.

We chose menus as an example GUI to implement in Elm. The particular design
places the top-level menu at the top of the screen, similar to Mac OS X and many
Linux distros, with selections coming down from the top. Menus extend when the
top-level item is hovered upon, and remain extended while the mouse hovers over
any item in the menu. Therefore it is necessary to know hover information about
each menu item. This time-varying information is also used to detect selections
upon click and highlight the moused-over item. It is simple to do this when the
hover-detecting area is constant. Our paper describes the much more difficult
task of managing time-varying hover information about time-varying areas.

There are two features of Elm we are deliberately avoiding. First is the
extensive raster drawing library, Graphics.Collage. Dynamic hover detection is
not problematic when using this library because it can be done purely on each
frame from the geometry. However, if we used this library, our GUI would be a
single raster animation and not a DOM tree. Secondly, the Graphics.Input library
contains wrappers around HTML checkboxes and dropdowns. While we refer to these
to show how the technique we develop for hovering genralizes, we avoid them when
constructing our menus.

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
 Graphics.Input.
* An implementation of desktop-style menu in Elm, which incorporates several
 noteworthy "tricks". Eliot, expand here please.
* An analysis of TodoFRP, the current state-of-the-art in dynamic Elm GUIs. We
 demonstrate how it operates in the absence of our technique, and how it could
 operate in its presence.

Section 2 introduces Elm, signals, and the prohibition on signals of signals. It
may be skipped by those already familiar with those topics. Section 3 presents a
first attempt at a menu and details the issue we encountered. Section 4 presents
Elm's hover detection for DOM elements and how it can be extended to meet our
needs. Section 5 analyzes TodoFRP. Section 6 explains our menu implementation in
detail. Section 7 concludes with a notice to the Elm community.

Sentences that need a home:
We have opted for clarity and thoroughness over brevity.
This paper uses both general, theory-bound techniques and practical hacks to
achieve its goals.

###Signals: Time-varying values
Elm: compilation, runtime, implementation details
State
No signals of signals
PLDI quote that's unclear
join

###A Naive Menu
Briefly, what is the problem we run in to? Why is this whole paper non-trivial?

Now that we've established basic knowledge of Elm, we can rephrase the
description of menus in terms of signals, and illustrate the a naive approach
encounters signals of signals.

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

TodoFRP presents the user with a text field. Entered text becomes a DOM element
which can be deleted with a "x" button, also a DOM element. The button is
implemented using the Graphics.Input function  

```` customButtons : a -> { events : Signal a,  
                       customButton : a -> Element -> Element -> Element -> Element }````

Notice the similarity with `hoverables`. Each call of `customButton` provides
the identifier event when the button is clicked, and three (pure) Elements to
display: one normally, one on hover, and one on click. The result is an
Element, not a Signal Element, that nevertheless changes among those three in
response to the mouse. This is possible because the result Element's dimensions
are taken to be the maximum of the three inputs' dimensions. Even if the
Elements have different sizes, the hover surface remains fixed in size (citation
needed, Eliot).

In the case of TodoFRP, these Elements are diferent colors of the "x" and the
same for each todo entry. The polymorphic `a`s are unique identifiers
(ascending integers) for each entry.

###Implementing Menus
Or however you want to present the actual menus. Your section, Eliot.
Three dirty tricks: spacers, ORing with parent, ORing with delay
State in the DOM, not foldp or Automatons, "Elm's implentation of Arrowized FRP"
How general?
If the menu structure is known statically, then it is possible to create menus
without hoverableJoin. However, in the general case menu structure is not known
statically, and may even change as the program executes, for example when a
different application becomes active. (Dynamic structure vs. dynamic strings?)

others sections....?

###Conclusion: To the Elm Community
"of service"
It's true that we've used the hoverables function in a way that it was
(probably) never meant to be used, and there are some caveats involved in doing
so. Many small GUIs do not require dynamic, hover-detecting elements. However,
most large mouse-based GUIs do, and creating them in Elm will necessarily
encounter the obstacles we have described.

Although we have implemented all of this without language modifications, it is
hoped that as the community becomes more familiar with functional GUIs, new
libraries are added to incorporate or obsolete some of our tricks.


###Acknowledgements
###References
