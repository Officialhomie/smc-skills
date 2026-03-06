#!/usr/bin/env bash
# Skill 76: RPC Endpoint Validator
# Tests RPC reliability patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="RPC endpoint reliability patterns validated"
FINDINGS=()

# Check for RPC configuration
RPC_CONFIG=$(find . \( -name "*.env*" -o -name "*.config.*" -o -name "hardhat.config.*" -o -name "foundry.toml" \) 2>/dev/null | head -5)

if [ -n "$RPC_CONFIG" ]; then
  while IFS= read -r file; do
    # Check for RPC URLs
    if grep -q "RPC\|rpc\|http.*provider\|ethers" "$file" 2>/dev/null; then
      # Check for multiple RPC endpoints (redundancy)
      RPC_COUNT=$(grep -o "https://\|http://" "$file" 2>/dev/null | wc -l || echo "0")

      if [ "$RPC_COUNT" -lt 2 ]; then
        FINDINGS+=("$file: Single RPC endpoint (no redundancy)")
        STATUS="warn"
      fi

      # Check for public RPC usage
      if grep -q "infura.io\|alchemy.com\|etherscan" "$file" 2>/dev/null; then
        FINDINGS+=("$file: Using public RPC endpoints (consider private nodes)")
        STATUS="warn"
      fi

      # Check for localhost/test RPC in production config
      if grep -q "http://localhost\|127.0.0.1" "$file" 2>/dev/null; then
        if [[ "$file" != *"test"* ]] && [[ "$file" != *"dev"* ]]; then
          FINDINGS+=("$file: Localhost RPC in non-test configuration")
          STATUS="warn"
        fi
      fi
    fi
  done <<< "$RPC_CONFIG"
fi

# Check for RPC call patterns in code
RPC_CALLS=$(find src contracts -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "eth_\|call()\|sendTransaction\|getBlock\|getTransaction" 2>/dev/null || true)

if [ -n "$RPC_CALLS" ]; then
  while IFS= read -r file; do
    # Check for timeout handling
    if grep -q "eth_\|sendTransaction\|getBlock" "$file"; then
      if ! grep -q "timeout\|maxRetries\|retry\|TIMEOUT" "$file"; then
        FINDINGS+=("$file: RPC calls without timeout handling")
        STATUS="warn"
      fi
    fi

    # Check for error handling
    if grep -q "sendTransaction\|call()" "$file"; then
      if ! grep -q "try.*catch\|error.*handling\|revert" "$file"; then
        FINDINGS+=("$file: RPC calls without error handling")
        STATUS="warn"
      fi
    fi

    # Check for request batching
    RPC_CALL_COUNT=$(grep -c "eth_\|getBlock\|getTransaction" "$file" || echo "0")

    if [ "$RPC_CALL_COUNT" -gt 5 ]; then
      if ! grep -q "batch\|multicall\|rpcBatch" "$file"; then
        FINDINGS+=("$file: Multiple sequential RPC calls ($RPC_CALL_COUNT) without batching")
        STATUS="warn"
      fi
    fi
  done <<< "$RPC_CALLS"
fi

# Check for hardhat.config.ts/js
if [ -f "hardhat.config.ts" ] || [ -f "hardhat.config.js" ]; then
  HARDHAT_CONFIG=$([ -f "hardhat.config.ts" ] && echo "hardhat.config.ts" || echo "hardhat.config.js")

  # Check for network configuration
  if ! grep -q "networks:" "$HARDHAT_CONFIG"; then
    FINDINGS+=("$HARDHAT_CONFIG: Missing networks configuration")
    STATUS="warn"
  fi

  # Check for fork configuration for testing
  if ! grep -q "hardhat.*fork\|forking:" "$HARDHAT_CONFIG"; then
    FINDINGS+=("$HARDHAT_CONFIG: No forking setup for mainnet testing")
    STATUS="warn"
  fi
fi

# Check for foundry.toml
if [ -f "foundry.toml" ]; then
  if ! grep -q "rpc_endpoints\|eth_rpc_url" foundry.toml; then
    FINDINGS+=("foundry.toml: RPC endpoints not configured")
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
  "skill":"rpc-endpoint-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "rpc_call_files":"$(echo "$RPC_CALLS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
