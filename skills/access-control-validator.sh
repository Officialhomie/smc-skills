#!/usr/bin/env bash
# Skill 11: Access Control Validator
# Validates Ownable, AccessControl patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="access control patterns validated"
ISSUES=()

# Check for Ownable pattern
if find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "contract.*Ownable" >/dev/null 2>&1; then
  # Verify onlyOwner modifier usage
  if ! find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "modifier onlyOwner" >/dev/null 2>&1; then
    ISSUES+=("Ownable contract without onlyOwner modifier")
    STATUS="fail"
  fi
fi

# Check for AccessControl pattern
if find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "AccessControl" >/dev/null 2>&1; then
  # Verify role-based modifiers
  if ! find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "hasRole\|onlyRole" >/dev/null 2>&1; then
    ISSUES+=("AccessControl imported but no role checks found")
    STATUS="warn"
  fi
fi

# Check for missing access control on critical functions
CRITICAL_FUNCS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "function (mint|burn|pause|unpause|withdraw|transferOwnership)" | grep -v "onlyOwner\|hasRole\|onlyRole" || true)

if [ -n "$CRITICAL_FUNCS" ]; then
  ISSUES+=("Critical functions without access control")
  STATUS="fail"
  SUMMARY="critical functions lack access control"
fi

# Build JSON array of issues
if [ ${#ISSUES[@]} -eq 0 ]; then
  ISSUES_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -s .)
else
  ISSUES_JSON="[\"${ISSUES[0]}\""
  for issue in "${ISSUES[@]:1}"; do
    ISSUES_JSON="$ISSUES_JSON,\"$issue\""
  done
  ISSUES_JSON="${ISSUES_JSON}]"
fi

cat <<JSON
{
  "skill":"access-control-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "issues":$ISSUES_JSON
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
