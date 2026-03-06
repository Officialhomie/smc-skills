#!/usr/bin/env bash
# Skill 58: Token Distribution Analyzer
# Detects vesting, airdrops, allocations
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="token distribution patterns analyzed"
FINDINGS=()
ARTIFACTS=()

# Check for vesting patterns
VESTING_PATTERNS=(
  "vesting"
  "cliff"
  "unlock"
  "release"
  "schedule"
)

for pattern in "${VESTING_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -li "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check vesting implementations
VESTING_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "vesting\|cliff" || true)

if [ -n "$VESTING_FILES" ]; then
  while IFS= read -r file; do
    # Check for vesting schedule tracking
    if ! grep -q "vestingSchedule\|vestingPeriod\|vestingAmount\|vestingStart" "$file"; then
      FINDINGS+=("$file: vesting without schedule tracking")
      STATUS="warn"
    fi

    # Check for cliff period
    if ! grep -q "cliffPeriod\|cliff\|cliffTime" "$file"; then
      FINDINGS+=("$file: no cliff period (tokens unlock immediately)")
      STATUS="warn"
    fi

    # Check for vesting curve (linear vs non-linear)
    if ! grep -q "linear\|exponential\|curve\|schedule" "$file"; then
      FINDINGS+=("$file: vesting curve not specified")
      STATUS="warn"
    fi

    # Check for early unlock guards
    if ! grep -q "require.*time\|block.*check\|vestingEnd\|vestingTime" "$file"; then
      FINDINGS+=("$file: no time-based unlock guards")
      STATUS="fail"
    fi
  done <<< "$VESTING_FILES"
fi

# Check for airdrop patterns
AIRDROP_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "airdrop\|claim\|distribution" || true)

if [ -n "$AIRDROP_FILES" ]; then
  while IFS= read -r file; do
    # Check for airdrop amount tracking
    if ! grep -q "airdropAmount\|claimAmount\|allocation" "$file"; then
      FINDINGS+=("$file: airdrop without amount tracking")
      STATUS="warn"
    fi

    # Check for claimed tracking
    if ! grep -q "claimed\|hasClaimed\|claimedAmount" "$file"; then
      FINDINGS+=("$file: airdrop without claim status tracking")
      STATUS="fail"
    fi

    # Check for claim deadline
    if ! grep -q "deadline\|claimDeadline\|expiresAt\|require.*block" "$file"; then
      FINDINGS+=("$file: airdrop without claim deadline")
      STATUS="warn"
    fi

    # Check for merkle proof verification (for airdrops)
    if ! grep -q "merkle\|proof\|root" "$file"; then
      FINDINGS+=("$file: airdrop without merkle verification (gas inefficient)")
      STATUS="warn"
    fi
  done <<< "$AIRDROP_FILES"
fi

# Check for allocation patterns
ALLOCATION=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "allocation|allocate|alloc" || true)

if [ -n "$ALLOCATION" ]; then
  ARTIFACTS+=("allocation-tracking")
  FINDINGS+=("Token allocation mechanism detected")
fi

# Check for allocation breakdown
BREAKDOWN=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "team.*alloc|public.*alloc|reserve.*alloc|treasury" || true)

if [ -n "$BREAKDOWN" ]; then
  FINDINGS+=("Allocation breakdown detected")
fi

# Check for max allocations
MAX_ALLOC=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "MAX_.*_ALLOCATION|ALLOCATION_CAP|totalAllocation" || true)

if [ -n "$MAX_ALLOC" ]; then
  ARTIFACTS+=("allocation-cap")
else
  FINDINGS+=("No allocation cap - verify total allocations don't exceed 100%")
  STATUS="warn"
fi

# Check for lockup periods
LOCKUP=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "lockup|locked|lock.*period|lock.*time" || true)

if [ -n "$LOCKUP" ]; then
  ARTIFACTS+=("lockup-period")
  FINDINGS+=("Token lockup period detected")
fi

# Check for team token handling
TEAM=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "team.*token|founder.*token|team.*allocation" || true)

if [ -n "$TEAM" ]; then
  FINDINGS+=("Team token allocation detected")

  while IFS= read -r file; do
    # Check if team tokens have vesting
    if grep -q "team" "$file" && ! grep -q "vesting\|cliff\|lock" "$file"; then
      FINDINGS+=("$file: team tokens without vesting (rug pull risk)")
      STATUS="fail"
    fi
  done <<< "$AIRDROP_FILES"
fi

# Check for community allocation
COMMUNITY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "community.*alloc|public.*alloc" || true)

if [ -n "$COMMUNITY" ]; then
  ARTIFACTS+=("community-allocation")
fi

# Check for treasury allocation
TREASURY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "treasury|reserve.*fund" || true)

if [ -n "$TREASURY" ]; then
  ARTIFACTS+=("treasury")
  FINDINGS+=("Treasury/reserve fund detected")
fi

# Check for multiple distribution phases
PHASES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "phase.*distribution|round.*allocation|stage.*distribution" || true)

if [ -n "$PHASES" ]; then
  ARTIFACTS+=("phased-distribution")
  FINDINGS+=("Phased distribution detected")
fi

# Check for distribution events
EVENTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "event.*[Aa]irdrops?|event.*Claim|event.*Allocation" || true)

if [ -n "$EVENTS" ]; then
  ARTIFACTS+=("distribution-events")
else
  FINDINGS+=("No events for distributions - limited transparency")
  STATUS="warn"
fi

# Check for merkle tree usage
MERKLE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "merkle\|proof" || true)

if [ -n "$MERKLE" ]; then
  ARTIFACTS+=("merkle-distribution")
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
  "skill":"token-distribution-analyzer",
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
