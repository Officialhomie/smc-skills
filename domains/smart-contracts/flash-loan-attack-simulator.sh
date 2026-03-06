#!/usr/bin/env bash
# Skill 53: Flash Loan Attack Simulator
# Detects flash loan functions, reentrancy in borrows
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="flash loan attack vectors analyzed"
FINDINGS=()
ARTIFACTS=()

# Check for flash loan patterns
FLASH_PATTERNS=(
  "flashLoan"
  "flashSwap"
  "flash"
)

for pattern in "${FLASH_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check flash loan implementations
FLASH_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "function.*flash" || true)

if [ -n "$FLASH_FILES" ]; then
  while IFS= read -r file; do
    # Check for fee charging
    if ! grep -A 15 "function.*flash" "$file" | grep -q "fee\|charge\|rate"; then
      FINDINGS+=("$file: flash loan without fee mechanism")
      STATUS="warn"
    fi

    # Check for return amount validation
    if ! grep -A 15 "function.*flash" "$file" | grep -q "require.*amount\|require.*balance"; then
      FINDINGS+=("$file: flash loan without repayment validation")
      STATUS="fail"
    fi

    # Check for callback function
    if ! grep -q "onFlash\|flashCallback\|callback" "$file"; then
      FINDINGS+=("$file: flash loan without callback validation")
      STATUS="fail"
    fi

    # Check for reentrancy guard on flash loan
    if ! grep -q "nonReentrant\|ReentrancyGuard" "$file"; then
      FINDINGS+=("$file: flash loan without reentrancy guard")
      STATUS="fail"
    fi
  done <<< "$FLASH_FILES"
fi

# Check for external calls in the same transaction
EXTERNAL_PATTERNS=(
  "\.call("
  "\.transfer("
  "\.send("
)

for pattern in "${EXTERNAL_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)
  if [ -n "$FILES" ]; then
    while IFS= read -r file; do
      # Check if external calls are in flash loan context
      if grep -q "flash" "$file" && grep -q "$pattern" "$file"; then
        FINDINGS+=("$file: external calls detected in flash context")
        STATUS="warn"
      fi
    done <<< "$FILES"
  fi
done

# Check for borrow/lend patterns
BORROW_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "borrow\|lend\|loan" || true)

if [ -n "$BORROW_FILES" ]; then
  while IFS= read -r file; do
    # Check for borrow limits
    if ! grep -q "maxBorrow\|borrowLimit\|borrowCap" "$file"; then
      FINDINGS+=("$file: borrow function without limits")
      STATUS="warn"
    fi

    # Check for collateral requirements
    if ! grep -A 10 "function.*borrow" "$file" | grep -q "collateral\|require.*balance"; then
      FINDINGS+=("$file: borrow without collateral check")
      STATUS="fail"
    fi

    # Check for interest accrual
    if ! grep -q "interest\|rate\|fee" "$file"; then
      FINDINGS+=("$file: lending without interest mechanism")
      STATUS="warn"
    fi
  done <<< "$BORROW_FILES"
fi

# Check for same-block constraints
SAME_BLOCK_CHECK=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "blockNumber\|timestamp.*==\|same.*block" || true)

if [ -n "$SAME_BLOCK_CHECK" ]; then
  ARTIFACTS+=("same-block-protection")
else
  # No same-block protection found
  if [ -n "$FLASH_FILES" ]; then
    FINDINGS+=("No same-block constraint detected in flash loan")
    STATUS="warn"
  fi
fi

# Check for dynamic balance checks
BALANCE_CHECK=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "balanceOf.*before|initialBalance|startBalance" || true)

if [ -n "$BALANCE_CHECK" ]; then
  ARTIFACTS+=("dynamic-balance-check")
fi

# Check for reserve ratio validation
RESERVE_RATIO=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "reserve.*ratio|solvency|liquidation" || true)

if [ -n "$RESERVE_RATIO" ]; then
  FINDINGS+=("Reserve ratio validation detected")
fi

# Build JSON arrays
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

if [ ${#ARTIFACTS[@]} -eq 0 ]; then
  ARTIFACTS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ARTIFACTS_JSON=$(printf '%s\n' "${ARTIFACTS[@]}" | jq -R . | jq -s .)
else
  ARTIFACTS_JSON="[\"${ARTIFACTS[0]}\""
  for a in "${ARTIFACTS[@]:1}"; do
    ARTIFACTS_JSON="$ARTIFACTS_JSON,\"$a\""
  done
  ARTIFACTS_JSON="${ARTIFACTS_JSON}]"
fi

cat <<JSON
{
  "skill":"flash-loan-attack-simulator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "protections":$ARTIFACTS_JSON,
    "findings":$FINDINGS_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
