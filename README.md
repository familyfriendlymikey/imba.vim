# vim.imba

I wanted to see how easy it would be to make a
TUI text editor with very basic functionality,
and it turns out it's as easy as <200 lines of code.

There are probably bugs.
The bugs I have noticed have to do with redrawing being async or something,
but since I'm not actually going to implement an editor in JS, I'm not going to fix that.

I have the following implemented:

Normal Mode Key | Function
-|-
hjkl | left down up right
i | enter insert mode
w | save and quit
q | force quit

Insert Mode Key | Function
-|-
esc | enter normal mode
backspace | works fine
return | works fine

## Useful Resources
- [Wish I found this blog post earlier](http://xn--rpa.cc/irl/term.html)
- [Wikipedia list of unicode character keycodes](https://en.wikipedia.org/wiki/List_of_Unicode_characters)
- [List of escape codes](https://espterm.github.io/docs/VT100%20escape%20codes.html)
- [I didn't use this TUI text editor tutorial, but it might be useful](https://viewsourcecode.org/snaptoken/kilo/04.aTextViewer.html)
