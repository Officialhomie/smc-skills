#!/usr/bin/env bash
# Skill 12: Upgradeability Pattern Check
# Validates UUPS, Transparent Proxy patterns
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="upgradeability patterns validated"
FINDINGS=()

# Check for proxy patterns
PROXY_PATTERNS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "UUPSUpgradeable\|TransparentUpgradeableProxy\|Proxy" || true)

if [ -n "$PROXY_PATTERNS" ]; then
  # Check for initializer instead of constructor
  CONSTRUCTORS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -E "constructor\(" | grep -v "// constructor" || true)

  if [ -n "$CONSTRUCTORS" ]; then
    FINDINGS+=("Upgradeable contract uses constructor (should use initializer)")
    STATUS="fail"
  fi

  # Check for initializer modifier
  if ! find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "initializer" >/dev/null 2>&1; then
    FINDINGS+=("Upgradeable contract missing initializer modifier")
    STATUS="fail"
  fi

  # Check for storage gaps
  if ! find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "__gap" >/dev/null 2>&1; then
    FINDINGS+=("Upgradeable contract missing storage gap")
    STATUS="warn"
    SUMMARY="missing storage gaps for upgrades"
  fi

  # Check for _authorizeUpgrade in UUPS
  if find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "UUPSUpgradeable" >/dev/null 2>&1; then
    if ! find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "_authorizeUpgrade" >/dev/null 2>&1; then
      FINDINGS+=("UUPS contract missing _authorizeUpgrade function")
      STATUS="fail"
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
  "skill":"upgradeability-check",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "proxy_files":"$(echo "$PROXY_PATTERNS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
