#!/usr/bin/env bash
# Skill 32: Governance Safety Checker
# Validates governance mechanisms, timelocks, multisig patterns, and centralization risks
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Governance safety validated"
FINDINGS=()
ADMIN_FUNCTIONS=()
CENTRALIZATION_RISKS=()
TIMELOCK_FINDINGS=()
MULTISIG_FINDINGS=()
GOVERNANCE_PARAMS=()

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for governance analysis"
else
  # Analyze each Solidity file
  while IFS= read -r file; do

    # Check for admin/owner functions
    admin_funcs=$(grep -nE "function.*(onlyOwner|onlyAdmin|onlyGovernance)" "$file" 2>/dev/null || echo "")
    if [ -n "$admin_funcs" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
        ADMIN_FUNCTIONS+=("$file:$line_num - $func_name (privileged)")
      done <<< "$admin_funcs"
    fi

    # Check for single owner pattern (centralization risk)
    if grep -q "Ownable\|onlyOwner" "$file" 2>/dev/null; then
      if ! grep -q "Ownable2Step\|transferOwnership.*timelock\|multisig" "$file" 2>/dev/null; then
        CENTRALIZATION_RISKS+=("$file - Uses Ownable without 2-step transfer or timelock")
        STATUS="warn"
      fi
    fi

    # Check for timelock usage
    if grep -q "TimelockController\|timelock\|delay.*execute" "$file" 2>/dev/null; then
      timelock_delay=$(grep -n "timelock.*delay\|delay.*=.*days\|delay.*=.*hours" "$file" 2>/dev/null || echo "")
      if [ -n "$timelock_delay" ]; then
        TIMELOCK_FINDINGS+=("$file - Timelock delay detected")
      else
        TIMELOCK_FINDINGS+=("$file - Timelock pattern found but delay not clearly defined")
        STATUS="warn"
      fi
    fi

    # Check for multisig patterns
    if grep -qE "quorum|threshold|MultiSigWallet|Gnosis.*Safe" "$file" 2>/dev/null; then
      threshold=$(grep -nE "threshold|quorum" "$file" 2>/dev/null || echo "")
      if [ -n "$threshold" ]; then
        while IFS= read -r line; do
          MULTISIG_FINDINGS+=("$file - Multisig threshold/quorum definition found")
        done <<< "$threshold"
      fi
    fi

    # Check for governance parameters (should have bounds)
    gov_params=$(grep -nE "function.*set[A-Z][a-zA-Z]*(Fee|Rate|Limit|Cap|Threshold)" "$file" 2>/dev/null || echo "")
    if [ -n "$gov_params" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')

        # Check if function has bounds validation (require statements)
        func_body=$(sed -n "${line_num},$((line_num + 30))p" "$file" 2>/dev/null || echo "")

        if echo "$func_body" | grep -qE "require.*<=|require.*>=|require.*<|require.*>" ; then
          GOVERNANCE_PARAMS+=("$file:$line_num - $func_name (has bounds validation)")
        else
          GOVERNANCE_PARAMS+=("$file:$line_num - $func_name (WARNING: missing bounds validation)")
          STATUS="warn"
        fi
      done <<< "$gov_params"
    fi

    # Check for emergency functions without multisig
    emergency_funcs=$(grep -nE "function.*(pause|unpause|emergency|withdraw|rescue)" "$file" 2>/dev/null || echo "")
    if [ -n "$emergency_funcs" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')

        # Check if only owner can call (single point of failure)
        if grep -A 5 "function.*$func_name" "$file" | grep -qE "onlyOwner" && \
           ! grep -q "multisig\|TimelockController" "$file"; then
          CENTRALIZATION_RISKS+=("$file:$line_num - $func_name controlled by single owner (no multisig)")
          STATUS="warn"
        fi
      done <<< "$emergency_funcs"
    fi

    # Check for upgradeability without governance
    if grep -qE "upgradeTo|upgradeToAndCall|UUPSUpgradeable" "$file" 2>/dev/null; then
      if ! grep -qE "timelock|multisig|governance|vote" "$file" 2>/dev/null; then
        CENTRALIZATION_RISKS+=("$file - Upgradeable contract without governance/timelock control")
        STATUS="fail"
      fi
    fi

    # Check for mint/burn without limits
    mint_burn=$(grep -nE "function.*(mint|burn)" "$file" 2>/dev/null || echo "")
    if [ -n "$mint_burn" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')

        func_body=$(sed -n "${line_num},$((line_num + 30))p" "$file" 2>/dev/null || echo "")

        # Check for mint cap or burn validation
        if ! echo "$func_body" | grep -qE "require.*cap|require.*maxSupply|require.*balance" ; then
          CENTRALIZATION_RISKS+=("$file:$line_num - $func_name has no supply cap or validation")
          STATUS="warn"
        fi
      done <<< "$mint_burn"
    fi

  done <<< "$SOL_FILES"

  # Build findings summary
  if [ ${#ADMIN_FUNCTIONS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#ADMIN_FUNCTIONS[@]} privileged admin functions")
  fi

  if [ ${#TIMELOCK_FINDINGS[@]} -gt 0 ]; then
    FINDINGS+=("Timelock mechanisms detected in ${#TIMELOCK_FINDINGS[@]} file(s)")
  else
    FINDINGS+=("WARNING: No timelock mechanisms found for admin actions")
    if [ "$STATUS" = "pass" ]; then
      STATUS="warn"
    fi
  fi

  if [ ${#MULTISIG_FINDINGS[@]} -gt 0 ]; then
    FINDINGS+=("Multisig patterns detected in ${#MULTISIG_FINDINGS[@]} file(s)")
  else
    FINDINGS+=("WARNING: No multisig patterns found")
    if [ "$STATUS" = "pass" ]; then
      STATUS="warn"
    fi
  fi

  if [ ${#CENTRALIZATION_RISKS[@]} -gt 0 ]; then
    FINDINGS+=("CRITICAL: ${#CENTRALIZATION_RISKS[@]} centralization risks detected")
    for risk in "${CENTRALIZATION_RISKS[@]}"; do
      FINDINGS+=("  - $risk")
    done
  fi

  if [ ${#GOVERNANCE_PARAMS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#GOVERNANCE_PARAMS[@]} governance parameter setters")
    # Count those without bounds
    unbounded=$(printf '%s\n' "${GOVERNANCE_PARAMS[@]}" | grep -c "WARNING" || echo "0")
    if [ "$unbounded" -gt 0 ]; then
      FINDINGS+=("WARNING: $unbounded parameter setters without bounds validation")
    fi
  fi

  # Update summary
  if [ "$STATUS" = "fail" ]; then
    SUMMARY="Critical governance issues detected - ${#CENTRALIZATION_RISKS[@]} centralization risks"
  elif [ "$STATUS" = "warn" ]; then
    SUMMARY="Governance improvements recommended - ${#CENTRALIZATION_RISKS[@]} risks, missing timelock/multisig"
  else
    SUMMARY="Governance safety validated - proper controls in place"
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

cat <<JSON
{
  "skill":"governance-safety-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "admin_functions":${#ADMIN_FUNCTIONS[@]},
    "centralization_risks":${#CENTRALIZATION_RISKS[@]},
    "timelock_usage":${#TIMELOCK_FINDINGS[@]},
    "multisig_patterns":${#MULTISIG_FINDINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
