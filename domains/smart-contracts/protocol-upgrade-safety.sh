#!/usr/bin/env bash
# Skill 45: Protocol Upgrade Safety
# Validates multi-contract upgrade safety and coordination
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Protocol upgrade safety validated"
FINDINGS=()
UPGRADEABLE_CONTRACTS=()
UPGRADE_MECHANISMS=()
COORDINATION_RISKS=()
STORAGE_RISKS=()
TIMELOCK_PROTECTION=()

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for upgrade safety analysis"
else
  # Analyze each file for upgrade patterns
  while IFS= read -r file; do

    # Detect upgradeable proxy patterns
    if grep -qE "UUPSUpgradeable|TransparentUpgradeableProxy|upgradeTo|upgradeToAndCall" "$file" 2>/dev/null; then
      UPGRADEABLE_CONTRACTS+=("$file - Upgradeable contract detected")

      # Check upgrade authorization
      upgrade_funcs=$(grep -nE "function.*upgradeTo|function.*_authorizeUpgrade" "$file" 2>/dev/null || echo "")
      if [ -n "$upgrade_funcs" ]; then
        while IFS= read -r line; do
          line_num=$(echo "$line" | cut -d: -f1)
          func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
          UPGRADE_MECHANISMS+=("$file:$line_num - $func_name")

          # Verify access control on upgrade functions
          func_body=$(sed -n "${line_num},$((line_num + 10))p" "$file" 2>/dev/null || echo "")
          if ! echo "$func_body" | grep -qE "onlyOwner|onlyRole|onlyAdmin|onlyGovernance"; then
            COORDINATION_RISKS+=("$file:$line_num - $func_name lacks access control")
            STATUS="fail"
          fi

          # Check for timelock protection
          if echo "$func_body" | grep -qE "timelock|delay"; then
            TIMELOCK_PROTECTION+=("$file:$line_num - $func_name has timelock protection")
          elif [ "$STATUS" != "fail" ]; then
            COORDINATION_RISKS+=("$file:$line_num - $func_name missing timelock (instant upgrades risky)")
            STATUS="warn"
          fi
        done <<< "$upgrade_funcs"
      fi

      # Check for storage gaps
      if ! grep -qE "__gap|uint256\[.*\] private __gap" "$file"; then
        STORAGE_RISKS+=("$file - Missing storage gap for upgrade safety")
        STATUS="warn"
      fi

      # Check for initializer protection
      if grep -qE "function initialize|initializer modifier" "$file"; then
        if ! grep -qE "initializer|_disableInitializers" "$file"; then
          STORAGE_RISKS+=("$file - Initialize function without proper protection")
          STATUS="fail"
        fi
      fi
    fi

    # Detect beacon proxy patterns
    if grep -qE "BeaconProxy|UpgradeableBeacon" "$file" 2>/dev/null; then
      FINDINGS+=("$file - Beacon proxy pattern detected")

      # Verify beacon upgrade is protected
      if ! grep -qE "onlyOwner|onlyRole" "$file"; then
        COORDINATION_RISKS+=("$file - Beacon upgrade lacks access control")
        STATUS="warn"
      fi
    fi

    # Check for multi-contract upgrade coordination
    if grep -qE "registry|manager|controller" "$file" 2>/dev/null; then
      # Look for upgrade coordination logic
      if grep -qE "upgradeAll|batchUpgrade|upgradeContracts" "$file"; then
        FINDINGS+=("$file - Multi-contract upgrade coordinator detected")

        # Verify atomic upgrade capability
        if ! grep -qE "revert|require.*success" "$file"; then
          COORDINATION_RISKS+=("$file - Multi-contract upgrade may not be atomic")
          STATUS="warn"
        fi
      fi
    fi

    # Detect version tracking
    if grep -qE "version|VERSION|getVersion" "$file" 2>/dev/null; then
      FINDINGS+=("$file - Version tracking implemented")
    fi

  done <<< "$SOL_FILES"

  # Build findings summary
  if [ ${#UPGRADEABLE_CONTRACTS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#UPGRADEABLE_CONTRACTS[@]} upgradeable contract(s)")
  fi

  if [ ${#UPGRADE_MECHANISMS[@]} -gt 0 ]; then
    FINDINGS+=("Detected ${#UPGRADE_MECHANISMS[@]} upgrade mechanism(s)")
  fi

  if [ ${#TIMELOCK_PROTECTION[@]} -gt 0 ]; then
    FINDINGS+=("${#TIMELOCK_PROTECTION[@]} upgrade(s) with timelock protection")
  fi

  if [ ${#STORAGE_RISKS[@]} -gt 0 ]; then
    FINDINGS+=("WARNING: ${#STORAGE_RISKS[@]} storage safety issue(s)")
    for risk in "${STORAGE_RISKS[@]}"; do
      FINDINGS+=("  - $risk")
    done
  fi

  if [ ${#COORDINATION_RISKS[@]} -gt 0 ]; then
    FINDINGS+=("CRITICAL: ${#COORDINATION_RISKS[@]} upgrade coordination risk(s)")
    for risk in "${COORDINATION_RISKS[@]}"; do
      FINDINGS+=("  - $risk")
    done
  fi

  # Update summary
  if [ "$STATUS" = "fail" ]; then
    SUMMARY="CRITICAL - Upgrade safety violations detected"
  elif [ "$STATUS" = "warn" ]; then
    SUMMARY="Upgrade safety warnings - ${#COORDINATION_RISKS[@]} risks, ${#STORAGE_RISKS[@]} storage issues"
  elif [ ${#UPGRADEABLE_CONTRACTS[@]} -eq 0 ]; then
    SUMMARY="No upgradeable contracts detected"
  else
    SUMMARY="Protocol upgrade safety validated - no critical issues"
  fi
fi

# Build JSON arrays
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
  "skill":"protocol-upgrade-safety",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "upgradeable_contracts":${#UPGRADEABLE_CONTRACTS[@]},
    "upgrade_mechanisms":${#UPGRADE_MECHANISMS[@]},
    "timelock_protection":${#TIMELOCK_PROTECTION[@]},
    "storage_risks":${#STORAGE_RISKS[@]},
    "coordination_risks":${#COORDINATION_RISKS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
