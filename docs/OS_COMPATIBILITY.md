# OS compatibility

Update this table whenever you test a configuration. "Tested" means the CI or manual run in the Evidence column passed.

| OS | Version | Arch | Target release | Status | Evidence | Known issues |
|---|---|---|---|---|---|---|
| Windows | 11 | x64 | MVP | Not tested | | |
| Windows | 10 | x64 | MVP | Not tested | | |
| Ubuntu LTS | 24.04 | x64 | MVP | Not tested | | Needs `libsecret` for secure storage |
| macOS | current and previous | arm64 | R3 (best effort earlier) | Not tested | | Needs signing and notarisation |

## Rules

An untested configuration must not be presented as supported (FR-ENV-013). Linux without a keyring: the app does not persist the session.
