#!/usr/bin/env bash
# Skill 22: Threat Model Generator
# Generates comprehensive threat model by analyzing contract entry points, roles, and trust boundaries
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Threat model generated successfully"
FINDINGS=()
ENTRY_POINTS=()
TRUST_BOUNDARIES=()
UNPROTECTED_STATE_CHANGES=()
ROLES_FOUND=()

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for threat modeling"
else
  # Analyze entry points (external/public functions)
  while IFS= read -r file; do
    # Find external functions
    external_funcs=$(grep -n "function.*external" "$file" 2>/dev/null || echo "")
    if [ -n "$external_funcs" ]; then
      while IFS= read -r line; do
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
        line_num=$(echo "$line" | cut -d: -f1)
        ENTRY_POINTS+=("$file:$line_num - external function: $func_name")
      done <<< "$external_funcs"
    fi

    # Find public functions
    public_funcs=$(grep -n "function.*public" "$file" 2>/dev/null || echo "")
    if [ -n "$public_funcs" ]; then
      while IFS= read -r line; do
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
        line_num=$(echo "$line" | cut -d: -f1)
        ENTRY_POINTS+=("$file:$line_num - public function: $func_name")
      done <<< "$public_funcs"
    fi

    # Find trust boundaries (access modifiers, msg.sender checks)
    if grep -q "onlyOwner\|onlyRole\|hasRole" "$file" 2>/dev/null; then
      TRUST_BOUNDARIES+=("$file - Access control modifiers detected")
    fi

    if grep -q "msg.sender.*==" "$file" 2>/dev/null || grep -q "require(msg.sender" "$file" 2>/dev/null; then
      TRUST_BOUNDARIES+=("$file - msg.sender validation detected")
    fi

    # Find role definitions
    role_defs=$(grep -n "bytes32.*constant.*ROLE\|bytes32.*public.*ROLE" "$file" 2>/dev/null || echo "")
    if [ -n "$role_defs" ]; then
      while IFS= read -r line; do
        role_name=$(echo "$line" | sed -n 's/.*bytes32[^=]*\([A-Z_]*ROLE\).*/\1/p')
        if [ -n "$role_name" ]; then
          ROLES_FOUND+=("$file - Role defined: $role_name")
        fi
      done <<< "$role_defs"
    fi

    # Find state-changing functions without access control
    state_changing=$(grep -n "function.*public\|function.*external" "$file" 2>/dev/null || echo "")
    if [ -n "$state_changing" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')

        # Check if function has state-changing keywords but no access control
        func_context=$(sed -n "${line_num},$((line_num + 20))p" "$file" 2>/dev/null || echo "")

        if echo "$func_context" | grep -qE "=|\+\+|--|delete|push|pop" && \
           ! echo "$func_context" | grep -qE "onlyOwner|onlyRole|hasRole|msg.sender.*==|require\(msg.sender"; then
          UNPROTECTED_STATE_CHANGES+=("$file:$line_num - $func_name may modify state without access control")
        fi
      done <<< "$state_changing"
    fi

  done <<< "$SOL_FILES"

  # Generate findings
  if [ ${#ENTRY_POINTS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#ENTRY_POINTS[@]} entry points (external/public functions)")
  fi

  if [ ${#TRUST_BOUNDARIES[@]} -gt 0 ]; then
    FINDINGS+=("Detected ${#TRUST_BOUNDARIES[@]} trust boundaries (access controls)")
  fi

  if [ ${#ROLES_FOUND[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#ROLES_FOUND[@]} role definitions")
  fi

  if [ ${#UNPROTECTED_STATE_CHANGES[@]} -gt 0 ]; then
    STATUS="warn"
    SUMMARY="Threat model generated - ${#UNPROTECTED_STATE_CHANGES[@]} potential unprotected state changes detected"
    FINDINGS+=("WARNING: ${#UNPROTECTED_STATE_CHANGES[@]} functions may modify state without access control")
  fi

  # Generate threat model markdown
  THREAT_MODEL_FILE="build/threat-model.md"
  mkdir -p build

  cat > "$THREAT_MODEL_FILE" <<EOF
# Threat Model Report

**Generated:** $(date -u +%FT%TZ)
**Project:** $(basename "$ROOT")

## Executive Summary

- **Entry Points:** ${#ENTRY_POINTS[@]} external/public functions
- **Trust Boundaries:** ${#TRUST_BOUNDARIES[@]} access control mechanisms
- **Roles Defined:** ${#ROLES_FOUND[@]} role-based access controls
- **Potential Issues:** ${#UNPROTECTED_STATE_CHANGES[@]} unprotected state changes

## Entry Points (Attack Surface)

EOF

  if [ ${#ENTRY_POINTS[@]} -gt 0 ]; then
    printf '%s\n' "${ENTRY_POINTS[@]}" | while IFS= read -r entry; do
      echo "- $entry" >> "$THREAT_MODEL_FILE"
    done
  else
    echo "No entry points detected." >> "$THREAT_MODEL_FILE"
  fi

  cat >> "$THREAT_MODEL_FILE" <<EOF

## Trust Boundaries

EOF

  if [ ${#TRUST_BOUNDARIES[@]} -gt 0 ]; then
    printf '%s\n' "${TRUST_BOUNDARIES[@]}" | while IFS= read -r boundary; do
      echo "- $boundary" >> "$THREAT_MODEL_FILE"
    done
  else
    echo "No trust boundaries detected." >> "$THREAT_MODEL_FILE"
  fi

  cat >> "$THREAT_MODEL_FILE" <<EOF

## Role-Based Access Control

EOF

  if [ ${#ROLES_FOUND[@]} -gt 0 ]; then
    printf '%s\n' "${ROLES_FOUND[@]}" | while IFS= read -r role; do
      echo "- $role" >> "$THREAT_MODEL_FILE"
    done
  else
    echo "No role definitions found." >> "$THREAT_MODEL_FILE"
  fi

  cat >> "$THREAT_MODEL_FILE" <<EOF

## Potential Security Issues

EOF

  if [ ${#UNPROTECTED_STATE_CHANGES[@]} -gt 0 ]; then
    echo "### ⚠️ Unprotected State Changes" >> "$THREAT_MODEL_FILE"
    echo "" >> "$THREAT_MODEL_FILE"
    printf '%s\n' "${UNPROTECTED_STATE_CHANGES[@]}" | while IFS= read -r issue; do
      echo "- $issue" >> "$THREAT_MODEL_FILE"
    done
  else
    echo "No obvious unprotected state changes detected." >> "$THREAT_MODEL_FILE"
  fi

  cat >> "$THREAT_MODEL_FILE" <<EOF

## Recommendations

1. **Review all entry points** - Ensure external/public functions have appropriate access controls
2. **Validate trust boundaries** - Verify msg.sender checks and modifiers are correctly applied
3. **Audit role hierarchy** - Review role definitions and their usage
4. **Fix unprotected state changes** - Add access control to functions that modify state
5. **Consider reentrancy guards** - Add nonReentrant modifier to functions with external calls
6. **Implement pause mechanism** - Add emergency pause functionality for critical functions

## Attack Surface Matrix

| Function Type | Count | Risk Level |
|---------------|-------|------------|
| External Functions | $(grep -c "external function" <<< "$(printf '%s\n' "${ENTRY_POINTS[@]}")" || echo "0") | High |
| Public Functions | $(grep -c "public function" <<< "$(printf '%s\n' "${ENTRY_POINTS[@]}")" || echo "0") | Medium |
| Unprotected State Changes | ${#UNPROTECTED_STATE_CHANGES[@]} | Critical |

EOF

  FINDINGS+=("Threat model saved to $THREAT_MODEL_FILE")
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

# Build attack surface JSON
ATTACK_SURFACE_JSON="{"
ATTACK_SURFACE_JSON="${ATTACK_SURFACE_JSON}\"entry_points\":${#ENTRY_POINTS[@]},"
ATTACK_SURFACE_JSON="${ATTACK_SURFACE_JSON}\"trust_boundaries\":${#TRUST_BOUNDARIES[@]},"
ATTACK_SURFACE_JSON="${ATTACK_SURFACE_JSON}\"roles\":${#ROLES_FOUND[@]},"
ATTACK_SURFACE_JSON="${ATTACK_SURFACE_JSON}\"unprotected_state_changes\":${#UNPROTECTED_STATE_CHANGES[@]}"
ATTACK_SURFACE_JSON="${ATTACK_SURFACE_JSON}}"

cat <<JSON
{
  "skill":"threat-model-generator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "attack_surface":$ATTACK_SURFACE_JSON,
    "threat_model_file":"build/threat-model.md"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
