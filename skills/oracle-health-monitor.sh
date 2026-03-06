#!/usr/bin/env bash
# Skill 70: Oracle Health Monitor
# Monitors oracle uptime and data quality patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="oracle health patterns validated"
FINDINGS=()

# Check for oracle usage across contracts
ORACLE_CONTRACTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "AggregatorV3Interface\|IOracle\|getPriceData\|latestRoundData" || true)

if [ -n "$ORACLE_CONTRACTS" ]; then
  CONTRACT_COUNT=$(echo "$ORACLE_CONTRACTS" | wc -l | tr -d ' ')

  while IFS= read -r file; do
    # Check for heartbeat/timeout monitoring
    if grep -q "latestRoundData\|getPriceData" "$file"; then
      if ! grep -q "timeout\|heartbeat\|ORACLE_TIMEOUT\|staleness" "$file"; then
        FINDINGS+=("$file: Oracle calls without heartbeat/timeout monitoring")
        STATUS="warn"
      fi
    fi

    # Check for data quality validation
    if grep -q "oracle.*price\|latestRoundData" "$file"; then
      if ! grep -q "require.*price\|assert.*data\|if.*quality" "$file"; then
        FINDINGS+=("$file: Oracle data without quality validation")
        STATUS="warn"
      fi
    fi

    # Check for multiple oracle sources for resilience
    ORACLE_CALLS=$(grep -c "AggregatorV3Interface\|IOracle" "$file" || echo "0")
    if [ "$ORACLE_CALLS" -eq 1 ]; then
      if ! grep -q "backup.*oracle\|secondary.*oracle\|oracle.*redundanc" "$file"; then
        FINDINGS+=("$file: Single oracle source without redundancy")
        STATUS="warn"
      fi
    fi

    # Check for price deviation checks
    if grep -q "latestRoundData" "$file"; then
      if ! grep -q "deviation\|diff\|percent.*change\|MAX_PRICE_DEVIATION" "$file"; then
        FINDINGS+=("$file: No price deviation detection")
        STATUS="warn"
      fi
    fi
  done <<< "$ORACLE_CONTRACTS"

  SUMMARY="oracle health monitoring patterns analyzed"
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
  "skill":"oracle-health-monitor",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "oracle_contracts":"$(echo "$ORACLE_CONTRACTS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
