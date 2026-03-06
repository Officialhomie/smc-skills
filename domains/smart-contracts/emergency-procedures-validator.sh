#!/usr/bin/env bash
# Skill 33: Emergency Procedures Validator
# Validates emergency mechanisms - pause, circuit breakers, emergency withdrawals, kill switches
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Emergency procedures validated"
FINDINGS=()
MISSING_PROCEDURES=()
PAUSE_MECHANISMS=()
CIRCUIT_BREAKERS=()
EMERGENCY_WITHDRAWALS=()
KILL_SWITCHES=()

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for emergency procedures analysis"
else
  # Analyze each Solidity file
  while IFS= read -r file; do

    # Check for pause mechanism
    if grep -qE "Pausable|whenNotPaused|whenPaused" "$file" 2>/dev/null; then
      PAUSE_MECHANISMS+=("$file - Pausable pattern detected")

      # Verify pause() and unpause() functions exist
      if grep -q "function pause()" "$file" 2>/dev/null; then
        # Check if pause has access control
        if grep -A 3 "function pause()" "$file" | grep -qE "onlyOwner|onlyRole|hasRole|onlyAdmin"; then
          FINDINGS+=("$file - pause() has proper access control")
        else
          MISSING_PROCEDURES+=("$file - pause() lacks access control")
          STATUS="warn"
        fi
      else
        MISSING_PROCEDURES+=("$file - Uses Pausable but no pause() function found")
        STATUS="warn"
      fi

      if grep -q "function unpause()" "$file" 2>/dev/null; then
        # Check if unpause has access control
        if grep -A 3 "function unpause()" "$file" | grep -qE "onlyOwner|onlyRole|hasRole|onlyAdmin"; then
          FINDINGS+=("$file - unpause() has proper access control")
        else
          MISSING_PROCEDURES+=("$file - unpause() lacks access control")
          STATUS="warn"
        fi
      else
        MISSING_PROCEDURES+=("$file - Uses Pausable but no unpause() function found")
        STATUS="warn"
      fi
    fi

    # Check for circuit breaker patterns
    if grep -qE "circuitBreaker|emergencyStop|stopped|locked" "$file" 2>/dev/null; then
      CIRCUIT_BREAKERS+=("$file - Circuit breaker pattern detected")
    fi

    # Check for emergency withdrawal functions
    emergency_withdraw=$(grep -nE "function.*(emergencyWithdraw|rescue|recover|evacuate)" "$file" 2>/dev/null || echo "")
    if [ -n "$emergency_withdraw" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')

        # Check if has access control
        if grep -A 5 "function.*$func_name" "$file" | grep -qE "onlyOwner|onlyRole|hasRole|onlyAdmin"; then
          EMERGENCY_WITHDRAWALS+=("$file:$line_num - $func_name (protected)")
        else
          EMERGENCY_WITHDRAWALS+=("$file:$line_num - $func_name (WARNING: no access control)")
          STATUS="warn"
        fi
      done <<< "$emergency_withdraw"
    fi

    # Check for kill switch / selfdestruct
    if grep -qE "selfdestruct|suicide" "$file" 2>/dev/null; then
      kill_switch_lines=$(grep -nE "selfdestruct|suicide" "$file" 2>/dev/null || echo "")
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)

        # Check if in a function with access control
        func_start=$(sed -n "1,${line_num}p" "$file" | grep -n "function" | tail -1 | cut -d: -f1)

        if [ -n "$func_start" ]; then
          func_def=$(sed -n "${func_start},$((func_start + 5))p" "$file")
          if echo "$func_def" | grep -qE "onlyOwner|onlyRole|hasRole"; then
            KILL_SWITCHES+=("$file:$line_num - selfdestruct protected by access control")
          else
            KILL_SWITCHES+=("$file:$line_num - WARNING: selfdestruct without access control")
            STATUS="fail"
          fi
        fi
      done <<< "$kill_switch_lines"
    fi

    # Check for reentrancy guards on emergency functions
    if [ ${#EMERGENCY_WITHDRAWALS[@]} -gt 0 ]; then
      if ! grep -q "nonReentrant\|ReentrancyGuard" "$file" 2>/dev/null; then
        MISSING_PROCEDURES+=("$file - Emergency withdrawals without reentrancy guard")
        if [ "$STATUS" = "pass" ]; then
          STATUS="warn"
        fi
      fi
    fi

  done <<< "$SOL_FILES"

  # Evaluate overall emergency readiness
  if [ ${#PAUSE_MECHANISMS[@]} -eq 0 ]; then
    MISSING_PROCEDURES+=("No pause mechanism found - consider implementing Pausable pattern")
    if [ "$STATUS" = "pass" ]; then
      STATUS="warn"
    fi
  else
    FINDINGS+=("Pause mechanisms: ${#PAUSE_MECHANISMS[@]} contract(s)")
  fi

  if [ ${#CIRCUIT_BREAKERS[@]} -eq 0 ]; then
    MISSING_PROCEDURES+=("No circuit breakers found - consider adding emergency stops")
    if [ "$STATUS" = "pass" ]; then
      STATUS="warn"
    fi
  else
    FINDINGS+=("Circuit breakers: ${#CIRCUIT_BREAKERS[@]} contract(s)")
  fi

  if [ ${#EMERGENCY_WITHDRAWALS[@]} -eq 0 ]; then
    MISSING_PROCEDURES+=("No emergency withdrawal functions - consider adding rescue mechanisms")
    if [ "$STATUS" = "pass" ]; then
      STATUS="warn"
    fi
  else
    FINDINGS+=("Emergency withdrawals: ${#EMERGENCY_WITHDRAWALS[@]} function(s)")
  fi

  if [ ${#KILL_SWITCHES[@]} -gt 0 ]; then
    FINDINGS+=("Kill switches (selfdestruct): ${#KILL_SWITCHES[@]} found")
  fi

  # Build comprehensive findings list
  if [ ${#MISSING_PROCEDURES[@]} -gt 0 ]; then
    FINDINGS+=("MISSING PROCEDURES:")
    for missing in "${MISSING_PROCEDURES[@]}"; do
      FINDINGS+=("  - $missing")
    done
  fi

  # Generate emergency runbook if build directory exists or can be created
  mkdir -p build 2>/dev/null || true

  if [ -d "build" ]; then
    RUNBOOK_FILE="build/emergency-runbook.md"

    cat > "$RUNBOOK_FILE" <<EOF
# Emergency Response Runbook

**Generated:** $(date -u +%FT%TZ)
**Project:** $(basename "$ROOT")

## Emergency Contacts

- **Security Team:** [Add contact info]
- **On-Call Developer:** [Add contact info]
- **Multisig Signers:** [Add signer list]

## Emergency Procedures

### 1. Pause Protocol

EOF

    if [ ${#PAUSE_MECHANISMS[@]} -gt 0 ]; then
      echo "**Status:** ✅ Pause mechanism implemented" >> "$RUNBOOK_FILE"
      echo "" >> "$RUNBOOK_FILE"
      printf '%s\n' "${PAUSE_MECHANISMS[@]}" | while IFS= read -r mech; do
        echo "- $mech" >> "$RUNBOOK_FILE"
      done
      echo "" >> "$RUNBOOK_FILE"
      echo "**Steps:**" >> "$RUNBOOK_FILE"
      echo "1. Identify the contract requiring pause" >> "$RUNBOOK_FILE"
      echo "2. Call \`pause()\` from authorized account" >> "$RUNBOOK_FILE"
      echo "3. Verify pause status on-chain" >> "$RUNBOOK_FILE"
      echo "4. Communicate pause to users" >> "$RUNBOOK_FILE"
    else
      echo "**Status:** ❌ No pause mechanism found" >> "$RUNBOOK_FILE"
      echo "" >> "$RUNBOOK_FILE"
      echo "**Recommendation:** Implement Pausable pattern from OpenZeppelin" >> "$RUNBOOK_FILE"
    fi

    cat >> "$RUNBOOK_FILE" <<EOF

### 2. Circuit Breakers

EOF

    if [ ${#CIRCUIT_BREAKERS[@]} -gt 0 ]; then
      echo "**Status:** ✅ Circuit breakers detected" >> "$RUNBOOK_FILE"
      echo "" >> "$RUNBOOK_FILE"
      printf '%s\n' "${CIRCUIT_BREAKERS[@]}" | while IFS= read -r cb; do
        echo "- $cb" >> "$RUNBOOK_FILE"
      done
    else
      echo "**Status:** ⚠️ No circuit breakers found" >> "$RUNBOOK_FILE"
      echo "" >> "$RUNBOOK_FILE"
      echo "**Recommendation:** Implement emergency stop mechanisms" >> "$RUNBOOK_FILE"
    fi

    cat >> "$RUNBOOK_FILE" <<EOF

### 3. Emergency Withdrawals

EOF

    if [ ${#EMERGENCY_WITHDRAWALS[@]} -gt 0 ]; then
      echo "**Status:** ✅ Emergency withdrawal functions available" >> "$RUNBOOK_FILE"
      echo "" >> "$RUNBOOK_FILE"
      printf '%s\n' "${EMERGENCY_WITHDRAWALS[@]}" | while IFS= read -r ew; do
        echo "- $ew" >> "$RUNBOOK_FILE"
      done
      echo "" >> "$RUNBOOK_FILE"
      echo "**Steps:**" >> "$RUNBOOK_FILE"
      echo "1. Assess the situation and determine affected assets" >> "$RUNBOOK_FILE"
      echo "2. Get multisig approval if required" >> "$RUNBOOK_FILE"
      echo "3. Call emergency withdrawal function" >> "$RUNBOOK_FILE"
      echo "4. Secure withdrawn funds" >> "$RUNBOOK_FILE"
      echo "5. Post-mortem analysis" >> "$RUNBOOK_FILE"
    else
      echo "**Status:** ❌ No emergency withdrawal mechanisms" >> "$RUNBOOK_FILE"
      echo "" >> "$RUNBOOK_FILE"
      echo "**Recommendation:** Add rescue functions for stuck tokens/ETH" >> "$RUNBOOK_FILE"
    fi

    cat >> "$RUNBOOK_FILE" <<EOF

### 4. Rollback Procedures

**Steps:**
1. Pause the affected contract
2. Document the current state
3. Prepare upgrade if contract is upgradeable
4. Test upgrade on testnet/fork
5. Execute upgrade via governance/multisig
6. Verify fix
7. Unpause contract
8. Monitor for 24-48 hours

### 5. Communication Plan

**Internal:**
- Notify security team immediately
- Brief all stakeholders
- Document all actions

**External:**
- Post-mortem blog post
- Twitter/Discord announcement
- Email to affected users
- Update documentation

## Incident Classification

| Severity | Response Time | Action |
|----------|---------------|--------|
| CRITICAL | Immediate | Pause all contracts, emergency withdrawal |
| HIGH | < 1 hour | Pause affected contracts |
| MEDIUM | < 4 hours | Monitor, prepare hotfix |
| LOW | < 24 hours | Schedule fix in next release |

## Post-Incident

- [ ] Root cause analysis
- [ ] Fix implementation
- [ ] Security audit of fix
- [ ] Testnet deployment and testing
- [ ] Mainnet deployment
- [ ] User communication
- [ ] Update runbook with lessons learned

---

**Last Updated:** $(date -u +%FT%TZ)
EOF

    FINDINGS+=("Emergency runbook generated at $RUNBOOK_FILE")
  fi

  # Update summary
  if [ "$STATUS" = "fail" ]; then
    SUMMARY="Critical emergency procedure gaps - ${#MISSING_PROCEDURES[@]} issues"
  elif [ "$STATUS" = "warn" ]; then
    SUMMARY="Emergency improvements needed - ${#MISSING_PROCEDURES[@]} missing procedures"
  else
    SUMMARY="Emergency procedures validated - comprehensive coverage"
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
  "skill":"emergency-procedures-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "pause_mechanisms":${#PAUSE_MECHANISMS[@]},
    "circuit_breakers":${#CIRCUIT_BREAKERS[@]},
    "emergency_withdrawals":${#EMERGENCY_WITHDRAWALS[@]},
    "kill_switches":${#KILL_SWITCHES[@]},
    "missing_procedures":${#MISSING_PROCEDURES[@]},
    "runbook_file":"build/emergency-runbook.md"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
