#!/usr/bin/env bash
# Skill 14: Event Emission Completeness
# Ensures critical state changes emit events
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="event emission patterns validated"
MISSING=()

# Critical functions that should emit events
CRITICAL_FUNCS=(
  "transferOwnership"
  "mint"
  "burn"
  "approve"
  "transfer"
  "pause"
  "unpause"
  "withdraw"
  "deposit"
  "setFee"
  "updateConfig"
)

for func in "${CRITICAL_FUNCS[@]}"; do
  # Find files with the function
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "function $func" || true)

  if [ -n "$FILES" ]; then
    while IFS= read -r file; do
      # Check if function body contains emit
      FUNC_START=$(grep -n "function $func" "$file" | head -1 | cut -d: -f1)

      if [ -n "$FUNC_START" ]; then
        # Extract function body (simplified - assumes single closing brace)
        FUNC_BODY=$(tail -n +$FUNC_START "$file" | awk '/^[[:space:]]*}/ {print; exit} {print}')

        if ! echo "$FUNC_BODY" | grep -q "emit"; then
          MISSING+=("$file:$func missing event emission")
          STATUS="warn"
        fi
      fi
    done <<< "$FILES"
  fi
done

# Check for event definitions
EVENT_COUNT=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -c "event " || echo "0")

if [ "$EVENT_COUNT" -eq 0 ]; then
  MISSING+=("No events defined in contract")
  STATUS="fail"
  SUMMARY="no events found in contracts"
fi

# Build JSON array
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
  "skill":"event-emission-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "missing_events":$MISSING_JSON,
    "total_events":"$EVENT_COUNT"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
