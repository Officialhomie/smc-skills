#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
forge test --fuzz-runs 256 2>/dev/null || STATUS="fail"

cat <<JSON
{
  "skill":"fuzz-test-check",
  "status":"$STATUS",
  "summary":"Fuzz tests executed",
  "artifacts":{"fuzz_runs":256},
  "metadata":{"timestamp":"$(date -u +%FT%TZ)"}
}
JSON
