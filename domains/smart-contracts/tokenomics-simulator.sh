#!/usr/bin/env bash
# Skill 50: Tokenomics Simulator
# Detects token emission, mint/burn functions, supply caps
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="tokenomics patterns validated"
FINDINGS=()
ARTIFACTS=()

# Check for token emission patterns
EMISSION_PATTERNS=(
  "mint"
  "burn"
  "MAX_SUPPLY"
  "totalSupply"
  "initialSupply"
)

for pattern in "${EMISSION_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check for mint function with supply checks
MINT_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "function mint" || true)

if [ -n "$MINT_FILES" ]; then
  while IFS= read -r file; do
    # Check if mint has supply cap checks
    if ! grep -A 5 "function mint" "$file" | grep -q "MAX_SUPPLY\|cap\|require.*total"; then
      FINDINGS+=("$file: mint() without supply cap check")
      STATUS="warn"
    fi

    # Check for access control on mint
    if ! grep -B 5 "function mint" "$file" | grep -q "onlyOwner\|onlyRole\|onlyMinter"; then
      FINDINGS+=("$file: mint() lacks access control")
      STATUS="fail"
    fi
  done <<< "$MINT_FILES"
fi

# Check for burn function implementation
BURN_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "function burn" || true)

if [ -n "$BURN_FILES" ]; then
  FINDINGS+=("burn() function detected")
fi

# Check for emission rate/schedule
EMISSION_SCHEDULE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "emissionRate|releaseSchedule|cliff|vesting" || true)

if [ -n "$EMISSION_SCHEDULE" ]; then
  FINDINGS+=("Emission schedule or vesting detected")
fi

# Check for inflation mechanism
INFLATION=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "inflation|emission.*rate" || true)

if [ -n "$INFLATION" ]; then
  FINDINGS+=("Inflation mechanism detected")
fi

# Check for supply cap
SUPPLY_CAP=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "MAX_SUPPLY|CAP|maxSupply" || true)

if [ -n "$SUPPLY_CAP" ]; then
  FINDINGS+=("Supply cap or maximum supply detected")
else
  FINDINGS+=("No supply cap detected - unlimited supply possible")
  STATUS="warn"
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
  "skill":"tokenomics-simulator",
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
