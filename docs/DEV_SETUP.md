# Developer setup

Required on every OS: Git, Flutter SDK (3.24+), Dart (3.5+), Melos (`dart pub global activate melos`), Python 3.12 and uv.

## Windows 10/11

1. Install Git, Flutter SDK and Python 3.12.
2. Install Visual Studio Build Tools with the "Desktop development with C++" workload (needed for Flutter Windows desktop).
3. Activate Melos: `dart pub global activate melos` then `melos bootstrap`.
4. Install uv: `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` then `uv sync --all-packages`.

## Ubuntu Linux LTS

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libsqlite3-dev git curl python3
# Install Flutter SDK and add flutter/bin to PATH, then:
dart pub global activate melos
melos bootstrap
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync --all-packages
```
`libsecret` is needed for secure token storage. Without a keyring the app refuses to persist the session.

## macOS

```bash
xcode-select --install
brew install uv
# Install Flutter SDK and configure Xcode for macOS desktop, then:
dart pub global activate melos
melos bootstrap
uv sync --all-packages
```

## Run and check

```bash
flutter run -d windows          # or -d linux, -d macos
melos run check                # Dart/Flutter analyze and tests
uv run pytest                  # Python service tests
python tools/check_docs.py     # consistency of requirements, design, backlog, tests
```

## Troubleshooting

Ensure `flutter doctor` reports no missing toolchains for your platform desktop runner. Add new OS findings to `OS_COMPATIBILITY.md`.
