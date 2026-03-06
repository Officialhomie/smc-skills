#!/usr/bin/env bash
# Skill 64: Governance Proposal Monitor
# Monitors proposal creation and execution patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="governance proposal patterns analyzed"
GOVERNANCE_ISSUES=()

# Check for governance contract patterns
GOVERNANCE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "Governance\|Governor\|Proposer\|Voter" || true)

if [ -n "$GOVERNANCE_FILES" ]; then
  while IFS= read -r file; do
    GOVERNANCE_ISSUES+=("$file: Governance contract detected")

    # Check for proposal struct
    if grep -q "struct.*Proposal\|mapping.*Proposal"; then
      GOVERNANCE_ISSUES+=("$file: Proposal tracking implemented")

      # Check for required proposal fields
      if ! grep -q "proposer\|creator"; then
        GOVERNANCE_ISSUES+=("$file: Proposal missing 'proposer' field (track proposal origin)")
        STATUS="warn"
      fi

      if ! grep -q "startBlock\|startTime\|timestamp"; then
        GOVERNANCE_ISSUES+=("$file: Proposal missing timestamp field")
        STATUS="warn"
      fi

      if ! grep -q "endBlock\|endTime"; then
        GOVERNANCE_ISSUES+=("$file: Proposal missing deadline field")
        STATUS="warn"
      fi
    fi

    # Check for voting patterns
    if grep -q "function.*vote\|function.*castVote"; then
      GOVERNANCE_ISSUES+=("$file: Voting function detected")

      # Check for double-voting protection
      if ! grep -q "hasVoted\|voted\|mapping.*voted"; then
        GOVERNANCE_ISSUES+=("$file: No double-voting prevention detected")
        STATUS="fail"
      fi

      # Check for voting power validation
      if ! grep -q "votingPower\|voting_power\|balanceOf"; then
        GOVERNANCE_ISSUES+=("$file: No voting power validation found")
        STATUS="warn"
      fi
    fi

    # Check for voting delay
    if grep -q "castVote\|vote" "$file"; then
      if ! grep -q "votingDelay\|voting_delay"; then
        GOVERNANCE_ISSUES+=("$file: No voting delay implemented (recommend adding)")
        STATUS="warn"
      fi
    fi

    # Check for proposal execution
    if grep -q "execute\|executeProposal"; then
      # Check if execution is protected
      if ! grep -q "require.*passed\|require.*approved\|require.*succeeded"; then
        GOVERNANCE_ISSUES+=("$file: Proposal execution without passage requirement check")
        STATUS="fail"
      fi

      # Check for timelock
      if ! grep -q "timelock\|delay.*execution\|TimelockController"; then
        GOVERNANCE_ISSUES+=("$file: Proposal execution without timelock (recommend adding)")
        STATUS="warn"
      fi
    fi

    # Check for quorum requirements
    if ! grep -q "quorum\|Quorum"; then
      GOVERNANCE_ISSUES+=("$file: No quorum requirement detected")
      STATUS="warn"
    fi

    # Check for proposal threshold
    if ! grep -q "proposalThreshold\|proposal_threshold\|minProposalPower"; then
      GOVERNANCE_ISSUES+=("$file: No proposal creation threshold (DoS risk)")
      STATUS="warn"
    fi
  done <<< "$GOVERNANCE_FILES"
fi

# Check for voting token patterns
VOTING_TOKEN_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "voting.*token\|governanceToken\|GovernanceToken" || true)

if [ -n "$VOTING_TOKEN_FILES" ]; then
  while IFS= read -r file; do
    GOVERNANCE_ISSUES+=("$file: Governance token detected")

    # Check for delegation support
    if ! grep -q "delegate\|Delegation"; then
      GOVERNANCE_ISSUES+=("$file: Governance token without delegation support")
      STATUS="warn"
    fi

    # Check for snapshot/checkpoint mechanism
    if ! grep -q "checkpoint\|snapshot\|blockNumber\|_block"; then
      GOVERNANCE_ISSUES+=("$file: No voting power snapshot mechanism")
      STATUS="warn"
    fi
  done <<< "$VOTING_TOKEN_FILES"
fi

# Check for vote aggregation patterns
VOTE_COUNTING_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "forVotes\|againstVotes\|abstainVotes\|_countVote" || true)

if [ -n "$VOTE_COUNTING_FILES" ]; then
  while IFS= read -r file; do
    # Check if vote tallying is consistent
    VOTE_TYPES=$(grep -c "forVotes\|againstVotes\|abstainVotes" "$file" || echo "0")

    if [ "$VOTE_TYPES" -gt 0 ]; then
      GOVERNANCE_ISSUES+=("$file: Multi-option voting detected ($VOTE_TYPES vote types)")

      # Check if voting results are checked properly
      if ! grep -q "forVotes.*>\|forVotes.*>="; then
        GOVERNANCE_ISSUES+=("$file: Vote comparison logic may be incomplete")
        STATUS="warn"
      fi
    fi
  done <<< "$VOTE_COUNTING_FILES"
fi

# Check for proposal state tracking
STATE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "ProposalState\|proposalState\|status" || true)

if [ -n "$STATE_FILES" ]; then
  while IFS= read -r file; do
    # Check for state enum
    if grep -q "enum.*ProposalState\|enum.*State"; then
      STATE_COUNT=$(grep -E "enum.*State.*{" -A10 "$file" | grep -c "[A-Z]" || echo "0")

      if [ "$STATE_COUNT" -lt 3 ]; then
        GOVERNANCE_ISSUES+=("$file: Limited proposal states ($STATE_COUNT) - consider more transitions")
        STATUS="warn"
      fi

      # Check for common states
      REQUIRED_STATES=("Pending" "Active" "Executed" "Defeated" "Canceled")

      for state in "${REQUIRED_STATES[@]}"; do
        if ! grep -q "$state"; then
          GOVERNANCE_ISSUES+=("$file: Missing '$state' proposal state")
          STATUS="warn"
        fi
      done
    fi
  done <<< "$STATE_FILES"
fi

# Check for governance access control
GOVERNANCE_ACCESS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "onlyGovernance\|onlyGovernor\|onlyProposer" || true)

if [ -n "$GOVERNANCE_ACCESS" ]; then
  while IFS= read -r file; do
    GOVERNANCE_ISSUES+=("$file: Governance-gated operations detected")
  done <<< "$GOVERNANCE_ACCESS"
fi

# Check for cancellation mechanism
CANCEL_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "cancel\|veto" || true)

if [ -n "$CANCEL_FILES" ]; then
  while IFS= read -r file; do
    # Check if cancel requires authorization
    CANCEL_LINES=$(grep -n "cancel\|veto" "$file" || true)

    while IFS= read -r line_info; do
      [ -z "$line_info" ] && continue

      LINE_NUM=$(echo "$line_info" | cut -d: -f1)
      CANCEL_CONTEXT=$(tail -n +$LINE_NUM "$file" | head -10)

      if ! echo "$CANCEL_CONTEXT" | grep -q "require\|onlyOwner\|onlyGovernance"; then
        GOVERNANCE_ISSUES+=("$file:$LINE_NUM: Proposal cancellation without authorization")
        STATUS="warn"
      fi
    done <<< "$CANCEL_LINES"
  done <<< "$CANCEL_FILES"
fi

# Build JSON array
if [ ${#GOVERNANCE_ISSUES[@]} -eq 0 ]; then
  ISSUES_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ISSUES_JSON=$(printf '%s\n' "${GOVERNANCE_ISSUES[@]}" | jq -R . | jq -s .)
else
  ISSUES_JSON="[\"${GOVERNANCE_ISSUES[0]}\""
  for g in "${GOVERNANCE_ISSUES[@]:1}"; do
    ISSUES_JSON="$ISSUES_JSON,\"$g\""
  done
  ISSUES_JSON="${ISSUES_JSON}]"
fi

cat <<JSON
{
  "skill":"governance-proposal-monitor",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "governance_issues":$ISSUES_JSON,
    "issue_count":${#GOVERNANCE_ISSUES[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
