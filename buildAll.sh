#!/bin/bash
cd src
elm -m *.elm menus/*.elm
cd build

fixElmRuntime() {
    file=$1
    temp=$(mktemp)
    regex='s/src=\".*elm-runtime.js\"/src=\"\/Elm-GUIs\/elm-runtime.js\"/g'
    sed "$regex" "$file" > "$temp"
    mv "$temp" "$file"
}

export -f fixElmRuntime

find . -name '*.html' -exec bash -c 'fixElmRuntime $@' _ {} \;

