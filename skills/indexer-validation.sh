#!/usr/bin/env bash
# Skill 71: Indexer Validation
# Validates subgraph schema and indexing patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="subgraph indexing patterns validated"
FINDINGS=()

# Check for subgraph.yaml configuration
if [ -f "subgraph.yaml" ]; then
  # Validate dataSources configuration
  if ! grep -q "dataSources:" subgraph.yaml; then
    FINDINGS+=("subgraph.yaml: Missing dataSources configuration")
    STATUS="fail"
  fi

  # Check for event handlers
  if ! grep -q "eventHandlers:\|blockHandlers:" subgraph.yaml; then
    FINDINGS+=("subgraph.yaml: No event or block handlers configured")
    STATUS="warn"
  fi

  # Validate contract addresses
  if grep -q "address:" subgraph.yaml; then
    if grep "address:.*0x0000000000000000000000000000000000000000" subgraph.yaml >/dev/null; then
      FINDINGS+=("subgraph.yaml: Zero address in datasources")
      STATUS="fail"
    fi
  fi

  SUMMARY="subgraph indexing configuration validated"
fi

# Check for mapping files
MAPPING_FILES=$(find . -name "*.ts" -path "*/src/mappings/*" 2>/dev/null | head -20 || true)

if [ -n "$MAPPING_FILES" ]; then
  while IFS= read -r file; do
    # Check for event handler implementations
    if grep -q "export function handle" "$file"; then
      # Validate entity creation pattern
      if ! grep -q "new.*Entity()\|store.set" "$file"; then
        FINDINGS+=("$file: Event handler without proper entity storage")
        STATUS="warn"
      fi
    fi

    # Check for schema compliance
    if grep -q "Entity\|store\." "$file"; then
      if ! grep -q "import.*from.*generated" "$file"; then
        FINDINGS+=("$file: Missing generated schema imports")
        STATUS="warn"
      fi
    fi

    # Check for error handling
    if grep -q "store.set\|store.get" "$file"; then
      if ! grep -q "try.*catch\|if.*null\|if.*undefined" "$file"; then
        FINDINGS+=("$file: Storage operations without error handling")
        STATUS="warn"
      fi
    fi
  done <<< "$MAPPING_FILES"
fi

# Check for schema.graphql
if [ -f "schema.graphql" ]; then
  # Validate entity definitions
  ENTITY_COUNT=$(grep -c "^type " schema.graphql || echo "0")

  if [ "$ENTITY_COUNT" -eq 0 ]; then
    FINDINGS+=("schema.graphql: No entity types defined")
    STATUS="fail"
  fi

  # Check for proper ID fields
  if grep -q "^type " schema.graphql; then
    if ! grep -q "id: ID!" schema.graphql; then
      FINDINGS+=("schema.graphql: Entities missing required ID field")
      STATUS="fail"
    fi
  fi

  # Validate relationships
  if grep -q ": \[.*\]\|: .*!" schema.graphql; then
    if ! grep -q "@entity\|@derivedFrom" schema.graphql; then
      FINDINGS+=("schema.graphql: Relationships without entity annotations")
      STATUS="warn"
    fi
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
  "skill":"indexer-validation",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "mapping_files":"$(echo "$MAPPING_FILES" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
