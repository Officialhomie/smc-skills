#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Compilation successful"
forge build 2>/dev/null || { STATUS="fail"; SUMMARY="Compilation failed"; }

cat <<JSON
{
  "skill":"compile-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{},
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
