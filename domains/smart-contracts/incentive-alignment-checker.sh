#!/usr/bin/env bash
# Skill 55: Incentive Alignment Checker
# Detects reward mechanisms, staking, yield farming
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="incentive alignment patterns analyzed"
FINDINGS=()
ARTIFACTS=()

# Check for reward/staking patterns
REWARD_PATTERNS=(
  "reward"
  "stake"
  "yield"
  "farming"
  "bonus"
  "incentive"
)

for pattern in "${REWARD_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -li "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check staking implementation
STAKING_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "stake\|Staking" || true)

if [ -n "$STAKING_FILES" ]; then
  while IFS= read -r file; do
    # Check for staking amount tracking
    if ! grep -q "staked\|stakedAmount\|stakingBalance" "$file"; then
      FINDINGS+=("$file: staking without proper amount tracking")
      STATUS="warn"
    fi

    # Check for reward rate
    if ! grep -q "rewardRate\|rewardPerToken\|rewardPerSecond" "$file"; then
      FINDINGS+=("$file: staking without reward rate definition")
      STATUS="warn"
    fi

    # Check for unstaking/withdrawal
    if ! grep -q "unstake\|withdraw.*stake" "$file"; then
      FINDINGS+=("$file: staking without unstake mechanism (lockup risk)")
      STATUS="warn"
    fi

    # Check for claim functionality
    if ! grep -q "claim\|claimReward" "$file"; then
      FINDINGS+=("$file: staking without reward claim mechanism")
      STATUS="fail"
    fi
  done <<< "$STAKING_FILES"
fi

# Check yield farming patterns
YIELD_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "yield\|farm\|pool.*reward" || true)

if [ -n "$YIELD_FILES" ]; then
  while IFS= read -r file; do
    # Check for APY/APR calculation
    if ! grep -q "apy\|apr\|APY\|APR\|yield.*rate" "$file"; then
      FINDINGS+=("$file: yield farming without APY/APR calculation")
      STATUS="warn"
    fi

    # Check for reward pool limits
    if ! grep -q "maxReward\|rewardCap\|totalRewardAmount" "$file"; then
      FINDINGS+=("$file: yield farming without reward pool limits")
      STATUS="warn"
    fi
  done <<< "$YIELD_FILES"
fi

# Check for reward distribution mechanism
DISTRIBUTION=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "distribute.*reward|allocate.*reward|emission" || true)

if [ -n "$DISTRIBUTION" ]; then
  FINDINGS+=("Reward distribution mechanism detected")
  ARTIFACTS+=("reward-distribution")
fi

# Check for perverse incentives (token dumping, farming-and-exit)
PERVERSE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "cliffPeriod|vestingSchedule|lockupPeriod" || true)

if [ -n "$PERVERSE" ]; then
  ARTIFACTS+=("lockup-protection")
else
  if [ -n "$STAKING_FILES" ] || [ -n "$YIELD_FILES" ]; then
    FINDINGS+=("No lockup or vesting mechanism to prevent reward dumping")
    STATUS="warn"
  fi
fi

# Check for fee/tax on rewards
FEE_ON_REWARDS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "rewardFee|taxOnReward|claimFee" || true)

if [ -n "$FEE_ON_REWARDS" ]; then
  FINDINGS+=("Fee/tax on rewards detected - may impact yield calculation")
fi

# Check for early exit penalty
PENALTY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "earlyExitPenalty|unstakePenalty|penalty.*early" || true)

if [ -n "$PENALTY" ]; then
  ARTIFACTS+=("early-exit-penalty")
fi

# Check for slashing mechanism
SLASHING=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "slash\|slash" || true)

if [ -n "$SLASHING" ]; then
  ARTIFACTS+=("slashing-mechanism")

  while IFS= read -r file; do
    # Check if slashing is justified
    if ! grep -q "condition\|require\|if.*then" "$file"; then
      FINDINGS+=("$file: slashing without clear conditions")
      STATUS="warn"
    fi
  done <<< "$SLASHING"
fi

# Check for governance involvement in rewards
GOVERNANCE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "governance|vote|proposal.*reward" || true)

if [ -n "$GOVERNANCE" ]; then
  ARTIFACTS+=("governance-reward")
  FINDINGS+=("Governance involvement in reward decisions detected")
fi

# Check for emergency withdrawal
EMERGENCY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "emergencyWithdraw|emergencyUnstake" || true)

if [ -n "$EMERGENCY" ]; then
  ARTIFACTS+=("emergency-withdraw")
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
  "skill":"incentive-alignment-checker",
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
