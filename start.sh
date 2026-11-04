#!/usr/bin/env bash
# User story: US-16 Native desktop shell startup (Sprint 4, MVP)
# Requirements: NFR-PORT-001, NFR-PERF-001
# Cross-platform startup script: detects OS, verifies dependencies, starts backend API and launches DevSphere desktop client.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "========================================="
echo "   DevSphere Cross-Platform Launcher    "
echo "========================================="

# 1. Detect Operating System (Linux, macOS, Windows)
OS_NAME="$(uname -s)"
TARGET_DEVICE=""

case "$OS_NAME" in
  Linux*)
    echo "Detected OS: Linux"
    TARGET_DEVICE="linux"
    ;;
  Darwin*)
    echo "Detected OS: macOS"
    TARGET_DEVICE="macos"
    ;;
  CYGWIN*|MINGW*|MSYS*|Windows_NT*)
    echo "Detected OS: Windows"
    TARGET_DEVICE="windows"
    ;;
  *)
    echo "Warning: Unrecognized OS ($OS_NAME). Defaulting to chrome web."
    TARGET_DEVICE="chrome"
    ;;
esac

# 2. Check Core Tooling (uv, flutter, melos)
echo ""
echo "--> Checking developer tools..."

# Ensure local bin is on PATH (for user-installed ninja, symlinks, etc.)
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v uv &> /dev/null; then
  echo "Error: 'uv' is not installed or not in PATH."
  echo "Install it via: curl -LsSf https://astral.sh/uv/install.sh | sh"
  exit 1
fi

if ! command -v flutter &> /dev/null; then
  if [ -d "$HOME/development/flutter/bin" ]; then
    export PATH="$HOME/development/flutter/bin:$PATH"
  fi
fi

if ! command -v flutter &> /dev/null; then
  echo "Error: 'flutter' is not found in PATH."
  echo "Please install Flutter and add it to your PATH."
  exit 1
fi

if ! command -v melos &> /dev/null; then
  if [ -f "$HOME/.pub-cache/bin/melos" ]; then
    export PATH="$HOME/.pub-cache/bin:$PATH"
  else
    echo "Activating melos globally..."
    dart pub global activate melos
    export PATH="$HOME/.pub-cache/bin:$PATH"
  fi
fi

# 3. Install & Sync Dependencies
echo ""
echo "--> Installing / syncing Python dependencies..."
uv sync

echo ""
echo "--> Bootstrapping Dart / Flutter workspace..."
melos bootstrap

# OS-Specific Pre-flight checks
if [ "$TARGET_DEVICE" = "linux" ]; then
  echo ""
  echo "--> Checking Linux build requirements..."
  if ! command -v ninja &> /dev/null; then
    echo "Installing ninja via uv tool..."
    uv tool install ninja || true
  fi

  if ! pkg-config --exists gtk+-3.0 2>/dev/null; then
    echo "Notice: libgtk-3-dev is missing for native GTK compilation."
    echo "Falling back to Chrome device..."
    TARGET_DEVICE="chrome"
  fi

  # Clean stale CMake cache if it was configured with /usr/local
  if [ -f "$ROOT_DIR/apps/desktop/build/linux/x64/debug/CMakeCache.txt" ]; then
    if grep -q "CMAKE_INSTALL_PREFIX:PATH=/usr/local" "$ROOT_DIR/apps/desktop/build/linux/x64/debug/CMakeCache.txt" 2>/dev/null; then
      echo "Cleaning stale Linux CMake build cache..."
      rm -rf "$ROOT_DIR/apps/desktop/build/linux"
    fi
  fi
fi

# 4. Start Backend API Server
echo ""
echo "--> Starting DevSphere Backend API (FastAPI) on port 8000..."

# Stop any existing process on port 8000
if command -v lsof &> /dev/null; then
  EXISTING_PID=$(lsof -ti:8000 || true)
  if [ -n "$EXISTING_PID" ]; then
    echo "Stopping existing process on port 8000 (PID: $EXISTING_PID)..."
    kill -9 $EXISTING_PID 2>/dev/null || true
    sleep 1
  fi
fi

# Launch backend in background
(
  cd "$ROOT_DIR/services/api"
  exec uv run uvicorn app.main:app --host 127.0.0.1 --port 8000
) &
API_PID=$!

cleanup() {
  echo ""
  echo "Shutting down DevSphere..."
  if [ -n "${API_PID:-}" ] && kill -0 "$API_PID" 2>/dev/null; then
    echo "Stopping API server (PID: $API_PID)..."
    kill "$API_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Wait for API to respond
echo "Waiting for API server to become ready..."
for i in {1..30}; do
  if curl -s http://127.0.0.1:8000/health | grep -q '"status":"ok"'; then
    echo "Backend API is ready at http://127.0.0.1:8000"
    break
  fi
  sleep 0.5
done

# 5. Launch the Complete Client Application
echo ""
echo "--> Launching DevSphere Client on target: $TARGET_DEVICE..."
cd "$ROOT_DIR/apps/desktop"

flutter run -d "$TARGET_DEVICE"

