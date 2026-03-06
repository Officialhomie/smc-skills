#!/usr/bin/env bash
# Skill 62: Gas Anomaly Detector
# Detects unusual gas consumption patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="gas consumption patterns analyzed"
GAS_ISSUES=()

# Check for gas-expensive operations in loops
LOOP_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "for\|while" || true)

if [ -n "$LOOP_FILES" ]; then
  while IFS= read -r file; do
    LOOP_LINES=$(grep -n "for\|while" "$file" | cut -d: -f1 || true)

    while IFS= read -r line_num; do
      [ -z "$line_num" ] && continue

      # Get loop body (next 20 lines)
      LOOP_BODY=$(tail -n +$((line_num)) "$file" | head -20)

      # Check for expensive operations in loops
      EXPENSIVE_OPS=(
        "keccak256"
        "\.call("
        "\.transfer("
        "emit"
        "balanceOf"
        "totalSupply"
      )

      for op in "${EXPENSIVE_OPS[@]}"; do
        if echo "$LOOP_BODY" | grep -q "$op"; then
          GAS_ISSUES+=("$file:$line_num: Expensive operation '$op' in loop (gas optimization)")
          STATUS="warn"
          break
        fi
      done
    done <<< "$LOOP_LINES"
  done <<< "$LOOP_FILES"
fi

# Check for storage operations in loops
STORAGE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "for\|while" || true)

if [ -n "$STORAGE_FILES" ]; then
  while IFS= read -r file; do
    # Find loops with storage write operations
    if grep -q "for.*{" "$file" && grep -q "^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*=" "$file"; then
      LOOP_STORAGE=$(grep -B2 "^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*=" "$file" | grep -E "for|while" || true)

      if [ -n "$LOOP_STORAGE" ]; then
        GAS_ISSUES+=("$file: Potential storage write in loop (cache to memory first)")
        STATUS="warn"
      fi
    fi
  done <<< "$STORAGE_FILES"
fi

# Check for redundant variable declarations
VAR_DECL_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "uint\|bool\|address" || true)

if [ -n "$VAR_DECL_FILES" ]; then
  while IFS= read -r file; do
    # Check for uint256 (32 bytes) when smaller types could be used
    LARGE_VARS=$(grep -n "uint256" "$file" | wc -l)

    if [ "$LARGE_VARS" -gt 10 ]; then
      # Check if contract has storage packing opportunities
      if grep -q "uint256.*bool\|uint256.*address" "$file"; then
        GAS_ISSUES+=("$file: Consider packing storage variables for better gas efficiency")
        STATUS="warn"
      fi
    fi
  done <<< "$VAR_DECL_FILES"
fi

# Check for inefficient array operations
ARRAY_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "\[.*\]" || true)

if [ -n "$ARRAY_FILES" ]; then
  while IFS= read -r file; do
    # Check for dynamic array length calls in loops
    if grep -q "\.length" "$file" && grep -q "for\|while" "$file"; then
      if grep -q "for.*\.length\|while.*\.length"; then
        GAS_ISSUES+=("$file: Reading array.length in loop condition (cache to variable)")
        STATUS="warn"
      fi
    fi

    # Check for repeated push operations
    if grep -c "\.push(" "$file" | grep -q -v "^0$"; then
      PUSH_COUNT=$(grep -c "\.push(" "$file")
      if [ "$PUSH_COUNT" -gt 3 ]; then
        GAS_ISSUES+=("$file: Multiple .push() calls ($PUSH_COUNT) - consider batch operations")
        STATUS="warn"
      fi
    fi
  done <<< "$ARRAY_FILES"
fi

# Check for missing immutable declarations
CONSTANT_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "address\|uint256" || true)

if [ -n "$CONSTANT_FILES" ]; then
  while IFS= read -r file; do
    # Check for variables that could be immutable (set only in constructor)
    STATE_VARS=$(grep -E "^\s+address\s+[a-zA-Z_]|^\s+uint256\s+[a-zA-Z_]" "$file" || true)

    if [ -n "$STATE_VARS" ]; then
      # Check if any should be immutable (assigned in constructor, never changed)
      if grep -q "constructor" "$file" && ! grep -q "immutable"; then
        GAS_ISSUES+=("$file: Consider using 'immutable' keyword for constructor-assigned variables")
        STATUS="warn"
      fi
    fi
  done <<< "$CONSTANT_FILES"
fi

# Check for unnecessary SSTORE operations (same value writes)
WRITE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "=\|+=" || true)

if [ -n "$WRITE_FILES" ]; then
  while IFS= read -r file; do
    # Check for potential redundant writes
    MULTI_ASSIGN=$(grep -E "^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*=" "$file" | cut -d= -f1 | sort | uniq -d)

    if [ -n "$MULTI_ASSIGN" ]; then
      GAS_ISSUES+=("$file: Variables assigned multiple times - check for redundant writes")
      STATUS="warn"
    fi
  done <<< "$WRITE_FILES"
fi

# Build JSON array
if [ ${#GAS_ISSUES[@]} -eq 0 ]; then
  ISSUES_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ISSUES_JSON=$(printf '%s\n' "${GAS_ISSUES[@]}" | jq -R . | jq -s .)
else
  ISSUES_JSON="[\"${GAS_ISSUES[0]}\""
  for g in "${GAS_ISSUES[@]:1}"; do
    ISSUES_JSON="$ISSUES_JSON,\"$g\""
  done
  ISSUES_JSON="${ISSUES_JSON}]"
fi

cat <<JSON
{
  "skill":"gas-anomaly-detector",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "gas_issues":$ISSUES_JSON,
    "issue_count":${#GAS_ISSUES[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
