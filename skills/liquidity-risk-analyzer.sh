#!/usr/bin/env bash
# Skill 51: Liquidity Risk Analyzer
# Detects liquidity pools, reserves, slippage protection
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="liquidity risk patterns analyzed"
FINDINGS=()
ARTIFACTS=()

# Check for liquidity pool patterns
POOL_PATTERNS=(
  "reserve"
  "liquidity"
  "pool"
  "uniswap"
  "balancer"
  "swap"
)

for pattern in "${POOL_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -li "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check for reserve tracking
RESERVE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "reserve" || true)

if [ -n "$RESERVE_FILES" ]; then
  while IFS= read -r file; do
    # Check if reserves are tracked/validated
    if ! grep -q "require.*reserve\|reserve.*balance\|reserveBalance" "$file"; then
      FINDINGS+=("$file: reserve tracking without validation")
      STATUS="warn"
    fi
  done <<< "$RESERVE_FILES"
fi

# Check for slippage protection
SWAP_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "function.*swap\|function.*exchange" || true)

if [ -n "$SWAP_FILES" ]; then
  while IFS= read -r file; do
    # Check for minimum output checks
    if ! grep -A 10 "function.*swap" "$file" | grep -q "minOutputAmount\|minimumReturn\|require.*amount"; then
      FINDINGS+=("$file: swap without slippage protection")
      STATUS="fail"
    fi
  done <<< "$SWAP_FILES"
fi

# Check for liquidity provider rewards
LP_PATTERNS=(
  "lpToken"
  "LPToken"
  "liquidity_provider"
  "addLiquidity"
  "removeLiquidity"
)

for pattern in "${LP_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)
  if [ -n "$FILES" ]; then
    FINDINGS+=("LP pattern detected: $pattern")
  fi
done

# Check for price oracle or price feeds
PRICE_PATTERNS=(
  "oracle"
  "feed"
  "price"
  "getPrice"
  "getRate"
)

for pattern in "${PRICE_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)
  if [ -n "$FILES" ]; then
    FINDINGS+=("Price mechanism detected: $pattern")
  fi
done

# Check for flashloan vulnerability in liquidity
FLASH_PATTERNS=(
  "flash"
  "flashLoan"
  "flashSwap"
)

for pattern in "${FLASH_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)
  if [ -n "$FILES" ]; then
    FINDINGS+=("Flash loan mechanism detected: $pattern")
    STATUS="warn"
  fi
done

# Check for constant product formula or similar
FORMULA_CHECK=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "reserve.*reserve|x.*y.*k|constant.*product" || true)

if [ -n "$FORMULA_CHECK" ]; then
  FINDINGS+=("Automated market maker formula detected")
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
  "skill":"liquidity-risk-analyzer",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "patterns":$ARTIFACTS_JSON,
    "findings":$FINDINGS_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
