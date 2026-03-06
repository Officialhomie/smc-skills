#!/usr/bin/env bash
# Skill 61: Transaction Monitor
# Analyzes transaction patterns for anomalies
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="transaction patterns analyzed"
ANOMALIES=()

# Check for batch transaction processing without limits
BATCH_PATTERNS=(
  "for.*uint.*<.*length"
  "while.*count.*<"
  "loop.*array\|array.*loop"
)

for pattern in "${BATCH_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)

  if [ -n "$FILES" ]; then
    while IFS= read -r file; do
      # Check if there's a loop length limit
      LOOP_LINES=$(grep -n "$pattern" "$file" || true)

      while IFS= read -r line_info; do
        [ -z "$line_info" ] && continue

        LINE_NUM=$(echo "$line_info" | cut -d: -f1)

        # Check if loop has explicit bounds or require statements
        LOOP_CONTEXT=$(tail -n +$LINE_NUM "$file" | head -10)

        if ! echo "$LOOP_CONTEXT" | grep -q "require.*<\|require.*length\|MAX_\|maxLength\|limit"; then
          ANOMALIES+=("$file:$LINE_NUM: Loop without explicit length limit (DoS risk)")
          STATUS="warn"
        fi
      done <<< "$LOOP_LINES"
    done <<< "$FILES"
  fi
done

# Check for reentrancy in transaction patterns
EXTERNAL_CALL_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "\.call(" || true)

if [ -n "$EXTERNAL_CALL_FILES" ]; then
  while IFS= read -r file; do
    # Check for multiple external calls in sequence
    CALL_COUNT=$(grep -c "\.call(" "$file" || echo "0")

    if [ "$CALL_COUNT" -gt 3 ]; then
      if ! grep -q "nonReentrant\|ReentrancyGuard" "$file"; then
        ANOMALIES+=("$file: Multiple external calls without reentrancy guard")
        STATUS="warn"
      fi
    fi

    # Check for dynamic recipient patterns
    if grep -q "address.*=.*msg.sender\|address.*=.*data\|address.*=.*input"; then
      if grep -q "\.transfer(\|\.call(" "$file"; then
        ANOMALIES+=("$file: Dynamic recipient with external call (verify origin)")
        STATUS="warn"
      fi
    fi
  done <<< "$EXTERNAL_CALL_FILES"
fi

# Check for state change after external calls (CEI violation)
CEI_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "\.call(" || true)

if [ -n "$CEI_FILES" ]; then
  while IFS= read -r file; do
    CALL_LINES=$(grep -n "\.call(" "$file" | cut -d: -f1 || true)

    while IFS= read -r line_num; do
      [ -z "$line_num" ] && continue

      # Check next 5 lines for state changes
      AFTER=$(tail -n +$((line_num + 1)) "$file" | head -5)

      if echo "$AFTER" | grep -qE "^\s+[a-zA-Z_][a-zA-Z0-9_]*\s+=" && ! echo "$AFTER" | grep -q "result\|success\|return"; then
        ANOMALIES+=("$file:$line_num: Potential CEI violation (state change after call)")
        STATUS="warn"
      fi
    done <<< "$CALL_LINES"
  done <<< "$CEI_FILES"
fi

# Check for amount validation in transactions
TRANSFER_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "transfer.*amount\|\.transfer(" || true)

if [ -n "$TRANSFER_FILES" ]; then
  while IFS= read -r file; do
    TRANSFER_LINES=$(grep -n "\.transfer(" "$file" || true)

    while IFS= read -r line_info; do
      [ -z "$line_info" ] && continue

      LINE_NUM=$(echo "$line_info" | cut -d: -f1)

      # Check if amount is validated
      CONTEXT=$(tail -n -$((LINE_NUM)) "$file" | head -10)

      if ! echo "$CONTEXT" | grep -qE "require.*>|require.*==|require.*!="; then
        ANOMALIES+=("$file:$LINE_NUM: Transfer without amount validation")
        STATUS="warn"
      fi
    done <<< "$TRANSFER_LINES"
  done <<< "$TRANSFER_FILES"
fi

# Check for transaction ordering issues
MAPPING_UPDATE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "mapping\|balances\|allowances" || true)

if [ -n "$MAPPING_UPDATE_FILES" ]; then
  while IFS= read -r file; do
    # Check if there are concurrent update patterns that could cause issues
    if grep -q "balances\[.*\]\s*=\|balances\[.*\]\s*+=" "$file"; then
      if ! grep -q "nonReentrant\|require.*balance\|SafeMath"; then
        ANOMALIES+=("$file: Balance update without protection checks")
        STATUS="warn"
      fi
    fi
  done <<< "$MAPPING_UPDATE_FILES"
fi

# Build JSON array
if [ ${#ANOMALIES[@]} -eq 0 ]; then
  ANOMALIES_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ANOMALIES_JSON=$(printf '%s\n' "${ANOMALIES[@]}" | jq -R . | jq -s .)
else
  ANOMALIES_JSON="[\"${ANOMALIES[0]}\""
  for a in "${ANOMALIES[@]:1}"; do
    ANOMALIES_JSON="$ANOMALIES_JSON,\"$a\""
  done
  ANOMALIES_JSON="${ANOMALIES_JSON}]"
fi

cat <<JSON
{
  "skill":"transaction-monitor",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "anomalies":$ANOMALIES_JSON,
    "anomaly_count":${#ANOMALIES[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
