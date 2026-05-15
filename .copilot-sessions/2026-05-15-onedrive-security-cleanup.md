# 2026-05-15 — OneDrive security cleanup

- Date / device / UI: 2026-05-15, Mac, VS Code Copilot
- Goal: Fix OneDrive/SPO policy-triggering runtime files in moneyPrinterTurbo.

## What worked (final approach kept)
- Located the real project at `/Users/mao_msft/Library/CloudStorage/OneDrive-Microsoft/moneyPrinterTurbo`, separate from the TestClaude skeleton folder.
- Moved app config loading from project-root `config.toml` to per-device local config outside OneDrive:
  - macOS: `~/Library/Application Support/moneyPrinterTurbo/config.toml`
  - Windows: `%LOCALAPPDATA%\moneyPrinterTurbo\config.toml`
- Added setup scripts:
  - `setup_env.sh` creates `~/.venvs/moneyPrinterTurbo` and migrates local config.
  - `setup_env.ps1` creates `%USERPROFILE%\.venvs\moneyPrinterTurbo` and migrates local config.
- Updated `webui.sh` and `webui.bat` to use the external per-device venv when present.
- Removed OneDrive-synced `.venv`, root `config.toml`, `__pycache__`, and `storage/cache_videos`.
- Verified app config now resolves outside OneDrive and final filename scan found no `.env`, cert/key files, token caches, project venv, root `config.toml`, or runtime cache paths.

## What failed (do not repeat)
- Don't assume `moneyPrinterTurbo` under `TestClaude ----` is the real project; the active project is under the OneDrive root.
- Don't leave project-root `config.toml` under OneDrive; it may contain API keys and the app used to recreate it automatically.
- Don't leave `.venv` under OneDrive; certifi `cacert.pem` triggers Microsoft policy warnings.

## Files changed
- .gitignore
- SETUP.txt
- setup_env.sh
- setup_env.ps1
- app/config/config.py
- webui.sh
- webui.bat

## Things to be done / recommendations
- Commit and push after Mao confirms, so Windows devices receive the setup scripts and local-config behavior.
- On Windows, run `setup_env.ps1` once from the project folder after pulling.
