#!/usr/bin/env bash
# Skill 15: Pausable Mechanism Check
# Validates emergency pause patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="pausable mechanism validated"
ISSUES=()

# Check for Pausable pattern
PAUSABLE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "Pausable\|whenNotPaused" || true)

if [ -n "$PAUSABLE_FILES" ]; then
  while IFS= read -r file; do
    # Check for pause function with access control
    if grep -q "function pause" "$file"; then
      if ! grep -A5 "function pause" "$file" | grep -q "onlyOwner\|onlyRole"; then
        ISSUES+=("$file: pause() lacks access control")
        STATUS="fail"
      fi
    else
      ISSUES+=("$file: Pausable imported but no pause() function")
      STATUS="warn"
    fi

    # Check for unpause function
    if ! grep -q "function unpause" "$file"; then
      ISSUES+=("$file: missing unpause() function")
      STATUS="fail"
    fi

    # Check for whenNotPaused modifier usage
    PROTECTED_COUNT=$(grep -c "whenNotPaused" "$file" || echo "0")

    if [ "$PROTECTED_COUNT" -lt 1 ]; then
      ISSUES+=("$file: no functions protected with whenNotPaused")
      STATUS="warn"
    fi
  done <<< "$PAUSABLE_FILES"
else
  # No pausable - check if it should have one
  CRITICAL_FUNCS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "function (transfer|mint|burn|deposit|withdraw)" | wc -l | tr -d ' ')

  if [ "$CRITICAL_FUNCS" -gt 0 ]; then
    ISSUES+=("Critical functions without pausable mechanism (consider adding)")
    STATUS="warn"
    SUMMARY="no emergency pause mechanism"
  fi
fi

# Build JSON array
if [ ${#ISSUES[@]} -eq 0 ]; then
  ISSUES_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -s .)
else
  ISSUES_JSON="[\"${ISSUES[0]}\""
  for i in "${ISSUES[@]:1}"; do
    ISSUES_JSON="$ISSUES_JSON,\"$i\""
  done
  ISSUES_JSON="${ISSUES_JSON}]"
fi

cat <<JSON
{
  "skill":"pausable-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "issues":$ISSUES_JSON,
    "pausable_contracts":"$(echo "$PAUSABLE_FILES" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
