# Task: Change a requirement

1. Edit the requirement row in `docs/main/srs_v1.md` (never reuse an ID; a changed meaning gets a new ID).
2. Run `python tools/gen_rtm.py docs/main/srs_v1.md` to regenerate counts and the matrix.
3. Update the SAD section and `tools/make_backlog.py` story map, then run `python tools/check_docs.py`.
4. Add a `-01` test case; the test plan generator fails without it.
