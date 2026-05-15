#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${MPT_VENV:-$HOME/.venvs/moneyPrinterTurbo}"
CONFIG_DIR="${MPT_CONFIG_DIR:-$HOME/Library/Application Support/moneyPrinterTurbo}"

if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="${PYTHON:-python3.11}"
else
  PYTHON_BIN="${PYTHON:-python3}"
fi

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "ERROR: Python was not found. Install Python 3.11 first, then rerun this script." >&2
  exit 1
fi

PY_VERSION="$($PYTHON_BIN - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
PY
)"

case "$PY_VERSION" in
  3.11|3.12) ;;
  *)
    echo "ERROR: MoneyPrinterTurbo requires Python >=3.11,<3.13. Found $PY_VERSION." >&2
    exit 1
    ;;
esac

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

if [[ -f "$PROJECT_DIR/config.toml" && ! -f "$CONFIG_DIR/config.toml" ]]; then
  cp "$PROJECT_DIR/config.toml" "$CONFIG_DIR/config.toml"
  chmod 600 "$CONFIG_DIR/config.toml"
  echo "Migrated local config to: $CONFIG_DIR/config.toml"
elif [[ ! -f "$CONFIG_DIR/config.toml" ]]; then
  cp "$PROJECT_DIR/config.example.toml" "$CONFIG_DIR/config.toml"
  chmod 600 "$CONFIG_DIR/config.toml"
  echo "Created local config template: $CONFIG_DIR/config.toml"
  echo "Fill in local config values before running the app."
fi

"$PYTHON_BIN" -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install -r "$PROJECT_DIR/requirements.txt"
"$VENV_DIR/bin/python" -B -m py_compile "$PROJECT_DIR/main.py" "$PROJECT_DIR/app/config/config.py"

echo "Ready. Virtualenv is outside OneDrive: $VENV_DIR"
echo "Local config is outside OneDrive: $CONFIG_DIR/config.toml"
echo "Use it on macOS with: source \"$VENV_DIR/bin/activate\""