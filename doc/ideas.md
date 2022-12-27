*
USE SELECTION to find next match

M
select between ()[]{}<>""'', and then
if you press `M` again, select outer?
must account for text objects like tags, such as <div></div>
so M automatically expands the selection continuously, alternating
between inner and outer?

m
select only (surround chars),
then the user can use normal editing commands
on those selections, like r or x
but it won't work because if you do r( it'll both be (
ms' should add ' around selection?

for listchars, just use arbitrary regex for replacements.
That's how we'll also implement tabs, using visual replacements?

only connect yanks to the system register, not deletions
or changes

s
surround selection with character?

:e test/whatever
edit file relative to project location

:e ./test/whatever
edit file relative to current buffer
