#!/usr/bin/env bash
# Skill 56: Fee Mechanism Validator
# Detects fee calculations, fee recipients, fee bounds
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="fee mechanism patterns validated"
FINDINGS=()
ARTIFACTS=()

# Check for fee patterns
FEE_PATTERNS=(
  "fee"
  "tax"
  "commission"
  "royalty"
  "basisPoints"
)

for pattern in "${FEE_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -li "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check fee implementations
FEE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "fee\|tax" || true)

if [ -n "$FEE_FILES" ]; then
  while IFS= read -r file; do
    # Check for fee storage/tracking
    if ! grep -q "feeAmount\|feeBalance\|collectedFees\|accumulatedFees" "$file"; then
      FINDINGS+=("$file: fee tracking without storage")
      STATUS="warn"
    fi

    # Check for fee bounds/limits
    if ! grep -q "MAX_FEE\|maxFee\|feeLimit\|basisPoints.*<=\|fee.*<=" "$file"; then
      FINDINGS+=("$file: no fee upper bound - unlimited fees possible")
      STATUS="fail"
    fi

    # Check for fee recipient
    if ! grep -q "feeRecipient\|treasury\|feeOwner\|feeAddress" "$file"; then
      FINDINGS+=("$file: no clear fee recipient defined")
      STATUS="warn"
    fi

    # Check if fee recipient is hardcoded or changeable
    if grep -q "feeRecipient.*=" "$file"; then
      if ! grep -B 5 "feeRecipient.*=" "$file" | grep -q "onlyOwner\|onlyAdmin\|governance"; then
        FINDINGS+=("$file: fee recipient changeable without access control")
        STATUS="fail"
      fi
    fi

    # Check for fee calculation accuracy
    if ! grep -q "multiply\|divide\|scale\|basisPoints" "$file"; then
      FINDINGS+=("$file: simple fee calculation without precision handling")
      STATUS="warn"
    fi
  done <<< "$FEE_FILES"
fi

# Check for withdrawal/collection of fees
WITHDRAWAL=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "withdrawFee|collectFee|claimFee" || true)

if [ -n "$WITHDRAWAL" ]; then
  ARTIFACTS+=("fee-withdrawal")

  while IFS= read -r file; do
    # Check if withdrawal has access control
    if ! grep -B 3 "withdrawFee\|collectFee\|claimFee" "$file" | grep -q "onlyOwner\|onlyAdmin\|onlyRole"; then
      FINDINGS+=("$file: fee withdrawal without access control")
      STATUS="fail"
    fi
  done <<< "$FEE_FILES"
fi

# Check for multiple fee types
MULTI_FEE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "swapFee|protocolFee|tradingFee|borrowFee" || true)

if [ -n "$MULTI_FEE" ]; then
  ARTIFACTS+=("multi-fee-types")
  FINDINGS+=("Multiple fee types detected")
fi

# Check for dynamic fees
DYNAMIC_FEE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "dynamicFee|adjustFee|variantFee|volatilityFee" || true)

if [ -n "$DYNAMIC_FEE" ]; then
  ARTIFACTS+=("dynamic-fees")

  while IFS= read -r file; do
    # Check if dynamic fee has bounds
    if ! grep -q "MAX_FEE\|maxFee\|bounds" "$file"; then
      FINDINGS+=("$file: dynamic fees without bounds")
      STATUS="warn"
    fi
  done <<< "$FEE_FILES"
fi

# Check for fee revenue split
SPLIT=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "feeSplit|revenueShare|percentage.*distribution" || true)

if [ -n "$SPLIT" ]; then
  ARTIFACTS+=("fee-split")

  while IFS= read -r file; do
    # Check if split percentages add up
    if grep -q "percentage\|percent\|[0-9]*%" "$file"; then
      FINDINGS+=("$file: fee split percentages - verify they sum to 100")
      STATUS="warn"
    fi
  done <<< "$FEE_FILES"
fi

# Check for dust/rounding issues
ROUNDING=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "dust|remainder|round" || true)

if [ -n "$ROUNDING" ]; then
  ARTIFACTS+=("rounding-handling")
else
  if [ -n "$FEE_FILES" ]; then
    FINDINGS+=("No rounding/dust handling detected in fee calculations")
    STATUS="warn"
  fi
fi

# Check for fee exemptions
EXEMPTION=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "feeExempt|exempt|noFee|skipFee" || true)

if [ -n "$EXEMPTION" ]; then
  ARTIFACTS+=("fee-exemption")

  while IFS= read -r file; do
    # Check if exemptions are restricted
    if ! grep -B 3 "feeExempt\|exempt" "$file" | grep -q "onlyOwner\|onlyAdmin"; then
      FINDINGS+=("$file: fee exemptions without access control")
      STATUS="warn"
    fi
  done <<< "$FEE_FILES"
fi

# Check for fee events
EVENTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "event.*[Ff]ee|FeeCollected|FeeWithdrawn" || true)

if [ -n "$EVENTS" ]; then
  ARTIFACTS+=("fee-events")
else
  if [ -n "$FEE_FILES" ]; then
    FINDINGS+=("No events for fee operations - limited transparency")
    STATUS="warn"
  fi
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
  "skill":"fee-mechanism-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "mechanisms":$ARTIFACTS_JSON,
    "findings":$FINDINGS_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
