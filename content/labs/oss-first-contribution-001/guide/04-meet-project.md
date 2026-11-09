# Meet the project

Before you change anything in a real project, you **look around**. Do this now. It is the habit that separates a good contributor from a risky one.

## 1. Open a terminal in this folder

In VS Code press `` Ctrl+` `` (the backtick key). You should be inside the lab folder. Check:

```
ls
```

You should see `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `src`, `tests` and `issues`.

## 2. Install the test tool

The checks and the project tests use pytest.

```
python3 -m pip install pytest
```

If your system refuses with `externally-managed-environment`, use your system's package instead, for example `sudo apt install python3-pytest` on Ubuntu, or create a virtual environment with `python3 -m venv .venv`.

On Windows use `py -m pip install pytest`.

## 3. Read the rulebook

Open `CONTRIBUTING.md` and read all of it. It has seven short rules. Almost every check in this lab is one of those rules, so you will not be surprised later.

## 4. Look at the issues

Open the three files in the `issues` folder:

- **Issue 1:** `slugify` leaves extra hyphens. A bug.
- **Issue 2:** `truncate_words` keeps one word too many. A bug that needs a test.
- **Issue 3:** the README has a wrong install name and a wrong example. Documentation.

## 5. Run the tests and see the problem yourself

```
python3 -m pytest
```

Two small tests pass. They do not cover the bugs, which is exactly why the bugs exist. Reproduce issue 1 in the Python prompt:

```
python3 -c "import sys; sys.path.insert(0, 'src'); from pyslug import slugify; print(slugify('Hello, World!'))"
```

You should see `hello--world-`. Never fix something you have not seen fail first.

## 6. Read the code

Open `src/pyslug/text.py`. It is only two short functions. Try to spot both bugs before you read the issues again.

This step has no check. When you have done these six things, go on to the next step.
