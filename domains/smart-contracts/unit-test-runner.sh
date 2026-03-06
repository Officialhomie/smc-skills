#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

OUTPUT=$(forge test -q 2>&1) || true
r=$?
STATUS="pass"
[ $r -ne 0 ] && STATUS="fail"
SUMMARY="Unit tests executed"

# Sanitize for JSON: escape backslash and double-quote, collapse newlines to space
OUTPUT_SAFE=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | head -c 2000)

cat <<JSON
{
  "skill":"unit-test-runner",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "output":"$OUTPUT_SAFE"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
