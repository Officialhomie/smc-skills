#!/usr/bin/env bash
# Skill 40: Protocol Design Analyzer
# Validates multi-contract protocol architecture, detects circular dependencies, analyzes interaction patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Protocol architecture validated"
FINDINGS=()
CONTRACTS=()
DEPENDENCIES=()
CIRCULAR_DEPS=()
INTERACTION_PATTERNS=()
SYSTEM_INVARIANTS=()

# Check if Surya is available for visualization
HAS_SURYA=$(command -v surya >/dev/null 2>&1 && echo "true" || echo "false")

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for protocol analysis"
else
  # Count total contracts
  contract_count=$(echo "$SOL_FILES" | wc -l | tr -d ' ')
  FINDINGS+=("Found $contract_count Solidity contracts")

  # Extract contract names and their dependencies
  declare -A contract_deps
  declare -A contract_files

  while IFS= read -r file; do
    # Extract contract name
    contract_name=$(grep -E "^contract |^abstract contract |^interface " "$file" 2>/dev/null | head -1 | sed -n 's/.*contract \([A-Za-z0-9_]*\).*/\1/p')

    if [ -n "$contract_name" ]; then
      CONTRACTS+=("$contract_name ($(basename $file))")
      contract_files["$contract_name"]="$file"

      # Extract dependencies (import statements and inheritance)
      imports=$(grep -E "^import " "$file" 2>/dev/null || echo "")
      inherits=$(grep -E "^contract .* is " "$file" 2>/dev/null | sed -n 's/.*is \([^{]*\).*/\1/p' | tr ',' '\n' | sed 's/^ *//;s/ *$//')

      # Track dependencies
      dep_list=""

      # Parse imports for contract references
      while IFS= read -r import_line; do
        if [ -n "$import_line" ]; then
          # Extract imported contract names
          imported=$(echo "$import_line" | sed -n 's/.*import.*["{].*\([A-Za-z0-9_]*\).*["}.*/\1/p')
          if [ -n "$imported" ]; then
            dep_list="$dep_list $imported"
          fi
        fi
      done <<< "$imports"

      # Add inherited contracts
      while IFS= read -r inherited; do
        if [ -n "$inherited" ]; then
          dep_list="$dep_list $inherited"
        fi
      done <<< "$inherits"

      # Store dependencies for this contract
      if [ -n "$dep_list" ]; then
        contract_deps["$contract_name"]="$dep_list"
        DEPENDENCIES+=("$contract_name depends on:$dep_list")
      fi
    fi
  done <<< "$SOL_FILES"

  FINDINGS+=("Analyzed ${#CONTRACTS[@]} contract definitions")
  FINDINGS+=("Found ${#DEPENDENCIES[@]} dependency relationships")

  # Detect circular dependencies using basic cycle detection
  for contract in "${!contract_deps[@]}"; do
    visited=""
    stack="$contract"

    while [ -n "$stack" ]; do
      current=$(echo "$stack" | awk '{print $1}')
      stack=$(echo "$stack" | cut -d' ' -f2-)

      if echo "$visited" | grep -q "\<$current\>"; then
        # Cycle detected
        if echo "$visited" | grep -q "\<$contract\>"; then
          cycle_path="$contract -> $visited -> $current"
          CIRCULAR_DEPS+=("Circular dependency detected: $cycle_path")
          STATUS="warn"
        fi
        continue
      fi

      visited="$visited $current"

      # Add dependencies of current contract to stack
      if [ -n "${contract_deps[$current]}" ]; then
        stack="$stack ${contract_deps[$current]}"
      fi
    done
  done

  if [ ${#CIRCULAR_DEPS[@]} -gt 0 ]; then
    FINDINGS+=("WARNING: ${#CIRCULAR_DEPS[@]} circular dependencies detected")
  else
    FINDINGS+=("No circular dependencies detected")
  fi

  # Analyze interaction patterns
  while IFS= read -r file; do
    # Detect external calls
    external_calls=$(grep -nE "\.call\{|\.delegatecall\(|\.staticcall\(" "$file" 2>/dev/null || echo "")
    if [ -n "$external_calls" ]; then
      call_count=$(echo "$external_calls" | wc -l | tr -d ' ')
      INTERACTION_PATTERNS+=("$(basename $file) - $call_count external call(s)")
    fi

    # Detect interface implementations
    interface_impl=$(grep -E "^contract .* is .*I[A-Z]" "$file" 2>/dev/null || echo "")
    if [ -n "$interface_impl" ]; then
      INTERACTION_PATTERNS+=("$(basename $file) - Implements interface pattern")
    fi

    # Detect factory patterns
    if grep -qE "function.*create|new [A-Z]" "$file" 2>/dev/null; then
      INTERACTION_PATTERNS+=("$(basename $file) - Factory pattern detected")
    fi

    # Detect proxy patterns
    if grep -qE "delegatecall|implementation|upgrade" "$file" 2>/dev/null; then
      INTERACTION_PATTERNS+=("$(basename $file) - Proxy/upgrade pattern detected")
    fi
  done <<< "$SOL_FILES"

  if [ ${#INTERACTION_PATTERNS[@]} -gt 0 ]; then
    FINDINGS+=("Detected ${#INTERACTION_PATTERNS[@]} interaction patterns")
  fi

  # Identify system-level invariants
  while IFS= read -r file; do
    # Look for require/assert statements that define invariants
    invariants=$(grep -nE "require\(|assert\(" "$file" 2>/dev/null | head -5 || echo "")
    if [ -n "$invariants" ]; then
      while IFS= read -r inv_line; do
        line_num=$(echo "$inv_line" | cut -d: -f1)
        condition=$(echo "$inv_line" | sed -n 's/.*require(\(.*\)).*/\1/p' | head -c 80)
        if [ -n "$condition" ]; then
          SYSTEM_INVARIANTS+=("$(basename $file):$line_num - $condition")
        fi
      done <<< "$invariants"
    fi
  done <<< "$SOL_FILES"

  if [ ${#SYSTEM_INVARIANTS[@]} -gt 0 ]; then
    FINDINGS+=("Identified ${#SYSTEM_INVARIANTS[@]} potential system invariants")
  fi

  # Generate architecture visualization if Surya is available
  mkdir -p build 2>/dev/null || true

  if [ "$HAS_SURYA" = "true" ] && [ -d "build" ]; then
    # Generate inheritance graph
    surya inheritance . --no-include-node-modules > build/inheritance-graph.dot 2>/dev/null || true
    if [ -f "build/inheritance-graph.dot" ]; then
      FINDINGS+=("Generated inheritance graph at build/inheritance-graph.dot")
    fi

    # Generate call graph
    surya graph . --no-include-node-modules > build/call-graph.dot 2>/dev/null || true
    if [ -f "build/call-graph.dot" ]; then
      FINDINGS+=("Generated call graph at build/call-graph.dot")
    fi
  else
    FINDINGS+=("Surya not available - install with: npm install -g surya")
  fi

  # Update summary based on findings
  if [ ${#CIRCULAR_DEPS[@]} -gt 0 ]; then
    SUMMARY="Protocol analysis complete - ${#CIRCULAR_DEPS[@]} circular dependencies found"
    STATUS="warn"
  elif [ $contract_count -lt 2 ]; then
    SUMMARY="Single contract detected - protocol analysis limited"
    STATUS="pass"
  else
    SUMMARY="Protocol architecture validated - $contract_count contracts, ${#DEPENDENCIES[@]} dependencies"
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

# Build circular dependencies JSON
if [ ${#CIRCULAR_DEPS[@]} -eq 0 ]; then
  CIRCULAR_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  CIRCULAR_JSON=$(printf '%s\n' "${CIRCULAR_DEPS[@]}" | jq -R . | jq -s .)
else
  CIRCULAR_JSON="["
  first=true
  for c in "${CIRCULAR_DEPS[@]}"; do
    escaped=$(echo "$c" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    if [ "$first" = true ]; then
      CIRCULAR_JSON="${CIRCULAR_JSON}\"$escaped\""
      first=false
    else
      CIRCULAR_JSON="${CIRCULAR_JSON},\"$escaped\""
    fi
  done
  CIRCULAR_JSON="${CIRCULAR_JSON}]"
fi

cat <<JSON
{
  "skill":"protocol-design-analyzer",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "total_contracts":${#CONTRACTS[@]},
    "dependencies":${#DEPENDENCIES[@]},
    "circular_dependencies":$CIRCULAR_JSON,
    "interaction_patterns":${#INTERACTION_PATTERNS[@]},
    "system_invariants":${#SYSTEM_INVARIANTS[@]},
    "has_surya":$HAS_SURYA,
    "visualization_files":["build/inheritance-graph.dot","build/call-graph.dot"]
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
