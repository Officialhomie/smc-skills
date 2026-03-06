#!/usr/bin/env bash
# Skill 72: Automation Bot Checker
# Checks keeper bot reliability and automation patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="keeper bot patterns validated"
FINDINGS=()

# Check for keeper contract patterns
KEEPER_CONTRACTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "keeper\|automation\|checkUpkeep\|performUpkeep" || true)

if [ -n "$KEEPER_CONTRACTS" ]; then
  while IFS= read -r file; do
    # Check for checkUpkeep implementation
    if grep -q "checkUpkeep" "$file"; then
      if ! grep -q "function checkUpkeep\|returns.*bool" "$file"; then
        FINDINGS+=("$file: Incomplete checkUpkeep implementation")
        STATUS="fail"
      fi

      # Validate return pattern
      if ! grep -q "return (upkeepNeeded\|return (true\|return (false" "$file"; then
        FINDINGS+=("$file: checkUpkeep missing proper return statement")
        STATUS="warn"
      fi
    fi

    # Check for performUpkeep implementation
    if grep -q "performUpkeep" "$file"; then
      if ! grep -q "function performUpkeep" "$file"; then
        FINDINGS+=("$file: Incomplete performUpkeep implementation")
        STATUS="fail"
      fi

      # Validate reentrancy protection
      if ! grep -q "nonReentrant\|guard\|lock" "$file"; then
        FINDINGS+=("$file: performUpkeep without reentrancy protection")
        STATUS="warn"
      fi
    fi

    # Check for execution gas limits
    if grep -q "performUpkeep\|keeper.*function" "$file"; then
      if ! grep -q "gasLimit\|GAS_LIMIT\|require.*gas\|gasleft()" "$file"; then
        FINDINGS+=("$file: No gas limit checks in keeper functions")
        STATUS="warn"
      fi
    fi

    # Check for timing validation
    if grep -q "checkUpkeep\|automation" "$file"; then
      if ! grep -q "block.timestamp\|lastExecuted\|interval\|TIME_" "$file"; then
        FINDINGS+=("$file: No timing validation in automation")
        STATUS="warn"
      fi
    fi

    # Check for access control on keeper functions
    if grep -q "performUpkeep" "$file"; then
      if ! grep -q "onlyKeeper\|onlyAutomation\|msg.sender\|authorized" "$file"; then
        FINDINGS+=("$file: performUpkeep without access control")
        STATUS="warn"
      fi
    fi
  done <<< "$KEEPER_CONTRACTS"

  SUMMARY="keeper bot automation patterns validated"
fi

# Check for keeper configuration files
KEEPER_CONFIG=$(find . -name "*.json" -o -name "*.config.*" 2>/dev/null | xargs grep -l "keeper\|automation\|upkeep" || true)

if [ -n "$KEEPER_CONFIG" ]; then
  # Validate configuration has retry logic
  if ! grep -q "retry\|attempt\|exponential" "$KEEPER_CONFIG"; then
    FINDINGS+=("Keeper config: Missing retry/backoff strategy")
    STATUS="warn"
  fi
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
  "skill":"automation-bot-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "keeper_contracts":"$(echo "$KEEPER_CONTRACTS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
