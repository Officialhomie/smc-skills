#!/usr/bin/env bash
# Skill 42: State Transition Safety
# Validates state machine security and transition logic
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="State transition safety validated"
FINDINGS=()
STATE_MACHINES=()
TRANSITIONS=()
STATE_VALIDATIONS=()
UNSAFE_TRANSITIONS=()
REENTRANCY_RISKS=()

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for state transition analysis"
else
  # Analyze each Solidity file for state machine patterns
  while IFS= read -r file; do

    # Detect enum-based state machines
    state_enums=$(grep -nE "enum.*(State|Status|Phase|Stage)" "$file" 2>/dev/null || echo "")
    if [ -n "$state_enums" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        enum_name=$(echo "$line" | sed -n 's/.*enum \([A-Za-z0-9_]*\).*/\1/p')
        STATE_MACHINES+=("$file:$line_num - Enum state machine: $enum_name")
      done <<< "$state_enums"
    fi

    # Detect state variable declarations
    state_vars=$(grep -nE "State public|Status public|Phase public|Stage public|currentState|status =" "$file" 2>/dev/null || echo "")
    if [ -n "$state_vars" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        var_name=$(echo "$line" | sed -n 's/.*\(State\|Status\|Phase\|currentState\).*/\1/p')
        STATE_MACHINES+=("$file:$line_num - State variable: $var_name")
      done <<< "$state_vars"
    fi

    # Detect state transition functions
    transition_funcs=$(grep -nE "function.*(transition|moveTo|changeTo|setState|setStatus)" "$file" 2>/dev/null || echo "")
    if [ -n "$transition_funcs" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
        TRANSITIONS+=("$file:$line_num - Transition function: $func_name")

        # Check if transition has state validation
        func_body=$(sed -n "${line_num},$((line_num + 20))p" "$file" 2>/dev/null || echo "")

        # Look for require statements validating current state
        if echo "$func_body" | grep -qE "require.*State|require.*status|require.*currentState"; then
          STATE_VALIDATIONS+=("$file:$line_num - $func_name has state validation")
        else
          UNSAFE_TRANSITIONS+=("$file:$line_num - $func_name lacks state precondition check")
          STATUS="warn"
        fi

        # Check for reentrancy protection on state transitions
        if echo "$func_body" | grep -qE "call\{|delegatecall|\.call\("; then
          if ! echo "$func_body" | grep -qE "nonReentrant|ReentrancyGuard"; then
            REENTRANCY_RISKS+=("$file:$line_num - $func_name performs external call without reentrancy guard")
            STATUS="fail"
          fi
        fi

        # Verify state is set before external calls (Checks-Effects-Interactions)
        # Extract lines before and after external calls
        if echo "$func_body" | grep -qE "\.call\{|\.transfer\(|\.send\("; then
          # Check if state update comes before external calls
          state_update_line=$(echo "$func_body" | grep -nE "State.*=|status.*=|currentState.*=" | head -1 | cut -d: -f1)
          external_call_line=$(echo "$func_body" | grep -nE "\.call\{|\.transfer\(|\.send\(" | head -1 | cut -d: -f1)

          if [ -n "$state_update_line" ] && [ -n "$external_call_line" ]; then
            if [ "$state_update_line" -gt "$external_call_line" ]; then
              UNSAFE_TRANSITIONS+=("$file:$line_num - $func_name updates state after external call (CEI violation)")
              STATUS="fail"
            fi
          fi
        fi
      done <<< "$transition_funcs"
    fi

    # Detect modifier-based state guards
    state_modifiers=$(grep -nE "modifier.*only[A-Z].*State|modifier.*when[A-Z].*State|modifier.*inState" "$file" 2>/dev/null || echo "")
    if [ -n "$state_modifiers" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        modifier_name=$(echo "$line" | sed -n 's/.*modifier \([^(]*\).*/\1/p')
        FINDINGS+=("$file:$line_num - State guard modifier: $modifier_name")

        # Verify modifier has require statement
        modifier_body=$(sed -n "${line_num},$((line_num + 5))p" "$file" 2>/dev/null || echo "")
        if ! echo "$modifier_body" | grep -qE "require|assert"; then
          UNSAFE_TRANSITIONS+=("$file:$line_num - Modifier $modifier_name lacks require/assert")
          STATUS="warn"
        fi
      done <<< "$state_modifiers"
    fi

    # Check for pause state implementation
    if grep -qE "whenNotPaused|whenPaused|Pausable" "$file" 2>/dev/null; then
      FINDINGS+=("$file - Pausable state pattern detected (emergency state)")
    fi

    # Detect time-based state transitions
    if grep -qE "block\.timestamp.*>|now.*>" "$file" 2>/dev/null; then
      time_transitions=$(grep -nE "block\.timestamp.*>|now.*>" "$file" 2>/dev/null || echo "")
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        condition=$(echo "$line" | sed 's/^[^:]*://;s/^[ \t]*//' | head -c 60)
        FINDINGS+=("$file:$line_num - Time-based transition: $condition")

        # Warn about block.timestamp manipulation
        if echo "$line" | grep -qE "block\.timestamp.*=="; then
          UNSAFE_TRANSITIONS+=("$file:$line_num - Using == for timestamp comparison (unsafe)")
          STATUS="warn"
        fi
      done <<< "$time_transitions"
    fi

    # Check for initialization state
    if grep -qE "initialized|initializer|initialize\(" "$file" 2>/dev/null; then
      init_check=$(grep -nE "require.*!initialized|require.*initialized.*false" "$file" 2>/dev/null || echo "")
      if [ -z "$init_check" ]; then
        if grep -qE "function.*initialize\(" "$file"; then
          UNSAFE_TRANSITIONS+=("$file - Initialize function without double-init protection")
          STATUS="fail"
        fi
      fi
    fi

  done <<< "$SOL_FILES"

  # Build findings summary
  if [ ${#STATE_MACHINES[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#STATE_MACHINES[@]} state machine(s)")
  fi

  if [ ${#TRANSITIONS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#TRANSITIONS[@]} state transition function(s)")
  fi

  if [ ${#STATE_VALIDATIONS[@]} -gt 0 ]; then
    FINDINGS+=("${#STATE_VALIDATIONS[@]} transition(s) have proper state validation")
  fi

  if [ ${#REENTRANCY_RISKS[@]} -gt 0 ]; then
    FINDINGS+=("CRITICAL: ${#REENTRANCY_RISKS[@]} reentrancy risk(s) in state transitions")
    for risk in "${REENTRANCY_RISKS[@]}"; do
      FINDINGS+=("  - $risk")
    done
  fi

  if [ ${#UNSAFE_TRANSITIONS[@]} -gt 0 ]; then
    FINDINGS+=("WARNING: ${#UNSAFE_TRANSITIONS[@]} unsafe transition(s) detected")
    for unsafe in "${UNSAFE_TRANSITIONS[@]}"; do
      FINDINGS+=("  - $unsafe")
    done
  fi

  # Update summary
  if [ ${#REENTRANCY_RISKS[@]} -gt 0 ]; then
    SUMMARY="CRITICAL - State transitions with reentrancy risks"
    STATUS="fail"
  elif [ ${#UNSAFE_TRANSITIONS[@]} -gt 0 ]; then
    SUMMARY="State transition issues detected - ${#UNSAFE_TRANSITIONS[@]} warnings"
    STATUS="warn"
  elif [ ${#STATE_MACHINES[@]} -eq 0 ]; then
    SUMMARY="No state machines detected"
    STATUS="pass"
  else
    SUMMARY="State transition safety validated - no critical issues"
    STATUS="pass"
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

# Build unsafe transitions JSON
if [ ${#UNSAFE_TRANSITIONS[@]} -eq 0 ]; then
  UNSAFE_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  UNSAFE_JSON=$(printf '%s\n' "${UNSAFE_TRANSITIONS[@]}" | jq -R . | jq -s .)
else
  UNSAFE_JSON="["
  first=true
  for u in "${UNSAFE_TRANSITIONS[@]}"; do
    escaped=$(echo "$u" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    if [ "$first" = true ]; then
      UNSAFE_JSON="${UNSAFE_JSON}\"$escaped\""
      first=false
    else
      UNSAFE_JSON="${UNSAFE_JSON},\"$escaped\""
    fi
  done
  UNSAFE_JSON="${UNSAFE_JSON}]"
fi

cat <<JSON
{
  "skill":"state-transition-safety",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "state_machines":${#STATE_MACHINES[@]},
    "transitions":${#TRANSITIONS[@]},
    "state_validations":${#STATE_VALIDATIONS[@]},
    "unsafe_transitions":$UNSAFE_JSON,
    "reentrancy_risks":${#REENTRANCY_RISKS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
