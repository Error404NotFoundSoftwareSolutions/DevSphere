# Definition of done

- [ ] Branch named by the rule, based on the latest main
- [ ] Every listed test case passes in a clean run
- [ ] Full suite passes: `uv run ruff check .`, `uv run pytest`, `melos run check`, and `python tools/check_docs.py`
- [ ] `./start.sh` updated for any runtime/dependency/service changes and verified (`bash -n ./start.sh`)
- [ ] Protected tests untouched
- [ ] Docs updated (CHANGELOG, test plan record, ADRs if needed)
- [ ] Commits follow the message format, no secrets staged
- [ ] Branch pushed, pull request open and linked to the issue
