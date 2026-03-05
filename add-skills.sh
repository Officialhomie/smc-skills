#!/usr/bin/env bash
# add-skills — copy root-level skills into a project's tools/skills/
# Usage:
#   ./add-skills.sh                    # add to current directory
#   ./add-skills.sh /path/to/project   # add to given project
#   add-skills.sh --link               # symlink instead of copy (default: copy)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SKILLS_SRC="${SCRIPT_DIR}/skills"
LINK=0
TARGET_DIR=""
for arg in "$@"; do
  if [ "$arg" = "--link" ]; then
    LINK=1
  elif [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$arg"
  fi
done
[ -z "$TARGET_DIR" ] && TARGET_DIR="."

if [ ! -d "$SKILLS_SRC" ]; then
  echo "Error: skills directory not found at $SKILLS_SRC" >&2
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR" || { echo "Error: cannot create target: $TARGET_DIR" >&2; exit 1; }
fi
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
DEST="${TARGET_DIR}/tools/skills"
mkdir -p "$DEST"

count=0
for f in "$SKILLS_SRC"/*.sh; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  if [ "$LINK" -eq 1 ]; then
    ln -sf "$f" "$DEST/$name"
  else
    cp "$f" "$DEST/$name"
  fi
  chmod +x "$DEST/$name"
  echo "  + $name"
  count=$((count + 1))
done

echo "Done: $count skills installed to $DEST"
echo "Run orchestrator: $DEST/ci-orchestrator.sh"
