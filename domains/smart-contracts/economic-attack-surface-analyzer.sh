#!/usr/bin/env bash
# Skill 47: Economic Attack Surface Analyzer
# Analyzes economic exploit vectors and attack surfaces
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Economic attack surface analyzed"
FINDINGS=()
PRICE_MANIPULATION_RISKS=()
FLASH_LOAN_VECTORS=()
MEV_VULNERABILITIES=()
ARBITRAGE_OPPORTUNITIES=()

SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found"
else
  while IFS= read -r file; do
    # Detect price manipulation risks
    if grep -qE "getPrice|latestAnswer|price.*oracle" "$file" 2>/dev/null; then
      if ! grep -qE "updatedAt|timeStamp|staleness" "$file"; then
        PRICE_MANIPULATION_RISKS+=("$file - Price oracle without staleness check")
        STATUS="warn"
      fi
    fi

    # Detect flash loan vectors
    if grep -qE "flashLoan|borrow.*repay.*same.*block" "$file" 2>/dev/null; then
      FLASH_LOAN_VECTORS+=("$file - Flash loan functionality detected")
    fi

    # Detect MEV vulnerabilities
    if grep -qE "frontrun|backrun|sandwich|slippage" "$file" 2>/dev/null; then
      MEV_VULNERABILITIES+=("$file - MEV-related code detected")
    fi

    # Detect arbitrage opportunities
    if grep -qE "swap|exchange|trade" "$file" 2>/dev/null; then
      if ! grep -qE "slippage|minAmountOut|deadline" "$file"; then
        ARBITRAGE_OPPORTUNITIES+=("$file - Swap without slippage protection")
        STATUS="warn"
      fi
    fi
  done <<< "$SOL_FILES"

  FINDINGS+=("Price manipulation risks: ${#PRICE_MANIPULATION_RISKS[@]}")
  FINDINGS+=("Flash loan vectors: ${#FLASH_LOAN_VECTORS[@]}")
  FINDINGS+=("MEV vulnerabilities: ${#MEV_VULNERABILITIES[@]}")

  if [ ${#PRICE_MANIPULATION_RISKS[@]} -gt 0 ] || [ ${#ARBITRAGE_OPPORTUNITIES[@]} -gt 0 ]; then
    SUMMARY="Economic risks detected - ${#PRICE_MANIPULATION_RISKS[@]} price risks"
  else
    SUMMARY="Economic attack surface analyzed - no critical risks"
  fi
fi

FINDINGS_JSON="[]"
if [ ${#FINDINGS[@]} -gt 0 ] && command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
fi

cat <<JSON
{
  "skill":"economic-attack-surface-analyzer",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "price_manipulation_risks":${#PRICE_MANIPULATION_RISKS[@]},
    "flash_loan_vectors":${#FLASH_LOAN_VECTORS[@]},
    "mev_vulnerabilities":${#MEV_VULNERABILITIES[@]}
  },
  "metadata":{"timestamp":"$(date -u +%FT%TZ)","runner":"local"}
}
JSON
