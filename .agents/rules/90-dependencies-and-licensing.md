# Dependency and licensing rules (DEP)

| ID | Sev | Rule |
|---|---|---|
| DEP-01 | MUST | No new dependency without a story that needs it, a licence check, and a row in `docs/TECH_STACK.md`. Prefer the platform's own features. |
| DEP-02 | MUST | Allowed licences by default: MIT, BSD-2/3, Apache-2.0, ISC, MPL-2.0 (file-level copyleft ok). Needs owner approval: LGPL, EPL, GPL/AGPL, SSPL, BSL, "source available", any custom licence. |
| DEP-03 | MUST | Pin versions; commit lockfiles; update deliberately (separate PR, changelog read, advisories checked). |
| DEP-04 | MUST | Record provenance for vendored or forked code: upstream URL, tag/commit, licence file kept, local modifications listed (`THIRD_PARTY_NOTICES`). |
| DEP-05 | STOP | Do not copy code from sources with an unknown or incompatible licence. Do not paste proprietary extension code, assets, icons or branding. |
| DEP-06 | MUST | Microsoft's name, logos, "Visual Studio Code" branding, the Marketplace and proprietary extensions are not ours to use (see `95-ide-fork.md`). Re-verify current terms before each release; legal review task SP-05. |
| DEP-07 | SHOULD | Prefer fewer, larger, maintained dependencies over many tiny ones. Check maintenance signals (recent releases, issue response, bus factor). |
| DEP-08 | MUST | Supply chain: installs run with scripts disabled where possible; CI uses a lockfile-frozen install; artefacts are built in CI, not on laptops. |
| DEP-09 | SHOULD | Generate an SBOM at release. |

## New-dependency checklist
Use `../checklists/new_dependency.md`.
