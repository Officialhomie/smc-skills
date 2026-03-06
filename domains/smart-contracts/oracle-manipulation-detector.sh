#!/usr/bin/env bash
# Skill 52: Oracle Manipulation Detector
# Detects oracle manipulation vectors and attack surfaces
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="oracle manipulation vectors analyzed"
FINDINGS=()
ARTIFACTS=()

# Check for oracle usage
ORACLE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "oracle\|feed\|price" || true)

if [ -n "$ORACLE_FILES" ]; then
  while IFS= read -r file; do
    # Check for single oracle dependency
    ORACLE_COUNT=$(grep -c "oracle\|feed" "$file" || echo "0")
    if [ "$ORACLE_COUNT" -eq 1 ]; then
      FINDINGS+=("$file: Single oracle dependency - single point of failure")
      STATUS="fail"
    fi

    # Check for oracle price validation
    if ! grep -q "require.*price\|priceCheck\|validatePrice" "$file"; then
      FINDINGS+=("$file: Oracle price without validation checks")
      STATUS="warn"
    fi

    # Check for staleness check
    if ! grep -q "timestamp\|staleness\|age\|updatedAt" "$file"; then
      FINDINGS+=("$file: No staleness check on oracle data")
      STATUS="fail"
    fi

    # Check for price deviation limits
    if ! grep -q "maxDeviation\|tolerance\|maxPriceChange\|baseFee" "$file"; then
      FINDINGS+=("$file: No price deviation bounds detected")
      STATUS="warn"
    fi
  done <<< "$ORACLE_FILES"

  # Check for multiple oracle implementation (good practice)
  MULTI_ORACLE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "oracle.*oracle|primary.*secondary|chainlink.*band|chainlink.*uniswap" || true)

  if [ -z "$MULTI_ORACLE" ]; then
    FINDINGS+=("Consider using multiple oracle sources for robustness")
    STATUS="warn"
  fi
fi

# Check for oracle interface/implementation
ORACLE_INTERFACE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "IOracle\|IPriceFeed\|OracleInterface" || true)

if [ -n "$ORACLE_INTERFACE" ]; then
  ARTIFACTS+=("oracle-interface")
fi

# Check for Chainlink oracle patterns
CHAINLINK=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "chainlink\|AggregatorV3\|AggregatorInterface" || true)

if [ -n "$CHAINLINK" ]; then
  ARTIFACTS+=("chainlink-oracle")

  while IFS= read -r file; do
    # Check for round completeness
    if ! grep -q "roundComplete\|answeredInRound" "$file"; then
      FINDINGS+=("$file: Chainlink oracle without round completeness check")
      STATUS="warn"
    fi

    # Check for answer bounds
    if ! grep -q "minAnswer\|maxAnswer" "$file"; then
      FINDINGS+=("$file: Chainlink oracle without answer bounds")
      STATUS="warn"
    fi
  done <<< "$CHAINLINK"
fi

# Check for Band Protocol patterns
BAND=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "band\|BandInterface\|IBandOracle" || true)

if [ -n "$BAND" ]; then
  ARTIFACTS+=("band-oracle")
fi

# Check for Uniswap TWAP patterns
TWAP=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "twap\|TWAP\|time.*weighted\|timeWeighted" || true)

if [ -n "$TWAP" ]; then
  ARTIFACTS+=("uniswap-twap")

  while IFS= read -r file; do
    # Check for observation length validation
    if ! grep -q "observation\|window" "$file"; then
      FINDINGS+=("$file: TWAP without observation window validation")
      STATUS="warn"
    fi
  done <<< "$TWAP"
fi

# Check for flash loan oracle attacks
FLASHLOAN_ORACLE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "flash.*price|flash.*oracle|price.*same.*block" || true)

if [ -n "$FLASHLOAN_ORACLE" ]; then
  FINDINGS+=("Flash loan oracle risk detected")
  STATUS="fail"
fi

# Check for block-based manipulation
BLOCK_ORACLE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "blockhash|block\.number.*price|block\.timestamp.*price" || true)

if [ -n "$BLOCK_ORACLE" ]; then
  FINDINGS+=("Block-based oracle manipulation risk detected")
  STATUS="fail"
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
  "skill":"oracle-manipulation-detector",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "oracle_types":$ARTIFACTS_JSON,
    "findings":$FINDINGS_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
