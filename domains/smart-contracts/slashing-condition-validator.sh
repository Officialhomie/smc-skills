#!/usr/bin/env bash
# Skill 67: Slashing Condition Validator
# Validates slashing conditions in PoS systems
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="PoS slashing conditions validated"
SLASHING_FINDINGS=()

# Check for PoS/staking contracts
STAKING_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "stake\|Stake\|staking\|validator\|Validator" || true)

if [ -n "$STAKING_FILES" ]; then
  while IFS= read -r file; do
    SLASHING_FINDINGS+=("$file: Staking/validator contract detected")

    # Check for slashing mechanism
    if grep -q "slash\|Slash\|penalty\|fine"; then
      SLASHING_FINDINGS+=("$file: Slashing mechanism implemented")

      # Check for slashing conditions
      SLASHING_CONDITIONS=(
        "doubleSign\|double_sign"
        "equivocation"
        "downtime\|offline"
        "misbehavior\|misconduct"
        "failure"
        "malicious"
      )

      FOUND_CONDITIONS=0

      for condition in "${SLASHING_CONDITIONS[@]}"; do
        if grep -q "$condition" "$file"; then
          SLASHING_FINDINGS+=("$file: Slashing condition found: $condition")
          FOUND_CONDITIONS=$((FOUND_CONDITIONS + 1))
        fi
      done

      if [ "$FOUND_CONDITIONS" -eq 0 ]; then
        SLASHING_FINDINGS+=("$file: Slashing mechanism without explicit conditions defined")
        STATUS="warn"
      fi
    else
      SLASHING_FINDINGS+=("$file: No slashing mechanism detected (PoS requires slashing)")
      STATUS="warn"
    fi

    # Check for evidence submission
    if grep -q "evidence\|proof\|prove" "$file"; then
      SLASHING_FINDINGS+=("$file: Evidence/proof mechanism for slashing detected")

      # Check if evidence validation is protected
      if ! grep -q "require.*evidence\|validate.*evidence"; then
        SLASHING_FINDINGS+=("$file: Evidence submission without validation")
        STATUS="warn"
      fi
    else
      SLASHING_FINDINGS+=("$file: No evidence submission mechanism (recommend for decentralization)")
      STATUS="warn"
    fi

    # Check for slashing amount/percentage
    if grep -q "slashAmount\|slash.*percent\|slash.*fraction"; then
      SLASHING_FINDINGS+=("$file: Slashing amount configurable")

      # Check if slashing amount has limits
      if ! grep -q "MAX.*SLASH\|maxSlash\|percentage.*<\|fraction.*<"; then
        SLASHING_FINDINGS+=("$file: Slashing amount without upper limit")
        STATUS="warn"
      fi
    else
      SLASHING_FINDINGS+=("$file: No slashing amount configuration")
      STATUS="warn"
    fi
  done <<< "$STAKING_FILES"
else
  SLASHING_FINDINGS+=("No staking/validator contracts detected")
fi

# Check for validator registration and removal
VALIDATOR_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "validator\|Validator" || true)

if [ -n "$VALIDATOR_FILES" ]; then
  while IFS= read -r file; do
    # Check for validator registration
    if grep -q "register\|joinValidator\|becomeValidator"; then
      SLASHING_FINDINGS+=("$file: Validator registration mechanism detected")

      # Check for registration requirements
      if ! grep -q "require.*stake\|require.*minimum\|require.*bond"; then
        SLASHING_FINDINGS+=("$file: Validator registration without stake requirement")
        STATUS="warn"
      fi
    fi

    # Check for validator removal
    if grep -q "remove.*validator\|kick\|eject\|deactivate"; then
      SLASHING_FINDINGS+=("$file: Validator removal mechanism detected")

      # Check if removal is protected
      if ! grep -q "onlyGovernance\|onlyAdmin\|require.*slash"; then
        SLASHING_FINDINGS+=("$file: Validator removal without authorization")
        STATUS="warn"
      fi
    fi

    # Check for validator state tracking
    if grep -q "validatorStatus\|validator.*state\|Status"; then
      SLASHING_FINDINGS+=("$file: Validator state tracking implemented")
    fi
  done <<< "$VALIDATOR_FILES"
fi

# Check for appeal/dispute mechanism
APPEAL_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "appeal\|dispute\|challenge\|contest" || true)

if [ -n "$APPEAL_FILES" ]; then
  while IFS= read -r file; do
    SLASHING_FINDINGS+=("$file: Appeal/dispute mechanism for slashing detected")

    # Check if appeals are time-limited
    if ! grep -q "appealPeriod\|disputeDeadline\|challengeDeadline"; then
      SLASHING_FINDINGS+=("$file: Appeal without time limits")
      STATUS="warn"
    fi

    # Check if appeals require evidence
    if ! grep -q "evidence\|proof\|argue"; then
      SLASHING_FINDINGS+=("$file: Appeal without evidence submission requirement")
      STATUS="warn"
    fi
  done <<< "$APPEAL_FILES"
else
  SLASHING_FINDINGS+=("No appeal/dispute mechanism found (recommend for fairness)")
  STATUS="warn"
fi

# Check for slashing history tracking
HISTORY_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "history\|log\|record\|slash.*count" || true)

if [ -n "$HISTORY_FILES" ]; then
  while IFS= read -r file; do
    # Check if slashing history is tracked
    if grep -q "slashingHistory\|slash.*count\|offenses\|violations"; then
      SLASHING_FINDINGS+=("$file: Slashing history/record tracking implemented")
    fi
  done <<< "$HISTORY_FILES"
fi

# Check for slashing rationale/documentation
SLASHING_DOCS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "slash\|penalty" 2>/dev/null || true)

if [ -n "$SLASHING_DOCS" ]; then
  SLASHING_FINDINGS+=("Slashing conditions documented")
else
  SLASHING_FINDINGS+=("No slashing rationale/documentation found")
  STATUS="warn"
fi

# Check for slashing event emission
SLASHING_EVENTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emit.*Slash\|emit.*Penalty" || true)

if [ -n "$SLASHING_EVENTS" ]; then
  while IFS= read -r file; do
    EVENT_COUNT=$(grep -c "emit.*Slash\|emit.*Penalty" "$file" || echo "0")

    SLASHING_FINDINGS+=("$file: $EVENT_COUNT slashing event(s) defined")
  done <<< "$SLASHING_EVENTS"
else
  SLASHING_FINDINGS+=("No slashing events found (recommend adding for auditability)")
  STATUS="warn"
fi

# Check for slashing fund/treasury
TREASURY_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "treasury\|slashingFund\|penalty.*pool" || true)

if [ -n "$TREASURY_FILES" ]; then
  while IFS= read -r file; do
    SLASHING_FINDINGS+=("$file: Slashing fund/treasury detected")

    # Check if fund is protected
    if ! grep -q "onlyGovernance\|onlyOwner\|timelock" "$file"; then
      SLASHING_FINDINGS+=("$file: Slashing fund without withdrawal protection")
      STATUS="warn"
    fi
  done <<< "$TREASURY_FILES"
fi

# Check for downtime tracking (for downtime slashing)
DOWNTIME_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "downtime\|offline\|miss\|block.*sign" || true)

if [ -n "$DOWNTIME_FILES" ]; then
  while IFS= read -r file; do
    SLASHING_FINDINGS+=("$file: Downtime tracking mechanism detected")

    # Check for downtime threshold
    if ! grep -q "downtimeThreshold\|maxMissed\|threshold"; then
      SLASHING_FINDINGS+=("$file: Downtime slashing without threshold")
      STATUS="warn"
    fi
  done <<< "$DOWNTIME_FILES"
fi

# Check for double-signing detection
DOUBLE_SIGN_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "doubleSign\|double.*sign\|equivocation" || true)

if [ -n "$DOUBLE_SIGN_FILES" ]; then
  while IFS= read -r file; do
    SLASHING_FINDINGS+=("$file: Double-signing detection implemented")

    # Check if detection validates signatures
    if ! grep -q "signature\|verify\|hash"; then
      SLASHING_FINDINGS+=("$file: Double-signing detection without signature verification")
      STATUS="warn"
    fi
  done <<< "$DOUBLE_SIGN_FILES"
fi

# Build JSON array
if [ ${#SLASHING_FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${SLASHING_FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${SLASHING_FINDINGS[0]}\""
  for s in "${SLASHING_FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$s\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"slashing-condition-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "slashing_findings":$FINDINGS_JSON,
    "finding_count":${#SLASHING_FINDINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
