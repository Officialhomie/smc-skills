#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

if ! command -v forge >/dev/null 2>&1; then
  echo '{"skill":"solidity-format-check","status":"warn","summary":"forge not installed","artifacts":{},"metadata":{"timestamp":"'"$(date -u +%FT%TZ)"'"}}'
  exit 0
fi

STATUS="pass"
forge fmt --check 2>/dev/null || STATUS="fail"

cat <<JSON
{
  "skill":"solidity-format-check",
  "status":"$STATUS",
  "summary":"forge fmt executed",
  "artifacts":{},
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
