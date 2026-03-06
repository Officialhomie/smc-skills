#!/usr/bin/env bash
# Skill 46: Multi-Contract Orchestration Validator
# Validates complex multi-contract operation security
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Multi-contract orchestration validated"
FINDINGS=()
ORCHESTRATION_PATTERNS=()
ATOMIC_OPERATIONS=()
ROLLBACK_MECHANISMS=()
COORDINATION_RISKS=()

SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found"
else
  while IFS= read -r file; do
    # Detect orchestration patterns
    if grep -qE "batch|multi|orchestrate|coordinate|execute.*multiple" "$file" 2>/dev/null; then
      ORCHESTRATION_PATTERNS+=("$file - Orchestration pattern detected")

      # Check for atomicity
      if grep -qE "revert|require.*success.*length" "$file"; then
        ATOMIC_OPERATIONS+=("$file - Atomic multi-operation detected")
      else
        COORDINATION_RISKS+=("$file - Multi-operation may not be atomic")
        STATUS="warn"
      fi
    fi

    # Detect rollback mechanisms
    if grep -qE "rollback|revert|undo|restore" "$file" 2>/dev/null; then
      ROLLBACK_MECHANISMS+=("$file - Rollback mechanism detected")
    fi
  done <<< "$SOL_FILES"

  FINDINGS+=("Found ${#ORCHESTRATION_PATTERNS[@]} orchestration pattern(s)")
  FINDINGS+=("Detected ${#ATOMIC_OPERATIONS[@]} atomic operation(s)")

  if [ ${#COORDINATION_RISKS[@]} -gt 0 ]; then
    FINDINGS+=("WARNING: ${#COORDINATION_RISKS[@]} coordination risk(s)")
  fi

  if [ "$STATUS" = "warn" ]; then
    SUMMARY="Orchestration warnings detected - ${#COORDINATION_RISKS[@]} risks"
  elif [ ${#ORCHESTRATION_PATTERNS[@]} -eq 0 ]; then
    SUMMARY="No orchestration patterns detected"
  else
    SUMMARY="Multi-contract orchestration validated"
  fi
fi

FINDINGS_JSON="[]"
if [ ${#FINDINGS[@]} -gt 0 ] && command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
fi

cat <<JSON
{
  "skill":"multi-contract-orchestration-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "orchestration_patterns":${#ORCHESTRATION_PATTERNS[@]},
    "atomic_operations":${#ATOMIC_OPERATIONS[@]},
    "coordination_risks":${#COORDINATION_RISKS[@]}
  },
  "metadata":{"timestamp":"$(date -u +%FT%TZ)","runner":"local"}
}
JSON
