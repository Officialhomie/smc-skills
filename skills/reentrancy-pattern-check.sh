#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

MATCHES=""
[ -d contracts ] && MATCHES=$(grep -R "call.value" contracts 2>/dev/null || true) || true

if [ -n "$MATCHES" ]; then
  STATUS="warn"
  SUMMARY="Low-level call pattern scan (matches found)"
else
  STATUS="pass"
  SUMMARY="Low-level call pattern scan"
fi

MATCHES_SAFE=$(echo "$MATCHES" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | head -c 1000)

cat <<JSON
{
  "skill":"reentrancy-pattern-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "matches":"$MATCHES_SAFE"
  },
  "metadata":{"timestamp":"$(date -u +%FT%TZ)"}
}
JSON
