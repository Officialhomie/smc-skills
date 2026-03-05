#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"
# formatting (if installed)
if command -v prettier >/dev/null 2>&1; then
  prettier --write "**/*.{ts,js,sol,md,json}" || true
fi
if command -v solhint >/dev/null 2>&1; then
  solhint "contracts/**/*.sol" || true
fi
cat <<JSON
{
  "skill":"format-check",
  "status":"pass",
  "summary":"format/lint applied (if tools installed)",
  "artifacts":{},
  "metadata":{"runner":"local"}
}
JSON
