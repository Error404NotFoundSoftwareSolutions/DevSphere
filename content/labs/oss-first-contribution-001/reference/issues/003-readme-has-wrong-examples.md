# Issue #3: README shows the wrong install name and the wrong output

Labels: documentation, good first issue

## What happens

The README tells people to run `pip install pyslugg` (two g's, a package that does not exist) and says `slugify("Hello, World!")` returns `'hello_world'`.

## What should happen

The package is called `pyslug`, and the slug uses a hyphen, not an underscore. Fix both lines. Run the example yourself and copy the real output instead of guessing.
