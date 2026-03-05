#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

REQUIRED_DIRS=(
  "contracts"
  "test"
  "scripts"
  "tools/skills"
  "docs"
  "ci"
)

MISSING=()
for dir in "${REQUIRED_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    MISSING+=("$dir")
  fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
  STATUS="fail"
  SUMMARY="Missing required directories"
else
  STATUS="pass"
  SUMMARY="Project structure valid"
fi

if [ ${#MISSING[@]} -eq 0 ]; then
  MISSING_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  MISSING_JSON=$(printf '%s\n' "${MISSING[@]}" | jq -R . | jq -s .)
else
  MISSING_JSON="[\"${MISSING[0]}\""
  for m in "${MISSING[@]:1}"; do
    MISSING_JSON="$MISSING_JSON,\"$m\""
  done
  MISSING_JSON="${MISSING_JSON}]"
fi

cat <<JSON
{
  "skill":"project-structure-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "missing_directories":$MISSING_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
