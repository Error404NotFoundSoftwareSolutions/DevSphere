# Task: Write a new lab (Mode 1)

1. Copy `content/labs/python-hello-001/` to a new folder.
2. Edit `lab.yaml` following `docs/LAB_MANIFEST_SPEC.md`.
3. Write guide steps in `guide/`, starter project in `starter/`, visible tests in `tests/visible/`.
4. Put protected tests in `tests/protected/` and the reference solution in `reference/`. They stay in this private repository and the publish step never puts them in a bundle.
5. Run `uv run labcheck content/labs/<lab-id>`: schema, starter fails, reference passes, repeat runs stable.
6. Add a last-verified date for any third-party link.
