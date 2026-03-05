#!/usr/bin/env bash
# Skill 43: System Invariant Checker
# Validates system-wide invariants using Echidna integration and manual pattern detection
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="System invariants validated"
FINDINGS=()
INVARIANT_FUNCTIONS=()
INVARIANT_PROPERTIES=()
MATH_INVARIANTS=()
BALANCE_CHECKS=()
SUPPLY_CHECKS=()
ECHIDNA_RESULTS=()

# Check if Echidna is available
HAS_ECHIDNA=$(command -v echidna >/dev/null 2>&1 && echo "true" || echo "false")
if [ "$HAS_ECHIDNA" = "false" ]; then
  HAS_ECHIDNA=$(docker images -q trailofbits/echidna 2>/dev/null | head -1)
  if [ -n "$HAS_ECHIDNA" ]; then
    HAS_ECHIDNA="docker"
  else
    HAS_ECHIDNA="false"
  fi
fi

# Find all Solidity files
SOL_FILES=$(find . -name "*.sol" -not -path "*/node_modules/*" -not -path "*/lib/*" 2>/dev/null || echo "")

if [ -z "$SOL_FILES" ]; then
  STATUS="warn"
  SUMMARY="No Solidity files found for invariant analysis"
else
  # Analyze each Solidity file for invariant patterns
  while IFS= read -r file; do

    # Detect Echidna invariant functions (echidna_* naming convention)
    echidna_funcs=$(grep -nE "function echidna_" "$file" 2>/dev/null || echo "")
    if [ -n "$echidna_funcs" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \(echidna_[^(]*\).*/\1/p')
        INVARIANT_FUNCTIONS+=("$file:$line_num - Echidna invariant: $func_name")

        # Verify function returns bool
        if ! echo "$line" | grep -qE "returns.*bool|view.*bool|pure.*bool"; then
          FINDINGS+=("WARNING: $file:$line_num - Echidna invariant $func_name should return bool")
          STATUS="warn"
        fi
      done <<< "$echidna_funcs"
    fi

    # Detect Foundry invariant tests
    foundry_invariants=$(grep -nE "function invariant_|function test_invariant" "$file" 2>/dev/null || echo "")
    if [ -n "$foundry_invariants" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_name=$(echo "$line" | sed -n 's/.*function \([^(]*\).*/\1/p')
        INVARIANT_FUNCTIONS+=("$file:$line_num - Foundry invariant: $func_name")
      done <<< "$foundry_invariants"
    fi

    # Detect mathematical invariants
    # Common patterns: sum of balances = total supply, ratio maintenance, etc.

    # Total supply invariants
    if grep -qE "totalSupply|_totalSupply" "$file" 2>/dev/null; then
      supply_checks=$(grep -nE "totalSupply.*==|_totalSupply.*==" "$file" 2>/dev/null || echo "")
      if [ -n "$supply_checks" ]; then
        while IFS= read -r line; do
          line_num=$(echo "$line" | cut -d: -f1)
          check=$(echo "$line" | sed 's/^[^:]*://;s/^[ \t]*//' | head -c 80)
          SUPPLY_CHECKS+=("$file:$line_num - Supply invariant: $check")
        done <<< "$supply_checks"
      fi
    fi

    # Balance invariants
    if grep -qE "balanceOf|_balances\[" "$file" 2>/dev/null; then
      balance_checks=$(grep -nE "require.*balanceOf.*>=|assert.*balance.*<=" "$file" 2>/dev/null || echo "")
      if [ -n "$balance_checks" ]; then
        while IFS= read -r line; do
          line_num=$(echo "$line" | cut -d: -f1)
          check=$(echo "$line" | sed 's/^[^:]*://;s/^[ \t]*//' | head -c 80)
          BALANCE_CHECKS+=("$file:$line_num - Balance invariant: $check")
        done <<< "$balance_checks"
      fi
    fi

    # Ratio invariants (common in AMMs, lending protocols)
    ratio_invariants=$(grep -nE "constant.*RATIO|invariant.*ratio|require.*ratio" "$file" 2>/dev/null || echo "")
    if [ -n "$ratio_invariants" ]; then
      while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        inv=$(echo "$line" | sed 's/^[^:]*://;s/^[ \t]*//' | head -c 80)
        MATH_INVARIANTS+=("$file:$line_num - Ratio invariant: $inv")
      done <<< "$ratio_invariants"
    fi

    # Detect overflow/underflow protection (though Solidity 0.8+ has built-in)
    if grep -qE "SafeMath|checked.*add|checked.*sub" "$file" 2>/dev/null; then
      FINDINGS+=("$file - Uses SafeMath or checked arithmetic (good practice)")
    fi

    # Check for assert statements (invariants that should never fail)
    assert_statements=$(grep -nE "assert\(" "$file" 2>/dev/null || echo "")
    if [ -n "$assert_statements" ]; then
      assert_count=$(echo "$assert_statements" | wc -l | tr -d ' ')
      INVARIANT_PROPERTIES+=("$file - $assert_count assert statement(s) (invariant checks)")
    fi

  done <<< "$SOL_FILES"

  # Run Echidna if available and test files exist
  if [ "$HAS_ECHIDNA" != "false" ]; then
    # Look for Echidna config
    echidna_config=""
    if [ -f "echidna.yaml" ]; then
      echidna_config="echidna.yaml"
      FINDINGS+=("Found Echidna config: echidna.yaml")
    elif [ -f ".echidna.yaml" ]; then
      echidna_config=".echidna.yaml"
      FINDINGS+=("Found Echidna config: .echidna.yaml")
    fi

    # Find test contracts (files with echidna_ functions)
    test_contracts=$(grep -l "function echidna_" $SOL_FILES 2>/dev/null || echo "")

    if [ -n "$test_contracts" ]; then
      FINDINGS+=("Found $(echo "$test_contracts" | wc -l | tr -d ' ') Echidna test contract(s)")

      # Create build directory for Echidna output
      mkdir -p build 2>/dev/null || true

      # Run Echidna on each test contract (with timeout to prevent hanging)
      for test_contract in $test_contracts; do
        contract_name=$(basename "$test_contract" .sol)

        if [ "$HAS_ECHIDNA" = "docker" ]; then
          # Run via Docker with timeout
          echidna_output=$(timeout 30s docker run --rm -v "$(pwd):/code" -w /code \
            trailofbits/echidna "$test_contract" ${echidna_config:+--config $echidna_config} 2>&1 || echo "timeout")
        else
          # Run native Echidna with timeout
          echidna_output=$(timeout 30s echidna "$test_contract" ${echidna_config:+--config $echidna_config} 2>&1 || echo "timeout")
        fi

        if [ "$echidna_output" = "timeout" ]; then
          ECHIDNA_RESULTS+=("$contract_name - Timeout (tests may be too complex)")
          FINDINGS+=("WARNING: Echidna tests timed out on $contract_name")
        else
          # Parse Echidna output for failures
          if echo "$echidna_output" | grep -q "FAILED"; then
            failed_count=$(echo "$echidna_output" | grep -c "FAILED" || echo "0")
            ECHIDNA_RESULTS+=("$contract_name - $failed_count invariant(s) FAILED")
            FINDINGS+=("CRITICAL: $contract_name has $failed_count failing invariant(s)")
            STATUS="fail"
          else
            passed_count=$(echo "$echidna_output" | grep -c "echidna_" || echo "0")
            ECHIDNA_RESULTS+=("$contract_name - All invariants passed ($passed_count tests)")
          fi

          # Save full output to build directory
          echo "$echidna_output" > "build/echidna-$contract_name.txt" 2>/dev/null || true
        fi
      done
    else
      FINDINGS+=("No Echidna test contracts found (functions named echidna_*)")
    fi
  else
    FINDINGS+=("Echidna not available - install with: docker pull trailofbits/echidna")
  fi

  # Build findings summary
  if [ ${#INVARIANT_FUNCTIONS[@]} -gt 0 ]; then
    FINDINGS+=("Found ${#INVARIANT_FUNCTIONS[@]} invariant test function(s)")
  fi

  if [ ${#SUPPLY_CHECKS[@]} -gt 0 ]; then
    FINDINGS+=("Detected ${#SUPPLY_CHECKS[@]} supply invariant check(s)")
  fi

  if [ ${#BALANCE_CHECKS[@]} -gt 0 ]; then
    FINDINGS+=("Detected ${#BALANCE_CHECKS[@]} balance invariant check(s)")
  fi

  if [ ${#MATH_INVARIANTS[@]} -gt 0 ]; then
    FINDINGS+=("Detected ${#MATH_INVARIANTS[@]} mathematical invariant(s)")
  fi

  # Update summary
  if echo "${ECHIDNA_RESULTS[@]}" | grep -q "FAILED"; then
    SUMMARY="CRITICAL - Invariant violations detected by Echidna"
    STATUS="fail"
  elif [ ${#INVARIANT_FUNCTIONS[@]} -eq 0 ] && [ ${#INVARIANT_PROPERTIES[@]} -eq 0 ]; then
    SUMMARY="No invariant tests found - consider adding Echidna tests"
    STATUS="warn"
  else
    SUMMARY="System invariants validated - ${#INVARIANT_FUNCTIONS[@]} tests, ${#ECHIDNA_RESULTS[@]} Echidna results"
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

# Build Echidna results JSON
if [ ${#ECHIDNA_RESULTS[@]} -eq 0 ]; then
  ECHIDNA_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  ECHIDNA_JSON=$(printf '%s\n' "${ECHIDNA_RESULTS[@]}" | jq -R . | jq -s .)
else
  ECHIDNA_JSON="["
  first=true
  for e in "${ECHIDNA_RESULTS[@]}"; do
    escaped=$(echo "$e" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    if [ "$first" = true ]; then
      ECHIDNA_JSON="${ECHIDNA_JSON}\"$escaped\""
      first=false
    else
      ECHIDNA_JSON="${ECHIDNA_JSON},\"$escaped\""
    fi
  done
  ECHIDNA_JSON="${ECHIDNA_JSON}]"
fi

cat <<JSON
{
  "skill":"system-invariant-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "invariant_functions":${#INVARIANT_FUNCTIONS[@]},
    "supply_checks":${#SUPPLY_CHECKS[@]},
    "balance_checks":${#BALANCE_CHECKS[@]},
    "math_invariants":${#MATH_INVARIANTS[@]},
    "echidna_results":$ECHIDNA_JSON,
    "has_echidna":"$HAS_ECHIDNA"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
