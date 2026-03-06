#!/usr/bin/env bash
# Skill 48: Protocol Governance Design Checker
# Validates governance mechanism design and safety
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Protocol governance design validated"
FINDINGS=()
GOVERNANCE_MECHANISMS=()
VOTING_POWER=()
PROPOSAL_VALIDATION=()
EXECUTION_DELAYS=()

SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found"
else
  while IFS= read -r file; do
    # Detect governance mechanisms
    if grep -qE "Governor|governance|propose|vote" "$file" 2>/dev/null; then
      GOVERNANCE_MECHANISMS+=("$file - Governance mechanism detected")

      # Check voting power distribution
      if grep -qE "votingPower|balanceOf|getVotes" "$file"; then
        VOTING_POWER+=("$file - Voting power tracking detected")
      fi

      # Check proposal validation
      if grep -qE "proposeThreshold|minimumQuorum" "$file"; then
        PROPOSAL_VALIDATION+=("$file - Proposal validation implemented")
      fi

      # Check execution delays
      if grep -qE "delay|timelock|votingPeriod" "$file"; then
        EXECUTION_DELAYS+=("$file - Execution delay mechanism")
      else
        STATUS="warn"
      fi
    fi
  done <<< "$SOL_FILES"

  FINDINGS+=("Governance mechanisms: ${#GOVERNANCE_MECHANISMS[@]}")
  FINDINGS+=("Voting power tracking: ${#VOTING_POWER[@]}")
  FINDINGS+=("Execution delays: ${#EXECUTION_DELAYS[@]}")

  if [ ${#GOVERNANCE_MECHANISMS[@]} -eq 0 ]; then
    SUMMARY="No governance mechanisms detected"
  elif [ ${#EXECUTION_DELAYS[@]} -eq 0 ]; then
    SUMMARY="Governance missing execution delays"
    STATUS="warn"
  else
    SUMMARY="Protocol governance design validated"
  fi
fi

FINDINGS_JSON="[]"
if [ ${#FINDINGS[@]} -gt 0 ] && command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
fi

cat <<JSON
{
  "skill":"protocol-governance-design-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "governance_mechanisms":${#GOVERNANCE_MECHANISMS[@]},
    "execution_delays":${#EXECUTION_DELAYS[@]}
  },
  "metadata":{"timestamp":"$(date -u +%FT%TZ)","runner":"local"}
}
JSON
