Elm-GUIs
========

Our Comp 150-FP final project. You can find the LaTeX in `paper/paper.tex`.

Running the Code
================
    cd src
    elm-server

All of the source code can be found in the `src` directory. The `src/menus`
directory has the various menu examples we created using the `Menu` and `Tree`
module.
* `main.elm`: This is a standard menu with a few nested directories.
* `dynamic.elm`: This shows off a menu with non-constant strings. Certain parts
   of the menu change on keyboard strokes and mouse clicks.
* `indexes.elm` looks just like `main.elm` except it tests the `stringsAgain`
   and `treeAtPath` functions.
* `maybeBlank.elm` tests how the code handles blank strings. This one
  demonstrates a bug in the hoverable detection of elm.

The path to the main menu is `/menus/main.elm`

