#!/usr/bin/env bash
# Skill 77: IPFS Pinning Checker
# Checks IPFS content availability patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="IPFS pinning availability patterns validated"
FINDINGS=()

# Check for IPFS usage
IPFS_REFS=$(find src contracts -name "*.sol" -o -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "ipfs://\|IPFS\|Qm[a-zA-Z0-9]\|bafyby\|bafkreie" 2>/dev/null || true)

if [ -n "$IPFS_REFS" ]; then
  while IFS= read -r file; do
    # Check for IPFS hash validation
    if grep -q "ipfs://\|Qm[a-zA-Z0-9]\|bafyby" "$file"; then
      if ! grep -q "validateHash\|isValidCID\|CID\|ipfs.*verify" "$file"; then
        FINDINGS+=("$file: IPFS references without hash validation")
        STATUS="warn"
      fi
    fi

    # Check for pinning service integration
    if grep -q "ipfs://\|IPFS" "$file"; then
      if ! grep -q "pinning\|pinata\|nft.storage\|web3.storage" "$file"; then
        FINDINGS+=("$file: IPFS usage without pinning service configured")
        STATUS="warn"
      fi
    fi

    # Check for timeout on IPFS operations
    if grep -q "ipfs.*add\|ipfs.*get\|ipfs.*cat" "$file"; then
      if ! grep -q "timeout\|maxRetries\|deadline" "$file"; then
        FINDINGS+=("$file: IPFS operations without timeout")
        STATUS="warn"
      fi
    fi

    # Check for fallback mechanisms
    if grep -q "ipfs://" "$file"; then
      if ! grep -q "fallback\|backup\|https://\|gateway" "$file"; then
        FINDINGS+=("$file: IPFS references without HTTP gateway fallback")
        STATUS="warn"
      fi
    fi
  done <<< "$IPFS_REFS"

  SUMMARY="IPFS pinning configuration validated"
fi

# Check for IPFS configuration files
IPFS_CONFIG=$(find . -name ".ipfs*" -o -name "ipfs*config*" -o -name "*pinning*config*" 2>/dev/null)

if [ -n "$IPFS_CONFIG" ]; then
  while IFS= read -r file; do
    # Check for redundant pinning
    if grep -q "pinning\|pin" "$file" 2>/dev/null; then
      PIN_SERVICE_COUNT=$(grep -o "pinata\|nft.storage\|web3.storage\|ipfs.*service" "$file" 2>/dev/null | sort -u | wc -l || echo "0")

      if [ "$PIN_SERVICE_COUNT" -lt 1 ]; then
        FINDINGS+=("$file: No pinning service configured")
        STATUS="warn"
      elif [ "$PIN_SERVICE_COUNT" -lt 2 ]; then
        FINDINGS+=("$file: Single pinning service (consider redundancy)")
        STATUS="warn"
      fi
    fi

    # Check for API key security
    if grep -q "api.*key\|secret.*key\|authorization\|bearer" "$file" 2>/dev/null; then
      FINDINGS+=("$file: Potential secrets in IPFS configuration")
      STATUS="fail"
    fi
  done <<< "$IPFS_CONFIG"
fi

# Check for package.json IPFS dependencies
if [ -f "package.json" ]; then
  if grep -q "ipfs\|web3.storage\|nft.storage" package.json; then
    # Check for version pinning
    IPFS_DEP_COUNT=$(grep -o '"ipfs.*":' package.json | wc -l || echo "0")

    if [ "$IPFS_DEP_COUNT" -gt 0 ]; then
      if ! grep "ipfs.*exact\|ipfs.*[0-9]\.[0-9]\.[0-9]" package.json >/dev/null; then
        FINDINGS+=("package.json: IPFS dependencies without pinned versions")
        STATUS="warn"
      fi
    fi
  fi
fi

# Check for .env or environment variables
if [ -f ".env" ] || [ -f ".env.example" ]; then
  ENV_FILE=$([ -f ".env" ] && echo ".env" || echo ".env.example")

  if grep -q "IPFS\|PINATA\|WEB3_STORAGE" "$ENV_FILE"; then
    if ! grep -q "IPFS_GATEWAY\|PINATA_.*KEY\|WEB3_STORAGE_KEY" "$ENV_FILE"; then
      FINDINGS+=("$ENV_FILE: IPFS config with missing gateway or service keys")
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
  "skill":"ipfs-pinning-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "ipfs_files":"$(echo "$IPFS_REFS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
