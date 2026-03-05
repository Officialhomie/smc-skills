#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"
STATUS="warn"
SUMMARY="no static analyzer installed"
if command -v slither >/dev/null 2>&1; then
  slither ./contracts --json build/slither.json && STATUS="pass" && SUMMARY="slither run"
elif command -v solhint >/dev/null 2>&1; then
  solhint "contracts/**/*.sol" && STATUS="pass" && SUMMARY="solhint run"
fi
cat <<JSON
{
  "skill":"static-analysis",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{},
  "metadata":{"runner":"local"}
}
JSON
