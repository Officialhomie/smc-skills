#!/usr/bin/env bash
# Skill 16: Ownable Pattern Validation
# Validates proper Ownable implementation
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="ownable pattern validated"
FINDINGS=()

# Check for Ownable contracts
OWNABLE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "is Ownable\|is Ownable2Step" || true)

if [ -n "$OWNABLE_FILES" ]; then
  while IFS= read -r file; do
    # Check for constructor setting owner
    if ! grep -q "constructor\|Ownable()" "$file"; then
      FINDINGS+=("$file: Ownable without explicit initialization")
      STATUS="warn"
    fi

    # Check for transferOwnership usage
    if ! grep -q "transferOwnership" "$file"; then
      FINDINGS+=("$file: Ownable imported but transferOwnership not used")
      STATUS="warn"
    fi

    # Check for onlyOwner modifier usage
    ONLY_OWNER_COUNT=$(grep -c "onlyOwner" "$file" || echo "0")

    if [ "$ONLY_OWNER_COUNT" -lt 1 ]; then
      FINDINGS+=("$file: No functions protected with onlyOwner")
      STATUS="fail"
      SUMMARY="ownable imported but not used"
    fi

    # Prefer Ownable2Step over Ownable (safer)
    if grep -q "is Ownable[^2]" "$file"; then
      FINDINGS+=("$file: Use Ownable2Step instead of Ownable for safer ownership transfer")
      STATUS="warn"
    fi

    # Check for renounceOwnership (dangerous)
    if grep -q "renounceOwnership" "$file"; then
      FINDINGS+=("$file: renounceOwnership can permanently lock contract (consider removing)")
      STATUS="warn"
    fi
  done <<< "$OWNABLE_FILES"
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
  "skill":"ownable-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "ownable_contracts":"$(echo "$OWNABLE_FILES" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
