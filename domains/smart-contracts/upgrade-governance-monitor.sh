#!/usr/bin/env bash
# Skill 68: Upgrade Governance Monitor
# Monitors upgrade proposal patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="upgrade governance patterns analyzed"
UPGRADE_FINDINGS=()

# Check for proxy/upgrade patterns
PROXY_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "Proxy\|proxy\|UUPS\|ERC1967\|upgradeable" || true)

if [ -n "$PROXY_FILES" ]; then
  while IFS= read -r file; do
    UPGRADE_FINDINGS+=("$file: Proxy/upgrade contract detected")

    # Check for implementation slot
    if grep -q "IMPLEMENTATION_SLOT\|_IMPLEMENTATION_SLOT\|implementation"; then
      UPGRADE_FINDINGS+=("$file: Implementation slot defined")

      # Check if slot is properly guarded
      if ! grep -q "constant.*=.*hex\|IMPLEMENTATION.*="; then
        UPGRADE_FINDINGS+=("$file: Implementation slot without proper constant definition")
        STATUS="warn"
      fi
    else
      UPGRADE_FINDINGS+=("$file: Proxy without explicit implementation slot")
      STATUS="warn"
    fi

    # Check for upgrade authorization
    if grep -q "upgradeTo\|_authorizeUpgrade\|upgrade"; then
      # Check if upgrade requires authorization
      if ! grep -q "onlyOwner\|onlyGovernance\|onlyRole\|_authorizeUpgrade"; then
        UPGRADE_FINDINGS+=("$file: Upgrade function without access control (CRITICAL)")
        STATUS="fail"
      else
        UPGRADE_FINDINGS+=("$file: Upgrade protected by authorization")
      fi
    fi

    # Check for storage layout preservation
    if grep -q "struct.*Storage\|storageLayout\|__gap"; then
      UPGRADE_FINDINGS+=("$file: Storage layout documentation detected")
    else
      UPGRADE_FINDINGS+=("$file: No storage layout documentation (maintain __gap for upgrades)")
      STATUS="warn"
    fi

    # Check for initialization protection
    if grep -q "initializer\|_initialized" "$file"; then
      UPGRADE_FINDINGS+=("$file: Initialization protection implemented")

      # Check if initializer is called in constructor
      if ! grep -q "reinitializer\|initializer" "$file"; then
        UPGRADE_FINDINGS+=("$file: No re-initialization protection detected")
        STATUS="warn"
      fi
    else
      UPGRADE_FINDINGS+=("$file: No initialization protection (add initializer modifier)")
      STATUS="warn"
    fi
  done <<< "$PROXY_FILES"
else
  UPGRADE_FINDINGS+=("No proxy/upgrade patterns detected")
fi

# Check for UUPS-specific patterns
UUPS_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "UUPS\|_authorizeUpgrade" || true)

if [ -n "$UUPS_FILES" ]; then
  while IFS= read -r file; do
    UPGRADE_FINDINGS+=("$file: UUPS upgrade pattern detected")

    # Check if _authorizeUpgrade is implemented
    if grep -q "function _authorizeUpgrade" "$file"; then
      UPGRADE_FINDINGS+=("$file: _authorizeUpgrade override implemented")

      # Check for access control in _authorizeUpgrade
      AUTH_FUNC=$(grep -A5 "function _authorizeUpgrade" "$file")

      if ! echo "$AUTH_FUNC" | grep -q "require\|onlyOwner\|onlyGovernance"; then
        UPGRADE_FINDINGS+=("$file: _authorizeUpgrade without proper authorization")
        STATUS="fail"
      fi
    else
      UPGRADE_FINDINGS+=("$file: _authorizeUpgrade not implemented")
      STATUS="fail"
    fi
  done <<< "$UUPS_FILES"
fi

# Check for upgrade events
UPGRADE_EVENTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emit.*Upgrade\|emit.*Implementation\|Upgraded" || true)

if [ -n "$UPGRADE_EVENTS" ]; then
  while IFS= read -r file; do
    EVENT_COUNT=$(grep -c "emit.*Upgrade\|Upgraded" "$file" || echo "0")

    UPGRADE_FINDINGS+=("$file: $EVENT_COUNT upgrade event(s) defined")
  done <<< "$UPGRADE_EVENTS"
else
  UPGRADE_FINDINGS+=("No upgrade events found (should emit on implementation change)")
  STATUS="warn"
fi

# Check for upgrade governance patterns
GOVERNANCE_UPGRADE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "governance.*upgrade\|upgrade.*governance\|upgradeProposal" || true)

if [ -n "$GOVERNANCE_UPGRADE" ]; then
  while IFS= read -r file; do
    UPGRADE_FINDINGS+=("$file: Governance-controlled upgrades detected")

    # Check for upgrade delay/timelock
    if ! grep -q "delay\|timelock\|proposal.*period"; then
      UPGRADE_FINDINGS+=("$file: Governance upgrade without timelock")
      STATUS="warn"
    fi
  done <<< "$GOVERNANCE_UPGRADE"
fi

# Check for version tracking
VERSION_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "version\|VERSION" || true)

if [ -n "$VERSION_FILES" ]; then
  while IFS= read -r file; do
    # Check if contract version is tracked
    if grep -q "contract.*[vV][0-9]\|_VERSION\|version.*=" "$file"; then
      UPGRADE_FINDINGS+=("$file: Contract version tracking implemented")
    fi
  done <<< "$VERSION_FILES"
else
  UPGRADE_FINDINGS+=("No version tracking detected (recommend adding)")
  STATUS="warn"
fi

# Check for migration/upgrade scripts
MIGRATION_FILES=$(find . -name "*migration*" -o -name "*upgrade*" -o -name "*deploy*" 2>/dev/null | grep -v node_modules | grep -v ".git" || true)

if [ -n "$MIGRATION_FILES" ]; then
  UPGRADE_FINDINGS+=("Migration/upgrade scripts found")
else
  UPGRADE_FINDINGS+=("No migration/upgrade scripts detected")
  STATUS="warn"
fi

# Check for upgrade safety patterns
DELEGATECALL_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "delegatecall" || true)

if [ -n "$DELEGATECALL_FILES" ]; then
  while IFS= read -r file; do
    # Check if delegatecall is used safely
    DELEGATECALL_LINES=$(grep -n "delegatecall" "$file" || true)

    while IFS= read -r line_info; do
      [ -z "$line_info" ] && continue

      LINE_NUM=$(echo "$line_info" | cut -d: -f1)
      CALL_CONTEXT=$(tail -n +$LINE_NUM "$file" | head -10)

      if ! echo "$CALL_CONTEXT" | grep -q "require.*success\|require.*result"; then
        UPGRADE_FINDINGS+=("$file:$LINE_NUM: delegatecall without return value check")
        STATUS="warn"
      fi
    done <<< "$DELEGATECALL_LINES"
  done <<< "$DELEGATECALL_FILES"
fi

# Check for fallback function (in proxies)
FALLBACK_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "fallback\|receive" || true)

if [ -n "$FALLBACK_FILES" ]; then
  while IFS= read -r file; do
    # Check if fallback is properly delegating
    if grep -q "fallback.*{" "$file"; then
      FALLBACK_BODY=$(grep -A10 "fallback.*{" "$file")

      if ! echo "$FALLBACK_BODY" | grep -q "delegatecall\|_delegate"; then
        UPGRADE_FINDINGS+=("$file: Fallback function without proper delegation")
        STATUS="warn"
      else
        UPGRADE_FINDINGS+=("$file: Fallback function properly implements delegation")
      fi
    fi
  done <<< "$FALLBACK_FILES"
fi

# Check for upgrade documentation
UPGRADE_DOCS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "upgrade\|UPGRADE" 2>/dev/null || true)

if [ -n "$UPGRADE_DOCS" ]; then
  UPGRADE_FINDINGS+=("Upgrade documentation found")
else
  UPGRADE_FINDINGS+=("No upgrade documentation (document upgrade process)")
  STATUS="warn"
fi

# Check for testnet upgrade testing
TEST_FILES=$(find . -name "*test*" -o -name "*spec*" 2>/dev/null | xargs grep -l "upgrade\|proxy" 2>/dev/null || true)

if [ -n "$TEST_FILES" ]; then
  UPGRADE_FINDINGS+=("Upgrade testing detected")
else
  UPGRADE_FINDINGS+=("No upgrade tests found (test upgrade paths)")
  STATUS="warn"
fi

# Build JSON array
if [ ${#UPGRADE_FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${UPGRADE_FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${UPGRADE_FINDINGS[0]}\""
  for u in "${UPGRADE_FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$u\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"upgrade-governance-monitor",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "upgrade_findings":$FINDINGS_JSON,
    "finding_count":${#UPGRADE_FINDINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
