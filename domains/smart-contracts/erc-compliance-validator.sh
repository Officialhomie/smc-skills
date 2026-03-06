#!/usr/bin/env bash
# Skill 18: ERC Compliance Validator
# Validates ERC20, ERC721, ERC1155 compliance
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="ERC standards compliance validated"
FINDINGS=()

# ERC20 Compliance Check
ERC20_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "is ERC20\|is IERC20" || true)

if [ -n "$ERC20_FILES" ]; then
  REQUIRED_ERC20_FUNCS=("totalSupply" "balanceOf" "transfer" "allowance" "approve" "transferFrom")

  while IFS= read -r file; do
    for func in "${REQUIRED_ERC20_FUNCS[@]}"; do
      if ! grep -q "function $func" "$file"; then
        FINDINGS+=("$file: Missing ERC20 function $func")
        STATUS="fail"
      fi
    done

    # Check for Transfer and Approval events
    if ! grep -q "event Transfer" "$file"; then
      FINDINGS+=("$file: Missing Transfer event")
      STATUS="fail"
    fi

    if ! grep -q "event Approval" "$file"; then
      FINDINGS+=("$file: Missing Approval event")
      STATUS="fail"
    fi
  done <<< "$ERC20_FILES"
fi

# ERC721 Compliance Check
ERC721_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "is ERC721\|is IERC721" || true)

if [ -n "$ERC721_FILES" ]; then
  REQUIRED_ERC721_FUNCS=("balanceOf" "ownerOf" "safeTransferFrom" "transferFrom" "approve" "setApprovalForAll" "getApproved" "isApprovedForAll")

  while IFS= read -r file; do
    for func in "${REQUIRED_ERC721_FUNCS[@]}"; do
      if ! grep -q "function $func" "$file"; then
        FINDINGS+=("$file: Missing ERC721 function $func")
        STATUS="fail"
      fi
    done

    # Check for ERC721 events
    if ! grep -q "event Transfer" "$file"; then
      FINDINGS+=("$file: Missing Transfer event")
      STATUS="fail"
    fi
  done <<< "$ERC721_FILES"
fi

# ERC1155 Compliance Check
ERC1155_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "is ERC1155\|is IERC1155" || true)

if [ -n "$ERC1155_FILES" ]; then
  REQUIRED_ERC1155_FUNCS=("balanceOf" "balanceOfBatch" "setApprovalForAll" "isApprovedForAll" "safeTransferFrom" "safeBatchTransferFrom")

  while IFS= read -r file; do
    for func in "${REQUIRED_ERC1155_FUNCS[@]}"; do
      if ! grep -q "function $func" "$file"; then
        FINDINGS+=("$file: Missing ERC1155 function $func")
        STATUS="fail"
      fi
    done
  done <<< "$ERC1155_FILES"
fi

# Check for supportsInterface (ERC165)
INTERFACE_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "is ERC721\|is ERC1155" || true)

if [ -n "$INTERFACE_FILES" ]; then
  while IFS= read -r file; do
    if ! grep -q "function supportsInterface" "$file"; then
      FINDINGS+=("$file: Missing supportsInterface (ERC165 compliance)")
      STATUS="warn"
    fi
  done <<< "$INTERFACE_FILES"
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
  "skill":"erc-compliance-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "erc20_contracts":"$(echo "$ERC20_FILES" | wc -l | tr -d ' ')",
    "erc721_contracts":"$(echo "$ERC721_FILES" | wc -l | tr -d ' ')",
    "erc1155_contracts":"$(echo "$ERC1155_FILES" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
