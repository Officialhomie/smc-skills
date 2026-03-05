#!/usr/bin/env bash
# Skill 20: External Call Boundary Audit
# Audits external calls for reentrancy and security issues
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="external calls validated"
VULNERABILITIES=()

# Check for external calls
EXTERNAL_CALL_PATTERNS=(
  "call{value:"
  ".call("
  ".delegatecall("
  ".staticcall("
  ".transfer("
  ".send("
)

for pattern in "${EXTERNAL_CALL_PATTERNS[@]}"; do
  FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "$pattern" || true)

  if [ -n "$FILES" ]; then
    while IFS= read -r file; do
      # Check for reentrancy guard
      if ! grep -q "nonReentrant\|ReentrancyGuard" "$file"; then
        VULNERABILITIES+=("$file: External calls without reentrancy guard")
        STATUS="fail"
      fi

      # Check for checks-effects-interactions pattern
      CALL_LINES=$(grep -n "$pattern" "$file" | cut -d: -f1 || true)

      while IFS= read -r line_num; do
        if [ -n "$line_num" ]; then
          # Check if state changes happen after external call
          AFTER_CALL=$(tail -n +$((line_num + 1)) "$file" | head -20 | grep -E "^\s+[a-zA-Z_]+ =" || true)

          if [ -n "$AFTER_CALL" ]; then
            VULNERABILITIES+=("$file:$line_num: State change after external call (CEI violation)")
            STATUS="fail"
          fi
        fi
      done <<< "$CALL_LINES"

      # Check for return value handling (.call)
      if echo "$pattern" | grep -q "\.call"; then
        UNCHECKED=$(grep -n "\.call(" "$file" | grep -v "require\|if\|success" || true)

        if [ -n "$UNCHECKED" ]; then
          VULNERABILITIES+=("$file: Unchecked return value from .call()")
          STATUS="fail"
        fi
      fi

      # Check for .send() usage (deprecated)
      if echo "$pattern" | grep -q "\.send"; then
        VULNERABILITIES+=("$file: Using .send() (deprecated, use .call{value:})")
        STATUS="warn"
      fi

      # Check for delegatecall (high risk)
      if echo "$pattern" | grep -q "delegatecall"; then
        if ! grep -q "onlyOwner\|onlyRole" "$file"; then
          VULNERABILITIES+=("$file: delegatecall without access control (CRITICAL)")
          STATUS="fail"
        fi
      fi
    done <<< "$FILES"
  fi
done

# Check for pull payment pattern (safer alternative)
PUSH_PAYMENT=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "\.transfer(\|\.send(" || true)

if [ -n "$PUSH_PAYMENT" ]; then
  VULNERABILITIES+=("Consider using pull payment pattern instead of push payments")
  STATUS="warn"
  SUMMARY="external calls need security review"
fi

# Build JSON array
if [ ${#VULNERABILITIES[@]} -eq 0 ]; then
  VULNERABILITIES_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  VULNERABILITIES_JSON=$(printf '%s\n' "${VULNERABILITIES[@]}" | jq -R . | jq -s .)
else
  VULNERABILITIES_JSON="[\"${VULNERABILITIES[0]}\""
  for v in "${VULNERABILITIES[@]:1}"; do
    VULNERABILITIES_JSON="$VULNERABILITIES_JSON,\"$v\""
  done
  VULNERABILITIES_JSON="${VULNERABILITIES_JSON}]"
fi

cat <<JSON
{
  "skill":"external-call-audit",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "vulnerabilities":$VULNERABILITIES_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
