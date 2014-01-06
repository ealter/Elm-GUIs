Elm-GUIs
========

Our Comp 150-FP final project. The final written product is `PAPER.pdf`. Links
to live demos of code are below.

Running the Code
================
    cd src
    elm-server

All of the source code can be found in the `src` directory. The `src/menus`
directory has the various menu examples we created using the `Menu` and `Tree`
module.
* (`main.elm`)[http://ealter.github.io/Elm-GUIs/src/build/menus/main.html]: This is a standard menu with a few nested directories.
* (`dynamic.elm`)[http://ealter.github.io/Elm-GUIs/src/build/menus/dynamic.html]: This shows off a menu with non-constant strings. Certain parts
   of the menu change on keyboard strokes and mouse clicks.
* (`indexes.elm`)[http://ealter.github.io/Elm-GUIs/src/build/menus/indexes.html] looks just like `main.elm` except it tests the `stringsAgain`
   and `treeAtPath` functions.
* (`maybeBlank.elm`)[http://ealter.github.io/Elm-GUIs/src/build/menus/maybeBlank.html] tests how the code handles blank strings. This one
  demonstrates a bug in the hoverable detection of elm.
* (`clicks.elm`)[http://ealter.github.io/Elm-GUIs/src/build/menus/clicks.html] demonstrates detecting clicks.

The path to the main menu is `/menus/main.elm`

