# Write the pull request

On GitHub this text is what a maintainer reads first. A good description saves everybody time and makes a quick merge likely.

## What a good pull request says

- **What** changed, in one or two sentences.
- **Why**: which issue it solves (`Fixes #2` closes the issue automatically when the pull request is merged).
- **How you tested** it, so the reviewer can repeat it.
- A **checklist** that shows you followed the project's rules. Tick only what is true.

## Do it

Stay on your `fix/issue-2-...` branch. Copy the template and open the copy:

```
cp PULL_REQUEST_TEMPLATE.md PULL_REQUEST.md
```

On Windows PowerShell use `copy PULL_REQUEST_TEMPLATE.md PULL_REQUEST.md`.

Edit `PULL_REQUEST.md`:

- Write real sentences under What, Why and How I tested.
- Put `Fixes #2` in the Why section.
- Delete the instruction comments: the lines of the template that begin with an angle bracket and two dashes. They are invisible on GitHub but they are noise in your file, and the check looks for them.
- Tick the checklist boxes that are true, like this: `- [x]`.

Commit it, so it travels with the branch:

```
git add PULL_REQUEST.md
git commit -m "docs: add the pull request description (#2)"
```

## Tips from maintainers

- Do not write "fixed bug". Say which bug and how it looked.
- Screenshots or command output help a lot.
- If you are unsure, say so. "I was not sure about X, what do you think?" is a good sentence.

## What is being checked

- All four sections of the template are present and filled in with sentences.
- The instruction comments are removed.
- It contains `Fixes #2`.
- At least three checklist items are ticked.
- You are still on the issue 2 branch.

When you are ready, press **Check my work**.
