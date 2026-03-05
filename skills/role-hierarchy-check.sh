#!/usr/bin/env bash
# Skill 17: Role Hierarchy Check
# Validates AccessControl role hierarchy and admin roles
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="role hierarchy validated"
ISSUES=()

# Check for AccessControl contracts
ACCESS_CONTROL_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "AccessControl" || true)

if [ -n "$ACCESS_CONTROL_FILES" ]; then
  while IFS= read -r file; do
    # Check for role definitions
    ROLE_DEFS=$(grep -c "bytes32.*ROLE" "$file" 2>/dev/null || echo "0")

    if [ "$ROLE_DEFS" -eq 0 ]; then
      ISSUES+=("$file: AccessControl imported but no roles defined")
      STATUS="fail"
    fi

    # Check for DEFAULT_ADMIN_ROLE usage
    if ! grep -q "DEFAULT_ADMIN_ROLE" "$file"; then
      ISSUES+=("$file: Missing DEFAULT_ADMIN_ROLE management")
      STATUS="warn"
    fi

    # Check for _grantRole in constructor
    if ! grep -q "_grantRole\|_setupRole" "$file"; then
      ISSUES+=("$file: Roles not granted in constructor/initializer")
      STATUS="fail"
    fi

    # Check for role admin setup
    if ! grep -q "_setRoleAdmin\|getRoleAdmin" "$file"; then
      ISSUES+=("$file: No role admin hierarchy configured")
      STATUS="warn"
    fi

    # Check for hasRole checks
    HAS_ROLE_COUNT=$(grep -c "hasRole\|onlyRole" "$file" || echo "0")

    if [ "$HAS_ROLE_COUNT" -lt 1 ]; then
      ISSUES+=("$file: Roles defined but not used in modifiers")
      STATUS="fail"
      SUMMARY="roles defined but not enforced"
    fi

    # Security: check for direct _grantRole calls outside constructor
    GRANT_ROLE_FUNCS=$(grep -n "_grantRole" "$file" | grep -v "constructor\|initialize" || true)

    if [ -n "$GRANT_ROLE_FUNCS" ]; then
      ISSUES+=("$file: Direct _grantRole calls outside constructor (use grantRole with access control)")
      STATUS="warn"
    fi
  done <<< "$ACCESS_CONTROL_FILES"
fi

# Build JSON array
if [ ${#ISSUES[@]} -eq 0 ]; then
  ISSUES_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -s .)
else
  ISSUES_JSON="[\"${ISSUES[0]}\""
  for i in "${ISSUES[@]:1}"; do
    ISSUES_JSON="$ISSUES_JSON,\"$i\""
  done
  ISSUES_JSON="${ISSUES_JSON}]"
fi

cat <<JSON
{
  "skill":"role-hierarchy-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "issues":$ISSUES_JSON,
    "access_control_contracts":"$(echo "$ACCESS_CONTROL_FILES" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
