#!/usr/bin/env bash
# Skill 13: Storage Collision Detector
# Detects potential storage slot collisions in upgradeable contracts
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="no storage collisions detected"
WARNINGS=()

# Check for storage layout changes in upgradeable contracts
UPGRADEABLE=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "Upgradeable" || true)

if [ -n "$UPGRADEABLE" ]; then
  # Check for storage gaps
  while IFS= read -r file; do
    if ! grep -q "__gap" "$file" 2>/dev/null; then
      WARNINGS+=("$file: missing storage gap")
      STATUS="warn"
    fi

    # Check for constant/immutable (safe from collision)
    CONSTANTS=$(grep -c "constant\|immutable" "$file" 2>/dev/null || echo "0")

    # Check for state variables without gaps
    STATE_VARS=$(grep -E "^\s+(uint|address|bool|bytes|string|mapping)" "$file" 2>/dev/null | grep -v "constant\|immutable" | wc -l | tr -d ' ')

    if [ "$STATE_VARS" -gt 0 ] && ! grep -q "__gap" "$file"; then
      WARNINGS+=("$file: $STATE_VARS state variables without storage gap")
      STATUS="fail"
      SUMMARY="storage collision risk detected"
    fi
  done <<< "$UPGRADEABLE"
fi

# Check for forge storage layout command availability
if command -v forge >/dev/null 2>&1; then
  # Generate storage layout
  forge inspect --help 2>&1 | grep -q "storage-layout" && {
    mkdir -p build
    forge inspect src/Counter.sol:Counter storage-layout > build/storage-layout.json 2>/dev/null || true
  }
fi

# Build JSON array
if [ ${#WARNINGS[@]} -eq 0 ]; then
  WARNINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  WARNINGS_JSON=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
else
  WARNINGS_JSON="[\"${WARNINGS[0]}\""
  for w in "${WARNINGS[@]:1}"; do
    WARNINGS_JSON="$WARNINGS_JSON,\"$w\""
  done
  WARNINGS_JSON="${WARNINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"storage-collision-detector",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "warnings":$WARNINGS_JSON,
    "storage_layout":"build/storage-layout.json"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
