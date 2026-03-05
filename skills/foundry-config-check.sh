#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"

if [ ! -f "foundry.toml" ]; then
  echo '{"skill":"foundry-config-check","status":"fail","summary":"foundry.toml missing","artifacts":{"missing_keys":[]},"metadata":{"timestamp":"'"$(date -u +%FT%TZ)"'"}}'
  exit 0
fi

REQUIRED_KEYS=("optimizer" "solc_version")
MISSING=()
for key in "${REQUIRED_KEYS[@]}"; do
  grep -q "$key" foundry.toml 2>/dev/null || MISSING+=("$key")
done

if [ ${#MISSING[@]} -ne 0 ]; then
  STATUS="fail"
  SUMMARY="Missing required foundry config keys"
else
  STATUS="pass"
  SUMMARY="Foundry config valid"
fi

if command -v jq >/dev/null 2>&1; then
  MISSING_JSON=$(printf '%s\n' "${MISSING[@]}" | jq -R . | jq -s .)
else
  MISSING_JSON="[]"
  for m in "${MISSING[@]}"; do
    [ "$MISSING_JSON" = "[]" ] && MISSING_JSON="[\"$m\"" || MISSING_JSON="$MISSING_JSON,\"$m\""
  done
  [ ${#MISSING[@]} -gt 0 ] && MISSING_JSON="${MISSING_JSON}]"
fi

cat <<JSON
{
  "skill":"foundry-config-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "missing_keys":$MISSING_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
