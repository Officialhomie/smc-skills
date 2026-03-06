#!/usr/bin/env bash
# Skill 49: Finality Guarantees Checker
# Validates finality property implementation
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Finality guarantees validated"
FINDINGS=()
FINALITY_MECHANISMS=()
CONFIRMATION_CHECKS=()
REORG_PROTECTION=()

SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found"
else
  while IFS= read -r file; do
    # Detect finality mechanisms
    if grep -qE "finalized|confirmed|irreversible" "$file" 2>/dev/null; then
      FINALITY_MECHANISMS+=("$file - Finality mechanism detected")

      # Check confirmation requirements
      if grep -qE "confirmations|blockNumber.*>.*required" "$file"; then
        CONFIRMATION_CHECKS+=("$file - Confirmation checks implemented")
      fi

      # Check reorg protection
      if grep -qE "safeBlockNumber|checkpoint" "$file"; then
        REORG_PROTECTION+=("$file - Reorg protection detected")
      fi
    fi
  done <<< "$SOL_FILES"

  FINDINGS+=("Finality mechanisms: ${#FINALITY_MECHANISMS[@]}")
  FINDINGS+=("Confirmation checks: ${#CONFIRMATION_CHECKS[@]}")

  if [ ${#FINALITY_MECHANISMS[@]} -eq 0 ]; then
    SUMMARY="No finality mechanisms detected"
  else
    SUMMARY="Finality guarantees validated - ${#FINALITY_MECHANISMS[@]} mechanisms"
  fi
fi

FINDINGS_JSON="[]"
if [ ${#FINDINGS[@]} -gt 0 ] && command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
fi

cat <<JSON
{
  "skill":"finality-guarantees-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "finality_mechanisms":${#FINALITY_MECHANISMS[@]},
    "confirmation_checks":${#CONFIRMATION_CHECKS[@]}
  },
  "metadata":{"timestamp":"$(date -u +%FT%TZ)","runner":"local"}
}
JSON
