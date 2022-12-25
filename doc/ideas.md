*
USE SELECTION to find next match

m
select only (surround chars),
then the user can use normal editing commands
on those selections, like r or x
but it won't work because if you do r( it'll both be (
ms' should add ' around selection?

for listchars, just use arbitrary regex for replacements.
That's how we'll also implement tabs, using visual replacements?

