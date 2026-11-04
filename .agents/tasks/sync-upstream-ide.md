# Task: sync Code-OSS upstream (Track B, when Active)

Persona: ide-fork-engineer. Checklist: `checklists/upstream_sync.md`.
1. Read the upstream release notes and security advisories for the target tag.
2. Branch `chore/upstream-<tag>`. Bump `upstream.lock`.
3. Re-apply patches in order; record result per patch (clean / fuzz / conflict / obsolete).
4. Drop patches that upstream fixed; propose upstream PRs for general fixes (FRK-10).
5. Build on 3 OSes in CI; run tests, patch-health, network-capture check.
6. Write `docs/UPSTREAM_SYNC.md` entry: tag, patch table, hours spent, issues.
7. PR; the owner decides the release.
