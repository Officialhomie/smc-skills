#!/usr/bin/env bash
# Skill 75: Subgraph Integrity Checker
# Validates subgraph schema integrity
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="subgraph schema integrity validated"
FINDINGS=()

# Check schema.graphql exists
if [ ! -f "schema.graphql" ]; then
  FINDINGS+=("Missing schema.graphql file")
  STATUS="fail"
else
  # Validate GraphQL schema syntax
  SCHEMA_LINES=$(wc -l < schema.graphql)

  if [ "$SCHEMA_LINES" -eq 0 ]; then
    FINDINGS+=("schema.graphql: Empty file")
    STATUS="fail"
  fi

  # Check for required type definitions
  if ! grep -q "^type " schema.graphql; then
    FINDINGS+=("schema.graphql: No type definitions found")
    STATUS="fail"
  fi

  # Validate entity IDs
  TYPE_COUNT=$(grep -c "^type " schema.graphql || echo "0")

  while IFS= read -r type_line; do
    TYPE_NAME=$(echo "$type_line" | awk '{print $2}')

    # Check if type has ID field
    if ! grep -A 20 "^type $TYPE_NAME" schema.graphql | grep -q "id: ID!"; then
      FINDINGS+=("schema.graphql: Type '$TYPE_NAME' missing required ID field")
      STATUS="fail"
    fi

    # Check for @entity directive
    if ! grep -B 2 "^type $TYPE_NAME" schema.graphql | grep -q "@entity"; then
      FINDINGS+=("schema.graphql: Type '$TYPE_NAME' missing @entity directive")
      STATUS="warn"
    fi
  done < <(grep "^type " schema.graphql)

  # Validate field types
  if grep -q ": String\|: Int\|: BigInt\|: Boolean\|: Bytes" schema.graphql; then
    # Check for nullable fields without reason
    NULLABLE_COUNT=$(grep ": \[.*\]$" schema.graphql | wc -l || echo "0")

    if [ "$NULLABLE_COUNT" -gt 0 ]; then
      FINDINGS+=("schema.graphql: $(expr "$NULLABLE_COUNT" 2>/dev/null || echo "$NULLABLE_COUNT") nullable array fields (consider making non-nullable)")
      STATUS="warn"
    fi
  fi

  # Check for circular references
  if grep -q "@derivedFrom" schema.graphql; then
    DERIVED_COUNT=$(grep -c "@derivedFrom" schema.graphql || echo "0")

    if [ "$DERIVED_COUNT" -gt 5 ]; then
      FINDINGS+=("schema.graphql: Multiple derived fields ($DERIVED_COUNT) may indicate circular references")
      STATUS="warn"
    fi
  fi

  # Validate enum definitions
  if grep -q "^enum " schema.graphql; then
    while IFS= read -r enum_line; do
      ENUM_NAME=$(echo "$enum_line" | awk '{print $2}')

      # Check enum has values
      if ! grep -A 5 "^enum $ENUM_NAME" schema.graphql | grep -q "[A-Z]"; then
        FINDINGS+=("schema.graphql: Enum '$ENUM_NAME' has no values")
        STATUS="warn"
      fi
    done < <(grep "^enum " schema.graphql)
  fi

  # Check for interface usage
  if grep -q "implements " schema.graphql; then
    if ! grep -q "^interface " schema.graphql; then
      FINDINGS+=("schema.graphql: Types implement interface but no interface definition found")
      STATUS="fail"
    fi
  fi
fi

# Check subgraph.yaml references schema
if [ -f "subgraph.yaml" ]; then
  if ! grep -q "schema.graphql" subgraph.yaml; then
    FINDINGS+=("subgraph.yaml: No reference to schema.graphql")
    STATUS="warn"
  fi
fi

# Build JSON array
if [ ${#FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${FINDINGS[0]}\""
  for f in "${FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$f\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"subgraph-integrity-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "type_count":"$(grep -c '^type ' schema.graphql 2>/dev/null || echo '0')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
