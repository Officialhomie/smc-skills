#!/usr/bin/env bash
# Skill 78: Event Listener Validator
# Validates event processing reliability
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="event listener reliability patterns validated"
FINDINGS=()

# Check for event emitters in contracts
EVENT_CONTRACTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emit.*\|event " || true)

if [ -n "$EVENT_CONTRACTS" ]; then
  while IFS= read -r file; do
    # Check for event definitions
    if grep -q "^[[:space:]]*event " "$file"; then
      EVENT_COUNT=$(grep -c "^[[:space:]]*event " "$file" || echo "0")

      # Check for indexed parameters (for efficient filtering)
      UNINDEXED_EVENTS=$(grep "^[[:space:]]*event " "$file" | grep -v "indexed" | wc -l || echo "0")

      if [ "$UNINDEXED_EVENTS" -gt 0 ]; then
        FINDINGS+=("$file: Events without indexed parameters (hard to filter)")
        STATUS="warn"
      fi
    fi

    # Check for event emission without validation
    if grep -q "emit " "$file"; then
      # Look for emissions that might not have preceding validation
      UNGUARDED_EMITS=$(grep "emit " "$file" | grep -v "require\|assert\|if " | wc -l || echo "0")

      if [ "$UNGUARDED_EMITS" -gt 2 ]; then
        FINDINGS+=("$file: Multiple unguarded event emissions")
        STATUS="warn"
      fi
    fi
  done <<< "$EVENT_CONTRACTS"

  SUMMARY="event emission patterns validated"
fi

# Check for event listener code
LISTENER_FILES=$(find src -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "on\|addEventListener\|watch\|subscribe.*event\|filter.*event" 2>/dev/null || true)

if [ -n "$LISTENER_FILES" ]; then
  while IFS= read -r file; do
    # Check for event filter configuration
    if grep -q "addEventListener\|on.*event\|watch\|filter.*event" "$file"; then
      if ! grep -q "filter\|fromBlock\|toBlock\|address" "$file"; then
        FINDINGS+=("$file: Event listeners without proper filtering")
        STATUS="warn"
      fi
    fi

    # Check for batch/paginated event processing
    EVENT_CALL_COUNT=$(grep -c "on\|addEventListener\|watch\|filter" "$file" || echo "0")

    if [ "$EVENT_CALL_COUNT" -gt 5 ]; then
      if ! grep -q "batch\|paginate\|limit\|range" "$file"; then
        FINDINGS+=("$file: Multiple event listeners without pagination")
        STATUS="warn"
      fi
    fi

    # Check for event ordering guarantees
    if grep -q "addEventListener.*order\|sequential\|ordered.*process" "$file"; then
      if ! grep -q "queue\|order\|sequence\|timestamp" "$file"; then
        FINDINGS+=("$file: No event ordering mechanism implemented")
        STATUS="warn"
      fi
    fi

    # Check for error handling in listeners
    if grep -q "addEventListener\|on.*event\|watch" "$file"; then
      if ! grep -q "try.*catch\|error.*handler\|catch.*error" "$file"; then
        FINDINGS+=("$file: Event listeners without error handling")
        STATUS="warn"
      fi
    fi

    # Check for reconnection logic
    if grep -q "WebSocket\|Provider\|subscribe" "$file"; then
      if ! grep -q "reconnect\|disconnect\|retry\|fallback" "$file"; then
        FINDINGS+=("$file: Event provider without reconnection logic")
        STATUS="warn"
      fi
    fi
  done <<< "$LISTENER_FILES"
fi

# Check for subgraph mapping handlers
MAPPING_FILES=$(find . -name "*.ts" -path "*/src/mappings/*" 2>/dev/null)

if [ -n "$MAPPING_FILES" ]; then
  while IFS= read -r file; do
    # Check for handler implementations
    if grep -q "export function handle" "$file"; then
      HANDLER_COUNT=$(grep -c "export function handle" "$file" || echo "0")

      # Verify handlers process events correctly
      if ! grep -q "store.set\|store.get\|entity" "$file"; then
        FINDINGS+=("$file: Event handler without state management")
        STATUS="warn"
      fi
    fi
  done <<< "$MAPPING_FILES"
fi

# Build JSON array
if [ ${#FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${FINDINGS[0]}\""
  for f in "${FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$f\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"event-listener-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "event_contracts":"$(echo "$EVENT_CONTRACTS" | wc -l | tr -d ' ')",
    "listener_files":"$(echo "$LISTENER_FILES" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
