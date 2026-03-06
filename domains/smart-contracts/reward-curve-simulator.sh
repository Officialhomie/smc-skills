#!/usr/bin/env bash
# Skill 57: Reward Curve Simulator
# Detects reward formulas, decay mechanisms
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="reward curve patterns analyzed"
FINDINGS=()
ARTIFACTS=()

# Check for reward calculation patterns
REWARD_PATTERNS=(
  "rewardRate"
  "rewardPerToken"
  "rewardPerSecond"
  "rewardPerBlock"
  "rewardFormula"
)

for pattern in "${REWARD_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check for decay mechanisms
DECAY_PATTERNS=(
  "decay"
  "halving"
  "exponential"
  "linear"
  "diminishing"
)

for pattern in "${DECAY_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -li "$pattern" || true)
  if [ -n "$FILES" ]; then
    ARTIFACTS+=("$pattern")
  fi
done

# Check reward calculation files
REWARD_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "reward" || true)

if [ -n "$REWARD_FILES" ]; then
  while IFS= read -r file; do
    # Check for time-based rewards
    if grep -q "block\|timestamp\|block\.number" "$file"; then
      FINDINGS+=("Time-based reward mechanism detected: $file")
    fi

    # Check for accumulated reward tracking
    if ! grep -q "accumulatedReward\|pendingReward\|claimableReward\|earnedReward" "$file"; then
      FINDINGS+=("$file: no accumulated reward tracking")
      STATUS="warn"
    fi

    # Check for multiplication overflow protection
    if grep -E "reward.*\*|multiply" "$file"; then
      if ! grep -q "safeMultiply\|mul.*safe\|mulDiv\|FullMath" "$file"; then
        FINDINGS+=("$file: reward multiplication without overflow protection")
        STATUS="fail"
      fi
    fi

    # Check for division precision
    if grep -E "reward.*\/|divide" "$file"; then
      if ! grep -q "safeDivide\|mulDiv\|FullMath\|precision" "$file"; then
        FINDINGS+=("$file: reward division without precision handling")
        STATUS="warn"
      fi
    fi

    # Check for reward formula clarity
    if grep -q "reward.*=.*[0-9]" "$file"; then
      FINDINGS+=("Hardcoded reward formula in: $file")
      STATUS="warn"
    fi
  done <<< "$REWARD_FILES"
fi

# Check for exponential decay
EXP_DECAY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "exp|power|\^|exponent" || true)

if [ -n "$EXP_DECAY" ]; then
  ARTIFACTS+=("exponential-decay")
  FINDINGS+=("Exponential decay formula detected")
fi

# Check for linear decay
LINEAR_DECAY=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "linear|slope|per.*block|per.*second" || true)

if [ -n "$LINEAR_DECAY" ]; then
  ARTIFACTS+=("linear-decay")
  FINDINGS+=("Linear decay formula detected")
fi

# Check for halving mechanism
HALVING=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "halv|half|divide.*2|>>.*1" || true)

if [ -n "$HALVING" ]; then
  ARTIFACTS+=("halving-mechanism")
  FINDINGS+=("Halving mechanism detected")
fi

# Check for constant rewards
CONSTANT=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "constant.*reward|fixed.*reward|static.*reward" || true)

if [ -n "$CONSTANT" ]; then
  ARTIFACTS+=("constant-rewards")
else
  if [ -n "$REWARD_FILES" ]; then
    FINDINGS+=("No constant reward period detected - rewards always decay")
    STATUS="warn"
  fi
fi

# Check for minimum reward floor
FLOOR=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "minReward|floorReward|rewardFloor" || true)

if [ -n "$FLOOR" ]; then
  ARTIFACTS+=("reward-floor")
  FINDINGS+=("Reward floor/minimum detected")
fi

# Check for cap on total rewards
CAP=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "maxTotalReward|totalRewardCap|rewardCap" || true)

if [ -n "$CAP" ]; then
  ARTIFACTS+=("reward-cap")
else
  if [ -n "$REWARD_FILES" ]; then
    FINDINGS+=("No cap on total rewards - unbounded supply risk")
    STATUS="warn"
  fi
fi

# Check for reward schedule (time-based phases)
SCHEDULE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "phase|epoch|season|period.*reward" || true)

if [ -n "$SCHEDULE" ]; then
  ARTIFACTS+=("reward-schedule")
  FINDINGS+=("Reward schedule with phases/epochs detected")
fi

# Check for reward formula documentation
DOCS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "// reward|/\* reward" || true)

if [ -z "$DOCS" ]; then
  if [ -n "$REWARD_FILES" ]; then
    FINDINGS+=("No inline documentation of reward formulas")
    STATUS="warn"
  fi
fi

# Check for emergency reward adjustment
ADJUST=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "updateReward|setReward|adjustReward" || true)

if [ -n "$ADJUST" ]; then
  ARTIFACTS+=("reward-adjustment")

  while IFS= read -r file; do
    # Check if adjustment has guards
    if ! grep -B 3 "updateReward\|setReward\|adjustReward" "$file" | grep -q "onlyOwner\|onlyAdmin\|timelock"; then
      FINDINGS+=("$file: reward adjustment without proper guards")
      STATUS="warn"
    fi
  done <<< "$REWARD_FILES"
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
  "skill":"reward-curve-simulator",
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
