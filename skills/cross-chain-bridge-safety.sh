#!/usr/bin/env bash
# Skill 73: Cross-Chain Bridge Safety
# Validates bridge security patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="bridge security patterns validated"
FINDINGS=()

# Check for bridge contracts
BRIDGE_CONTRACTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "bridge\|Bridge\|lock.*mint\|burn.*release" || true)

if [ -n "$BRIDGE_CONTRACTS" ]; then
  while IFS= read -r file; do
    # Check for nonce tracking to prevent replay attacks
    if grep -q "bridge\|lock\|release" "$file"; then
      if ! grep -q "nonce\|chainId\|sequence\|messageId" "$file"; then
        FINDINGS+=("$file: Bridge without replay attack prevention (no nonce/chainId)")
        STATUS="fail"
      fi
    fi

    # Check for signature validation
    if grep -q "bridge.*transfer\|lock.*mint\|burn.*release" "$file"; then
      if ! grep -q "signature\|ecrecover\|verify\|ECDSA" "$file"; then
        FINDINGS+=("$file: Bridge transfer without signature validation")
        STATUS="fail"
      fi
    fi

    # Check for amount validation
    if grep -q "function.*bridge\|function.*lock\|function.*release" "$file"; then
      if ! grep -q "require.*amount\|require.*balance\|assert.*value" "$file"; then
        FINDINGS+=("$file: Bridge transfer without amount validation")
        STATUS="fail"
      fi
    fi

    # Check for token whitelisting
    if grep -q "supportedTokens\|tokenList\|bridge.*token" "$file"; then
      if ! grep -q "isSupported\|whitelist\|allowedTokens" "$file"; then
        FINDINGS+=("$file: No token whitelist enforcement")
        STATUS="warn"
      fi
    fi

    # Check for liquidity management
    if grep -q "release\|withdraw" "$file"; then
      if ! grep -q "liquidity\|reserve\|pool\|balance.*check" "$file"; then
        FINDINGS+=("$file: No liquidity verification before release")
        STATUS="warn"
      fi
    fi

    # Check for pause mechanism
    if grep -q "bridge.*transfer" "$file"; then
      if ! grep -q "whenNotPaused\|paused\|emergency" "$file"; then
        FINDINGS+=("$file: Bridge without pause/emergency mechanism")
        STATUS="warn"
      fi
    fi

    # Check for event logging
    if grep -q "function.*bridge\|function.*lock" "$file"; then
      if ! grep -q "event.*Bridge\|event.*Lock\|emit.*Bridge" "$file"; then
        FINDINGS+=("$file: Bridge operations without event logging")
        STATUS="warn"
      fi
    fi
  done <<< "$BRIDGE_CONTRACTS"

  SUMMARY="bridge security validation completed"
fi

# Check for bridge configuration
BRIDGE_CONFIG=$(find . -name "*.json" -o -name "*.config.*" 2>/dev/null | xargs grep -l "bridge\|chainId\|rpc" || true)

if [ -n "$BRIDGE_CONFIG" ]; then
  # Check for multiple chain support
  CHAIN_COUNT=$(grep -o "chainId\|chain" "$BRIDGE_CONFIG" 2>/dev/null | wc -l || echo "0")
  if [ "$CHAIN_COUNT" -lt 2 ]; then
    FINDINGS+=("Bridge config: Limited to single chain (no multi-chain redundancy)")
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
  "skill":"cross-chain-bridge-safety",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "bridge_contracts":"$(echo "$BRIDGE_CONTRACTS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
