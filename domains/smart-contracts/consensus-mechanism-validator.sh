#!/usr/bin/env bash
# Skill 41: Consensus Mechanism Validator
# Validates consensus and finality mechanisms in protocols (PoS, voting, quorum)
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Consensus mechanisms validated"
FINDINGS=()
VOTING_MECHANISMS=()
QUORUM_CHECKS=()
FINALITY_PATTERNS=()
SLASHING_CONDITIONS=()
CONSENSUS_RISKS=()

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for consensus validation"
else
  # Analyze each Solidity file for consensus patterns
  while IFS= read -r file; do

    # Detect voting mechanisms
    if grep -qE "function.*vote|function.*propose|Proposal|Vote" "$file" 2>/dev/null; then
      voting_funcs=$(grep -nE "function.*(vote|propose|castVote)" "$file" 2>/dev/null || echo "")
      if [ -n "$voting_funcs" ]; then
        while IFS= read -r line; do
          line_num=$(echo "$line" | cut -d: -f1)
          func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
          VOTING_MECHANISMS+=("$file:$line_num - $func_name")
        done <<< "$voting_funcs"
      fi
    fi

    # Detect quorum checks
    if grep -qE "quorum|threshold|majority" "$file" 2>/dev/null; then
      quorum_checks=$(grep -nE "quorum|threshold.*reached|require.*>=.*quorum" "$file" 2>/dev/null || echo "")
      if [ -n "$quorum_checks" ]; then
        while IFS= read -r line; do
          line_num=$(echo "$line" | cut -d: -f1)
          check=$(echo "$line" | sed 's/^[^:]*://;s/^[ \t]*//' | head -c 80)
          QUORUM_CHECKS+=("$file:$line_num - $check")

          # Validate quorum has bounds checking
          if ! echo "$line" | grep -qE "require|assert"; then
            CONSENSUS_RISKS+=("$file:$line_num - Quorum check without require/assert")
            STATUS="warn"
          fi
        done <<< "$quorum_checks"
      fi
    fi

    # Detect finality patterns
    if grep -qE "finalized|finality|confirmed|executed" "$file" 2>/dev/null; then
      finality_patterns=$(grep -nE "bool.*finalized|state.*Finalized|function.*finalize" "$file" 2>/dev/null || echo "")
      if [ -n "$finality_patterns" ]; then
        while IFS= read -r line; do
          line_num=$(echo "$line" | cut -d: -f1)
          pattern=$(echo "$line" | sed 's/^[^:]*://;s/^[ \t]*//' | head -c 80)
          FINALITY_PATTERNS+=("$file:$line_num - $pattern")
        done <<< "$finality_patterns"
      fi
    fi

    # Detect slashing conditions (for PoS systems)
    if grep -qE "slash|penalty|penalize|stake.*burn" "$file" 2>/dev/null; then
      slashing=$(grep -nE "function.*slash|function.*penalize" "$file" 2>/dev/null || echo "")
      if [ -n "$slashing" ]; then
        while IFS= read -r line; do
          line_num=$(echo "$line" | cut -d: -f1)
          func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
          SLASHING_CONDITIONS+=("$file:$line_num - $func_name")

          # Check if slashing has access control
          func_body=$(sed -n "${line_num},$((line_num + 10))p" "$file" 2>/dev/null || echo "")
          if ! echo "$func_body" | grep -qE "onlyOwner|onlyRole|onlyValidator"; then
            CONSENSUS_RISKS+=("$file:$line_num - Slashing function without access control")
            STATUS="fail"
          fi
        done <<< "$slashing"
      fi
    fi

    # Check for validator/staker management
    if grep -qE "validator|staker|delegator" "$file" 2>/dev/null; then
      # Verify proper stake tracking
      if ! grep -qE "mapping.*stake|uint.*stake|totalStaked" "$file"; then
        CONSENSUS_RISKS+=("$file - Validator/staker pattern without stake tracking")
        STATUS="warn"
      fi
    fi

    # Detect time-based consensus (timelock, delay)
    if grep -qE "timelock|delay.*execute|TimelockController" "$file" 2>/dev/null; then
      timelock=$(grep -nE "delay|timelock" "$file" 2>/dev/null | head -3 || echo "")
      if [ -n "$timelock" ]; then
        FINDINGS+=("$file - Timelock pattern detected (consensus delay mechanism)")

        # Check if delay is configurable
        if ! grep -qE "function.*setDelay|delay.*immutable" "$file"; then
          CONSENSUS_RISKS+=("$file - Timelock delay is mutable without protection")
          STATUS="warn"
        fi
      fi
    fi

    # Check for multi-sig patterns
    if grep -qE "MultiSig|multisig|requiredSignatures|confirmTransaction" "$file" 2>/dev/null; then
      multisig=$(grep -nE "requiredSignatures|threshold|confirmTransaction" "$file" 2>/dev/null || echo "")
      if [ -n "$multisig" ]; then
        FINDINGS+=("$file - Multi-signature consensus pattern detected")

        # Validate threshold logic
        if grep -qE "threshold.*=.*0|requiredSignatures.*=.*0" "$file"; then
          CONSENSUS_RISKS+=("$file - Multi-sig threshold can be set to zero")
          STATUS="fail"
        fi
      fi
    fi

    # Check for checkpoint/epoch mechanisms
    if grep -qE "checkpoint|epoch|era" "$file" 2>/dev/null; then
      checkpoint=$(grep -nE "function.*checkpoint|currentEpoch|updateEpoch" "$file" 2>/dev/null || echo "")
      if [ -n "$checkpoint" ]; then
        FINDINGS+=("$file - Checkpoint/epoch consensus mechanism detected")
      fi
    fi

    # Validate double-voting prevention
    if [ ${#VOTING_MECHANISMS[@]} -gt 0 ]; then
      # Check for hasVoted tracking
      if ! grep -qE "mapping.*hasVoted|mapping.*voted|alreadyVoted" "$file"; then
        CONSENSUS_RISKS+=("$file - Voting mechanism without double-vote prevention")
        STATUS="warn"
      fi
    fi

  done <<< "$SOL_FILES"

  # Build findings summary
  if [ ${#VOTING_MECHANISMS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#VOTING_MECHANISMS[@]} voting mechanism(s)")
  fi

  if [ ${#QUORUM_CHECKS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#QUORUM_CHECKS[@]} quorum check(s)")
  else
    if [ ${#VOTING_MECHANISMS[@]} -gt 0 ]; then
      CONSENSUS_RISKS+=("Voting mechanisms found but no quorum checks detected")
      STATUS="warn"
    fi
  fi

  if [ ${#FINALITY_PATTERNS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#FINALITY_PATTERNS[@]} finality pattern(s)")
  fi

  if [ ${#SLASHING_CONDITIONS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#SLASHING_CONDITIONS[@]} slashing condition(s)")
  fi

  if [ ${#CONSENSUS_RISKS[@]} -gt 0 ]; then
    FINDINGS+=("CRITICAL: ${#CONSENSUS_RISKS[@]} consensus risk(s) detected")
    for risk in "${CONSENSUS_RISKS[@]}"; do
      FINDINGS+=("  - $risk")
    done
  fi

  # Update summary
  if [ "$STATUS" = "fail" ]; then
    SUMMARY="Critical consensus vulnerabilities - ${#CONSENSUS_RISKS[@]} risks detected"
  elif [ "$STATUS" = "warn" ]; then
    SUMMARY="Consensus validation complete - ${#CONSENSUS_RISKS[@]} warnings"
  elif [ ${#VOTING_MECHANISMS[@]} -eq 0 ] && [ ${#SLASHING_CONDITIONS[@]} -eq 0 ]; then
    SUMMARY="No consensus mechanisms detected"
    STATUS="pass"
  else
    SUMMARY="Consensus mechanisms validated - no critical issues"
  fi
fi

# Build JSON array for findings
if [ ${#FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="["
  first=true
  for f in "${FINDINGS[@]}"; do
    escaped=$(echo "$f" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    if [ "$first" = true ]; then
      FINDINGS_JSON="${FINDINGS_JSON}\"$escaped\""
      first=false
    else
      FINDINGS_JSON="${FINDINGS_JSON},\"$escaped\""
    fi
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

# Build consensus risks JSON
if [ ${#CONSENSUS_RISKS[@]} -eq 0 ]; then
  RISKS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  RISKS_JSON=$(printf '%s\n' "${CONSENSUS_RISKS[@]}" | jq -R . | jq -s .)
else
  RISKS_JSON="["
  first=true
  for r in "${CONSENSUS_RISKS[@]}"; do
    escaped=$(echo "$r" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    if [ "$first" = true ]; then
      RISKS_JSON="${RISKS_JSON}\"$escaped\""
      first=false
    else
      RISKS_JSON="${RISKS_JSON},\"$escaped\""
    fi
  done
  RISKS_JSON="${RISKS_JSON}]"
fi

cat <<JSON
{
  "skill":"consensus-mechanism-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "voting_mechanisms":${#VOTING_MECHANISMS[@]},
    "quorum_checks":${#QUORUM_CHECKS[@]},
    "finality_patterns":${#FINALITY_PATTERNS[@]},
    "slashing_conditions":${#SLASHING_CONDITIONS[@]},
    "consensus_risks":$RISKS_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
