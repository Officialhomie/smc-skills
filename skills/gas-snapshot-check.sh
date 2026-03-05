#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
forge snapshot 2>/dev/null || STATUS="fail"

cat <<JSON
{
  "skill":"gas-snapshot-check",
  "status":"$STATUS",
  "summary":"Gas snapshot generated",
  "artifacts":{"snapshot_file":"gas-snapshot.txt"},
  "metadata":{"timestamp":"$(date -u +%FT%TZ)"}
}
JSON
