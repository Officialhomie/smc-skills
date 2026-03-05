#!/usr/bin/env bash
# Skill 19: Oracle Integration Guard
# Validates safe oracle integration (Chainlink, etc.)
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="oracle integration validated"
RISKS=()

# Check for Chainlink oracle usage
ORACLE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "AggregatorV3Interface\|ChainlinkClient\|VRFConsumerBase" || true)

if [ -n "$ORACLE_FILES" ]; then
  while IFS= read -r file; do
    # Check for price staleness checks
    if grep -q "latestRoundData\|getRoundData" "$file"; then
      if ! grep -q "updatedAt\|timeStamp" "$file"; then
        RISKS+=("$file: Oracle price data without staleness check")
        STATUS="fail"
      fi
    fi

    # Check for zero price validation
    if grep -q "latestRoundData" "$file"; then
      if ! grep -q "price > 0\|require.*answer\|if.*answer" "$file"; then
        RISKS+=("$file: No validation for zero oracle price")
        STATUS="fail"
      fi
    fi

    # Check for round completeness
    if grep -q "getRoundData" "$file"; then
      if ! grep -q "answeredInRound\|roundId" "$file"; then
        RISKS+=("$file: No check for round completeness")
        STATUS="warn"
      fi
    fi

    # Check for circuit breaker / fallback
    ORACLE_CALLS=$(grep -c "latestRoundData\|getRoundData" "$file" || echo "0")

    if [ "$ORACLE_CALLS" -gt 0 ]; then
      if ! grep -q "try.*catch\|fallback\|backup" "$file"; then
        RISKS+=("$file: Oracle calls without circuit breaker or fallback")
        STATUS="warn"
      fi
    fi

    # Check for oracle address validation
    if grep -q "AggregatorV3Interface" "$file"; then
      if ! grep -q "require.*oracle.*address(0)\|oracle != address(0)" "$file"; then
        RISKS+=("$file: Oracle address not validated")
        STATUS="warn"
      fi
    fi

    # Check for decimals handling
    if grep -q "decimals()" "$file"; then
      if ! grep -q "10 \*\* decimals\|10\*\*decimals" "$file"; then
        RISKS+=("$file: Oracle decimals not properly handled")
        STATUS="warn"
      fi
    fi
  done <<< "$ORACLE_FILES"

  SUMMARY="oracle integration needs security review"
fi

# Build JSON array
if [ ${#RISKS[@]} -eq 0 ]; then
  RISKS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  RISKS_JSON=$(printf '%s\n' "${RISKS[@]}" | jq -R . | jq -s .)
else
  RISKS_JSON="[\"${RISKS[0]}\""
  for r in "${RISKS[@]:1}"; do
    RISKS_JSON="$RISKS_JSON,\"$r\""
  done
  RISKS_JSON="${RISKS_JSON}]"
fi

cat <<JSON
{
  "skill":"oracle-integration-guard",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "risks":$RISKS_JSON,
    "oracle_contracts":"$(echo "$ORACLE_FILES" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
