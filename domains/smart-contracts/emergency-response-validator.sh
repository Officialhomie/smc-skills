#!/usr/bin/env bash
# Skill 65: Emergency Response Validator
# Validates emergency procedures are in place
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="emergency response procedures validated"
EMERGENCY_FINDINGS=()

# Check for pause mechanism
PAUSE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "pause\|Pausable" || true)

if [ -n "$PAUSE_FILES" ]; then
  while IFS= read -r file; do
    # Check for proper pause guard
    if grep -q "function.*pause" "$file"; then
      if ! grep -q "onlyOwner\|onlyAdmin\|onlyGovernance\|onlyRole"; then
        EMERGENCY_FINDINGS+=("$file: Pause function without access control (CRITICAL)")
        STATUS="fail"
      else
        EMERGENCY_FINDINGS+=("$file: Emergency pause mechanism implemented")
      fi

      # Check for pause flag guard
      if ! grep -q "whenNotPaused\|require.*!.*paused\|require.*paused"; then
        EMERGENCY_FINDINGS+=("$file: Pause mechanism without state guard checks")
        STATUS="warn"
      fi
    fi
  done <<< "$PAUSE_FILES"
else
  # Check if contracts handle emergencies
  CRIT_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "contract\s" | head -5 || true)

  if [ -n "$CRIT_FILES" ]; then
    EMERGENCY_FINDINGS+=("No pause/pausable mechanism found (consider implementing)")
    STATUS="warn"
  fi
fi

# Check for emergency withdrawal functions
WITHDRAW_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "withdraw\|drain\|emergency" || true)

if [ -n "$WITHDRAW_FILES" ]; then
  while IFS= read -r file; do
    WITHDRAW_LINES=$(grep -n "withdraw\|drain\|emergency" "$file" || true)

    while IFS= read -r line_info; do
      [ -z "$line_info" ] && continue

      LINE_NUM=$(echo "$line_info" | cut -d: -f1)

      # Check for access control
      WITHDRAW_CONTEXT=$(tail -n -$((LINE_NUM)) "$file" | head -10)

      if echo "$WITHDRAW_CONTEXT" | grep -q "withdraw" && ! echo "$WITHDRAW_CONTEXT" | grep -q "onlyOwner\|onlyAdmin\|onlyRole"; then
        EMERGENCY_FINDINGS+=("$file:$LINE_NUM: Withdrawal function without access control")
        STATUS="fail"
      fi

      # Check for amount validation
      if ! echo "$WITHDRAW_CONTEXT" | grep -q "require.*amount\|require.*balance"; then
        EMERGENCY_FINDINGS+=("$file:$LINE_NUM: Withdrawal without proper validation")
        STATUS="warn"
      fi
    done <<< "$WITHDRAW_LINES"
  done <<< "$WITHDRAW_FILES"
fi

# Check for timelock mechanism
TIMELOCK_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "timelock\|TimelockController\|delay" || true)

if [ -n "$TIMELOCK_FILES" ]; then
  while IFS= read -r file; do
    EMERGENCY_FINDINGS+=("$file: Timelock mechanism detected")

    # Check for minimum delay
    if ! grep -q "MIN_DELAY\|min_delay\|DELAY"; then
      EMERGENCY_FINDINGS+=("$file: Timelock without configurable delay")
      STATUS="warn"
    fi
  done <<< "$TIMELOCK_FILES"
else
  EMERGENCY_FINDINGS+=("No timelock mechanism found (recommend implementing for critical operations)")
  STATUS="warn"
fi

# Check for circuit breaker patterns
CIRCUIT_BREAKER_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "circuit.*breaker\|threshold\|limit\|max.*amount" || true)

if [ -n "$CIRCUIT_BREAKER_FILES" ]; then
  while IFS= read -r file; do
    # Check for transaction limits
    if grep -q "MAX_\|_MAX\|max_"; then
      EMERGENCY_FINDINGS+=("$file: Transaction limit/threshold detected")

      # Check if limit is enforced
      LIMIT_LINES=$(grep -n "MAX_\|_MAX\|max_" "$file" | head -5)

      while IFS= read -r line_info; do
        [ -z "$line_info" ] && continue

        LINE_NUM=$(echo "$line_info" | cut -d: -f1)
        LIMIT_CONTEXT=$(tail -n +$LINE_NUM "$file" | head -5)

        if ! echo "$LIMIT_CONTEXT" | grep -q "require"; then
          EMERGENCY_FINDINGS+=("$file:$LINE_NUM: Limit defined but not enforced")
          STATUS="warn"
        fi
      done <<< "$LIMIT_LINES"
    fi
  done <<< "$CIRCUIT_BREAKER_FILES"
fi

# Check for emergency state/flag
EMERGENCY_FLAG_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emergency\|isEmergency\|_emergency" || true)

if [ -n "$EMERGENCY_FLAG_FILES" ]; then
  while IFS= read -r file; do
    # Check if emergency flag is properly protected
    if grep -q "emergency" "$file"; then
      if ! grep -q "onlyOwner.*emergency\|onlyAdmin.*emergency"; then
        EMERGENCY_FINDINGS+=("$file: Emergency flag without protection (CRITICAL)")
        STATUS="fail"
      fi
    fi
  done <<< "$EMERGENCY_FLAG_FILES"
fi

# Check for multi-sig emergency controls
MULTISIG_EMERGENCY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "multisig.*emergency\|emergency.*multisig" || true)

if [ -n "$MULTISIG_EMERGENCY" ]; then
  EMERGENCY_FINDINGS+=("Multi-signature emergency control detected")
else
  # Check for any governance-based emergency
  GOVERNANCE_EMERGENCY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "governance.*emergency\|emergency.*governance" || true)

  if [ -z "$GOVERNANCE_EMERGENCY" ]; then
    EMERGENCY_FINDINGS+=("No multi-sig or governance emergency controls found")
    STATUS="warn"
  fi
fi

# Check for upgrade mechanism (can be used for emergency fixes)
UPGRADE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "upgrade\|Upgrade\|UUPS\|Proxy" || true)

if [ -n "$UPGRADE_FILES" ]; then
  while IFS= read -r file; do
    EMERGENCY_FINDINGS+=("$file: Upgrade mechanism available (can enable emergency fixes)")

    # Check if upgrade is protected
    if grep -q "upgrade" "$file"; then
      if ! grep -q "onlyOwner\|onlyGovernance\|onlyRole"; then
        EMERGENCY_FINDINGS+=("$file: Upgrade function without access control (CRITICAL)")
        STATUS="fail"
      fi
    fi
  done <<< "$UPGRADE_FILES"
fi

# Check for event logging of emergency actions
EMERGENCY_EVENTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emergency\|panic\|alert" | xargs grep -l "emit" || true)

if [ -n "$EMERGENCY_EVENTS" ]; then
  EMERGENCY_FINDINGS+=("Emergency events are being logged")
else
  EMERGENCY_FINDINGS+=("Consider logging emergency actions via events")
  STATUS="warn"
fi

# Check for documentation/comments about emergency procedures
EMERGENCY_DOCS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emergency.*procedure\|/@notice.*emergency\|// Emergency" || true)

if [ -n "$EMERGENCY_DOCS" ]; then
  EMERGENCY_FINDINGS+=("Emergency procedures documented in code")
else
  EMERGENCY_FINDINGS+=("Emergency procedures lack in-code documentation")
  STATUS="warn"
fi

# Build JSON array
if [ ${#EMERGENCY_FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${EMERGENCY_FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${EMERGENCY_FINDINGS[0]}\""
  for e in "${EMERGENCY_FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$e\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"emergency-response-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "emergency_findings":$FINDINGS_JSON,
    "finding_count":${#EMERGENCY_FINDINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
