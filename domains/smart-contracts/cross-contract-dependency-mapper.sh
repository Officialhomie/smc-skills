#!/usr/bin/env bash
# Skill 44: Cross-Contract Dependency Mapper
# Generates comprehensive dependency graphs for multi-contract protocols
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="Cross-contract dependencies mapped"
FINDINGS=()
CONTRACT_REGISTRY=()
IMPORTS=()
INHERITANCE=()
INTERFACE_USAGE=()
EXTERNAL_CALLS=()
LIBRARY_USAGE=()
DEPENDENCY_GRAPH=()

# Check if Python with NetworkX is available for graph analysis
HAS_PYTHON=$(command -v python3 >/dev/null 2>&1 && echo "true" || echo "false")
HAS_NETWORKX="false"
if [ "$HAS_PYTHON" = "true" ]; then
  HAS_NETWORKX=$(python3 -c "import networkx" 2>/dev/null && echo "true" || echo "false")
fi

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for dependency analysis"
else
  # Build contract registry
  declare -A contract_to_file
  declare -A file_to_contracts

  while IFS= read -r file; do
    # Extract all contract/interface/library definitions
    contracts=$(grep -E "^contract |^interface |^library |^abstract contract " "$file" 2>/dev/null | \
                sed -n 's/.*\(contract\|interface\|library\) \([A-Za-z0-9_]*\).*/\2/p')

    if [ -n "$contracts" ]; then
      while IFS= read -r contract_name; do
        if [ -n "$contract_name" ]; then
          CONTRACT_REGISTRY+=("$contract_name ($(basename $file))")
          contract_to_file["$contract_name"]="$file"
          file_to_contracts["$file"]="${file_to_contracts[$file]} $contract_name"
        fi
      done <<< "$contracts"
    fi
  done <<< "$SOL_FILES"

  FINDINGS+=("Discovered ${#CONTRACT_REGISTRY[@]} contract/interface/library definitions")

  # Analyze dependencies for each file
  while IFS= read -r file; do
    file_basename=$(basename "$file")

    # Extract import statements
    import_lines=$(grep -E "^import " "$file" 2>/dev/null || echo "")
    if [ -n "$import_lines" ]; then
      while IFS= read -r import_line; do
        # Parse import path
        import_path=$(echo "$import_line" | sed -n 's/.*"\(.*\)".*/\1/p')
        if [ -n "$import_path" ]; then
          IMPORTS+=("$file_basename imports $import_path")

          # Extract imported names (if specified)
          imported_names=$(echo "$import_line" | sed -n 's/.*{\(.*\)}.*/\1/p' | tr ',' '\n' | sed 's/^ *//;s/ *$//')
          if [ -n "$imported_names" ]; then
            while IFS= read -r name; do
              if [ -n "$name" ]; then
                DEPENDENCY_GRAPH+=("$file_basename -> $name (import)")
              fi
            done <<< "$imported_names"
          fi
        fi
      done <<< "$import_lines"
    fi

    # Extract inheritance relationships
    inheritance_lines=$(grep -E "^contract .* is |^interface .* is " "$file" 2>/dev/null || echo "")
    if [ -n "$inheritance_lines" ]; then
      while IFS= read -r inherit_line; do
        contract_name=$(echo "$inherit_line" | sed -n 's/.*\(contract\|interface\) \([A-Za-z0-9_]*\).*/\2/p')
        parents=$(echo "$inherit_line" | sed -n 's/.*is \([^{]*\).*/\1/p' | tr ',' '\n' | sed 's/^ *//;s/ *$//')

        if [ -n "$parents" ]; then
          while IFS= read -r parent; do
            if [ -n "$parent" ]; then
              INHERITANCE+=("$contract_name inherits from $parent")
              DEPENDENCY_GRAPH+=("$contract_name -> $parent (inherits)")
            fi
          done <<< "$parents"
        fi
      done <<< "$inheritance_lines"
    fi

    # Detect interface usage (external contract calls)
    interface_calls=$(grep -nE "I[A-Z][A-Za-z0-9]*\(.*\)\." "$file" 2>/dev/null || echo "")
    if [ -n "$interface_calls" ]; then
      while IFS= read -r call_line; do
        line_num=$(echo "$call_line" | cut -d: -f1)
        interface_name=$(echo "$call_line" | sed -n 's/.*\(I[A-Z][A-Za-z0-9]*\)(.*/\1/p')

        if [ -n "$interface_name" ]; then
          INTERFACE_USAGE+=("$file_basename:$line_num uses interface $interface_name")
          DEPENDENCY_GRAPH+=("$file_basename -> $interface_name (interface call)")
        fi
      done <<< "$interface_calls"
    fi

    # Detect library usage (using X for Y)
    library_usage=$(grep -E "using .* for " "$file" 2>/dev/null || echo "")
    if [ -n "$library_usage" ]; then
      while IFS= read -r usage_line; do
        library_name=$(echo "$usage_line" | sed -n 's/.*using \([A-Za-z0-9_]*\).*/\1/p')
        if [ -n "$library_name" ]; then
          LIBRARY_USAGE+=("$file_basename uses library $library_name")
          DEPENDENCY_GRAPH+=("$file_basename -> $library_name (library)")
        fi
      done <<< "$library_usage"
    fi

    # Detect external contract calls (.call, interface instances)
    external_call_lines=$(grep -nE "\.call\{|[A-Z][A-Za-z0-9]*\(address\(" "$file" 2>/dev/null || echo "")
    if [ -n "$external_call_lines" ]; then
      call_count=$(echo "$external_call_lines" | wc -l | tr -d ' ')
      EXTERNAL_CALLS+=("$file_basename has $call_count external call(s)")
    fi

  done <<< "$SOL_FILES"

  # Generate NetworkX graph if available
  mkdir -p build 2>/dev/null || true

  if [ "$HAS_NETWORKX" = "true" ] && [ ${#DEPENDENCY_GRAPH[@]} -gt 0 ]; then
    # Create Python script to generate dependency graph
    cat > build/generate_dep_graph.py <<'PYTHON'
import networkx as nx
import json
import sys

# Read edges from stdin
edges = []
for line in sys.stdin:
    line = line.strip()
    if ' -> ' in line:
        parts = line.split(' -> ')
        if len(parts) == 2:
            source = parts[0].strip()
            target_parts = parts[1].split(' (')
            target = target_parts[0].strip()
            edge_type = target_parts[1].rstrip(')') if len(target_parts) > 1 else 'unknown'
            edges.append((source, target, edge_type))

# Create directed graph
G = nx.DiGraph()
for source, target, edge_type in edges:
    G.add_edge(source, target, type=edge_type)

# Detect cycles
try:
    cycles = list(nx.simple_cycles(G))
    has_cycles = len(cycles) > 0
except:
    cycles = []
    has_cycles = False

# Calculate graph metrics
metrics = {
    'nodes': G.number_of_nodes(),
    'edges': G.number_of_edges(),
    'has_cycles': has_cycles,
    'cycles': [' -> '.join(cycle) for cycle in cycles],
    'strongly_connected_components': len(list(nx.strongly_connected_components(G)))
}

# Find most connected nodes
degree_centrality = nx.degree_centrality(G)
top_nodes = sorted(degree_centrality.items(), key=lambda x: x[1], reverse=True)[:5]
metrics['most_connected'] = [{'node': node, 'centrality': round(cent, 3)} for node, cent in top_nodes]

print(json.dumps(metrics, indent=2))
PYTHON

    # Run graph analysis
    graph_output=$(printf '%s\n' "${DEPENDENCY_GRAPH[@]}" | python3 build/generate_dep_graph.py 2>&1 || echo '{}')

    if [ "$graph_output" != "{}" ]; then
      FINDINGS+=("Generated dependency graph analysis")

      # Check for cycles
      if echo "$graph_output" | grep -q '"has_cycles": true'; then
        cycle_count=$(echo "$graph_output" | grep -c "cycles" || echo "0")
        FINDINGS+=("WARNING: Circular dependencies detected in protocol")
        STATUS="warn"
      else
        FINDINGS+=("No circular dependencies detected")
      fi

      # Save graph output
      echo "$graph_output" > build/dependency-graph.json 2>/dev/null || true
    fi
  else
    if [ "$HAS_NETWORKX" = "false" ]; then
      FINDINGS+=("Python NetworkX not available - install with: pip install networkx")
    fi
  fi

  # Build findings summary
  if [ ${#IMPORTS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#IMPORTS[@]} import statement(s)")
  fi

  if [ ${#INHERITANCE[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#INHERITANCE[@]} inheritance relationship(s)")
  fi

  if [ ${#INTERFACE_USAGE[@]} -gt 0 ]; then
    FINDINGS+=("Detected ${#INTERFACE_USAGE[@]} interface usage(s)")
  fi

  if [ ${#LIBRARY_USAGE[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#LIBRARY_USAGE[@]} library usage(s)")
  fi

  if [ ${#EXTERNAL_CALLS[@]} -gt 0 ]; then
    FINDINGS+=("Detected external calls in ${#EXTERNAL_CALLS[@]} file(s)")
  fi

  # Update summary
  if [ ${#DEPENDENCY_GRAPH[@]} -eq 0 ]; then
    SUMMARY="No dependencies detected - single-contract system"
    STATUS="pass"
  elif [ "$STATUS" = "warn" ]; then
    SUMMARY="Dependency mapping complete - circular dependencies found"
  else
    SUMMARY="Cross-contract dependencies mapped - ${#DEPENDENCY_GRAPH[@]} relationships"
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

cat <<JSON
{
  "skill":"cross-contract-dependency-mapper",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "total_contracts":${#CONTRACT_REGISTRY[@]},
    "imports":${#IMPORTS[@]},
    "inheritance":${#INHERITANCE[@]},
    "interface_usage":${#INTERFACE_USAGE[@]},
    "library_usage":${#LIBRARY_USAGE[@]},
    "external_calls":${#EXTERNAL_CALLS[@]},
    "dependency_edges":${#DEPENDENCY_GRAPH[@]},
    "has_networkx":"$HAS_NETWORKX",
    "graph_analysis_file":"build/dependency-graph.json"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
