# Developer setup

Required on every OS: Git, Node.js 22 (see `.nvmrc`), pnpm 10, Python 3.12 and uv.

## Windows 10/11

1. Install Git, Node.js 22 and Python 3.12.
2. Install Visual Studio Build Tools with the "Desktop development with C++" workload (needed to build `node-pty` and the SQLite module).
3. `corepack enable` then `pnpm install`.
4. Install uv: `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` then `uv sync --all-packages`.

## Ubuntu LTS

```bash
sudo apt update
sudo apt install -y build-essential python3 make g++ libsecret-1-dev git curl
# Node 22 via nvm or your preferred manager, then:
corepack enable
pnpm install
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync --all-packages
```
`libsecret` is needed for secure token storage. Without a keyring the app refuses to persist the session.

## macOS (best effort until R3)

```bash
xcode-select --install
brew install node@22 uv
corepack enable && pnpm install && uv sync --all-packages
```

## Run and check

```bash
pnpm dev                      # desktop app
pnpm check                    # JS/TS lint, types, tests, then Python tests
python tools/check_docs.py    # consistency of requirements, design, backlog, tests
```

## Troubleshooting

Native module errors after an Electron upgrade: `pnpm --filter @devsphere/desktop rebuild`. Add new OS findings to `OS_COMPATIBILITY.md`.
