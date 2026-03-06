#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

if ! command -v slither >/dev/null 2>&1; then
  echo '{"skill":"slither-analysis","status":"warn","summary":"slither not installed","artifacts":{},"metadata":{"timestamp":"'"$(date -u +%FT%TZ)"'"}}'
  exit 0
fi

mkdir -p build
STATUS="pass"
slither . --json build/slither.json 2>/dev/null || STATUS="fail"

cat <<JSON
{
  "skill":"slither-analysis",
  "status":"$STATUS",
  "summary":"Slither executed",
  "artifacts":{"report":"build/slither.json"},
  "metadata":{"timestamp":"$(date -u +%FT%TZ)"}
}
JSON
