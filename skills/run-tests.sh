#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"
STATUS="pass"
SUMMARY="all tests passed"
if command -v forge >/dev/null 2>&1; then
  if ! forge test -q; then
    STATUS="fail"
    SUMMARY="some tests failed"
  fi
else
  STATUS="warn"
  SUMMARY="forge not found"
fi
cat <<JSON
{
  "skill":"run-tests",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{"test_command":"forge test"},
  "metadata":{"runner":"local"}
}
JSON
