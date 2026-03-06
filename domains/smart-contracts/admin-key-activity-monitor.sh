#!/usr/bin/env bash
# Skill 63: Admin Key Activity Monitor
# Tracks privileged operations (onlyOwner, onlyRole calls)
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="admin key activity patterns analyzed"
ADMIN_FINDINGS=()

# Find all admin-protected functions
ADMIN_MODIFIERS=(
  "onlyOwner"
  "onlyRole"
  "onlyAdmin"
  "onlyGovernance"
  "onlyGovernor"
  "onlyMultisig"
  "requiresAuth"
)

for modifier in "${ADMIN_MODIFIERS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$modifier" || true)

  if [ -n "$FILES" ]; then
    while IFS= read -r file; do
      # Count functions with this modifier
      FUNC_COUNT=$(grep -c "$modifier" "$file" || echo "0")

      ADMIN_FINDINGS+=("$file: $FUNC_COUNT functions with $modifier modifier")

      # Check for functions without emit (state changes without events)
      PROTECTED_FUNCS=$(grep -B5 "$modifier" "$file" | grep "function " || true)

      while IFS= read -r func_line; do
        [ -z "$func_line" ] && continue

        FUNC_NAME=$(echo "$func_line" | grep -oE "function [a-zA-Z_][a-zA-Z0-9_]*" | cut -d' ' -f2)

        # Check if function body contains emit
        if [ -n "$FUNC_NAME" ]; then
          FUNC_START=$(grep -n "function $FUNC_NAME" "$file" | head -1 | cut -d: -f1)

          if [ -n "$FUNC_START" ]; then
            FUNC_BODY=$(tail -n +$FUNC_START "$file" | awk '/^[[:space:]]*}/ {print; exit} {print}')

            if ! echo "$FUNC_BODY" | grep -q "emit"; then
              ADMIN_FINDINGS+=("$file: Admin function '$FUNC_NAME' lacks event emission")
              STATUS="warn"
            fi
          fi
        fi
      done <<< "$PROTECTED_FUNCS"
    done <<< "$FILES"
  fi
done

# Check for multi-signature requirement patterns
MULTISIG_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "multisig\|MultiSig\|Multisig" || true)

if [ -n "$MULTISIG_FILES" ]; then
  while IFS= read -r file; do
    ADMIN_FINDINGS+=("$file: Multi-signature contract detected")

    # Check if approval threshold is documented
    if ! grep -q "threshold\|approvalCount\|signaturesRequired"; then
      ADMIN_FINDINGS+=("$file: Multi-signature contract without explicit threshold documentation")
      STATUS="warn"
    fi

    # Check for time delays
    if ! grep -q "delay\|timelock\|timestamp"; then
      ADMIN_FINDINGS+=("$file: Multi-signature lacking time delay (recommend adding timelock)")
      STATUS="warn"
    fi
  done <<< "$MULTISIG_FILES"
fi

# Check for owner transfer functions
OWNER_TRANSFER_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "transferOwnership\|setOwner\|changeOwner" || true)

if [ -n "$OWNER_TRANSFER_FILES" ]; then
  while IFS= read -r file; do
    # Check if ownership transfer is protected
    TRANSFER_LINES=$(grep -n "transferOwnership\|setOwner\|changeOwner" "$file" || true)

    while IFS= read -r line_info; do
      [ -z "$line_info" ] && continue

      LINE_NUM=$(echo "$line_info" | cut -d: -f1)

      # Check if function has access control
      FUNC_CONTEXT=$(tail -n -$((LINE_NUM)) "$file" | head -10)

      if ! echo "$FUNC_CONTEXT" | grep -qE "onlyOwner|onlyRole|onlyMultisig|require.*msg.sender"; then
        ADMIN_FINDINGS+=("$file:$LINE_NUM: Ownership transfer without access control (CRITICAL)")
        STATUS="fail"
      fi

      # Check if new owner is validated
      if ! echo "$FUNC_CONTEXT" | grep -q "require.*address\|require.*!= address(0)"; then
        ADMIN_FINDINGS+=("$file:$LINE_NUM: Ownership transfer without address validation")
        STATUS="warn"
      fi
    done <<< "$TRANSFER_LINES"
  done <<< "$OWNER_TRANSFER_FILES"
fi

# Check for pause/unpause functions (admin-critical)
PAUSE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "pause\|Pausable" || true)

if [ -n "$PAUSE_FILES" ]; then
  while IFS= read -r file; do
    # Count pause-related functions
    PAUSE_COUNT=$(grep -c "pause\|unpause" "$file" || echo "0")

    ADMIN_FINDINGS+=("$file: $PAUSE_COUNT pause/unpause operations")

    # Check if pause has event
    if grep -q "function.*pause" "$file"; then
      PAUSE_FUNC=$(grep -A10 "function.*pause" "$file")

      if ! echo "$PAUSE_FUNC" | grep -q "emit"; then
        ADMIN_FINDINGS+=("$file: Pause function without event emission")
        STATUS="warn"
      fi
    fi
  done <<< "$PAUSE_FILES"
fi

# Check for parameter update functions
PARAM_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -lE "setFee|setRate|setThreshold|setLimit|update.*Config" || true)

if [ -n "$PARAM_FILES" ]; then
  while IFS= read -r file; do
    PARAM_LINES=$(grep -nE "setFee|setRate|setThreshold|setLimit|update.*Config" "$file" || true)

    while IFS= read -r line_info; do
      [ -z "$line_info" ] && continue

      LINE_NUM=$(echo "$line_info" | cut -d: -f1)

      # Check for validation of new parameters
      PARAM_CONTEXT=$(tail -n +$LINE_NUM "$file" | head -10)

      if ! echo "$PARAM_CONTEXT" | grep -q "require\|assert\|validate"; then
        ADMIN_FINDINGS+=("$file:$LINE_NUM: Parameter update without validation")
        STATUS="warn"
      fi

      # Check for event emission
      if ! echo "$PARAM_CONTEXT" | grep -q "emit"; then
        ADMIN_FINDINGS+=("$file:$LINE_NUM: Parameter update without event")
        STATUS="warn"
      fi
    done <<< "$PARAM_LINES"
  done <<< "$PARAM_FILES"
fi

# Check for emergency functions
EMERGENCY_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -lE "emergency|withdraw.*all|drain|shutdown" || true)

if [ -n "$EMERGENCY_FILES" ]; then
  while IFS= read -r file; do
    # Count emergency operations
    EMERGENCY_COUNT=$(grep -cE "emergency|withdraw.*all|drain|shutdown" "$file" || echo "0")

    ADMIN_FINDINGS+=("$file: $EMERGENCY_COUNT emergency/drain operations detected")

    # Check if emergency functions are protected
    if grep -q "emergency\|drain\|shutdown"; then
      if ! grep -q "onlyOwner\|onlyMultisig\|onlyRole"; then
        ADMIN_FINDINGS+=("$file: Emergency functions without access control (CRITICAL)")
        STATUS="fail"
      fi
    fi
  done <<< "$EMERGENCY_FILES"
fi

# Build JSON array
if [ ${#ADMIN_FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${ADMIN_FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${ADMIN_FINDINGS[0]}\""
  for f in "${ADMIN_FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$f\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"admin-key-activity-monitor",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "admin_findings":$FINDINGS_JSON,
    "finding_count":${#ADMIN_FINDINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
