#!/usr/bin/env bash
# Skill 74: Relayer Security Validator
# Audits relayer security patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="relayer security patterns validated"
FINDINGS=()

# Check for relayer/transaction submission contracts
RELAYER_CONTRACTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "relayer\|Relayer\|submit.*transaction\|relay" || true)

if [ -n "$RELAYER_CONTRACTS" ]; then
  while IFS= read -r file; do
    # Check for gas price validation
    if grep -q "relay\|submit.*transaction\|function.*relay" "$file"; then
      if ! grep -q "tx.gasprice\|gasPrice\|maxGasPrice\|GAS_PRICE" "$file"; then
        FINDINGS+=("$file: Relayer without gas price validation")
        STATUS="warn"
      fi
    fi

    # Check for nonce tracking to prevent out-of-order execution
    if grep -q "submit\|relay.*transaction" "$file"; then
      if ! grep -q "nonce\|sequence\|order\|strict.*order" "$file"; then
        FINDINGS+=("$file: Relayer without nonce/sequence tracking")
        STATUS="warn"
      fi
    fi

    # Check for destination validation
    if grep -q "relay.*to\|submit.*to\|target.*address" "$file"; then
      if ! grep -q "require.*target\|require.*address\|destination.*check" "$file"; then
        FINDINGS+=("$file: Relayer without destination validation")
        STATUS="warn"
      fi
    fi

    # Check for relayer fee mechanism
    if grep -q "function.*relay\|relay.*fee\|relayer.*reward" "$file"; then
      if ! grep -q "fee\|compensation\|reward\|reimburs" "$file"; then
        FINDINGS+=("$file: Relayer without fee/compensation mechanism")
        STATUS="warn"
      fi
    fi

    # Check for frontrunning protection
    if grep -q "relay.*transaction\|submit.*order" "$file"; then
      if ! grep -q "commit.*reveal\|batch\|timeout\|ordered" "$file"; then
        FINDINGS+=("$file: Relayer vulnerable to frontrunning")
        STATUS="warn"
      fi
    fi

    # Check for sender authorization
    if grep -q "function.*relay" "$file"; then
      if ! grep -q "require.*sender\|msg.sender.*authorized\|hasRole" "$file"; then
        FINDINGS+=("$file: Relayer without sender authorization")
        STATUS="fail"
      fi
    fi

    # Check for transaction deadline
    if grep -q "relay\|submit" "$file"; then
      if ! grep -q "deadline\|timeout\|block.timestamp\|expir" "$file"; then
        FINDINGS+=("$file: Relayer without transaction deadline validation")
        STATUS="warn"
      fi
    fi
  done <<< "$RELAYER_CONTRACTS"

  SUMMARY="relayer security validation completed"
fi

# Check for relayer configuration
RELAYER_CONFIG=$(find . -name "relayer*" -o -name "*relay*config*" 2>/dev/null | head -5)

if [ -n "$RELAYER_CONFIG" ]; then
  # Check for secure storage of keys
  if [ -f "$RELAYER_CONFIG" ]; then
    if grep -q "private.*key\|secret\|password" "$RELAYER_CONFIG"; then
      FINDINGS+=("$RELAYER_CONFIG: Potential secrets in configuration file")
      STATUS="fail"
    fi
  fi
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

cat <<JSON
{
  "skill":"relayer-security-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "relayer_contracts":"$(echo "$RELAYER_CONTRACTS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
