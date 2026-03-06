#!/usr/bin/env bash
# install-docs-standard — Install Cyfrin-style docs standard into this repo or another project.
# Usage:
#   ./install-docs-standard.sh              # install into current repo (root)
#   ./install-docs-standard.sh /path/to/project
#
# Creates CLAUDE.md, .docs-config.json, docs/DOCS_STANDARD.md. Safe to re-run.
# Standard: https://github.com/Cyfrin/claude-docs-prompts
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SKILL="${SCRIPT_DIR}/skills/docs-standard-install.sh"
TARGET="${1:-.}"

if [ ! -x "$SKILL" ]; then
  echo "Error: skill not found or not executable: $SKILL" >&2
  exit 1
fi

out=$("$SKILL" "$TARGET")
echo "$out"
if command -v jq >/dev/null 2>&1; then
  echo ""; echo "Summary: $(echo "$out" | jq -r '.summary')"
  echo "Files: $(echo "$out" | jq -r '.artifacts.files_created | join(", ")')"
else
  echo ""; echo "Docs standard applied. Use | jq to inspect JSON."
fi
