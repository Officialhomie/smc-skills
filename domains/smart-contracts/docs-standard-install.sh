#!/usr/bin/env bash
# docs-standard-install — Install Cyfrin-style docs standard (CLAUDE.md, .docs-config.json, docs/DOCS_STANDARD.md) into a project. Works from repo root or any project.
# Usage: docs-standard-install.sh [TARGET_DIR]
# Emits JSON artifact. Run from project root or pass path.
set -e

TARGET="${1:-.}"
if [ -n "$1" ] && [ -d "$1" ]; then
  TARGET="$(cd "$1" && pwd)"
elif [ -n "$1" ] && [ ! -d "$1" ]; then
  mkdir -p "$1" && TARGET="$(cd "$1" && pwd)"
else
  TARGET="$(git rev-parse --show-toplevel 2>/dev/null)" || TARGET="$(cd "$TARGET" && pwd)"
fi
cd "$TARGET"

CREATED=()
UPDATED=()
STATUS="pass"
SUMMARY="Docs standard installed"

# Infer defaults
GITHUB_REPO=""
if git remote get-url origin 2>/dev/null | grep -q .; then
  GITHUB_REPO="$(git remote get-url origin 2>/dev/null | sed 's|.*github\.com[:/]||; s|\.git$||')"
fi
SITE_TITLE="$(basename "$(pwd)")"
[ -z "$SITE_TITLE" ] && SITE_TITLE="Project"

# 1. CLAUDE.md (with marker; do not overwrite content below marker if present)
MARKER="<!-- LOCAL CUSTOMIZATIONS — everything below this line is preserved on update -->"
if [ ! -f "CLAUDE.md" ]; then
  cat > CLAUDE.md <<'CLAUDE'
# Documentation standard (human + AI)

This project follows the **[Cyfrin claude-docs-prompts](https://github.com/Cyfrin/claude-docs-prompts)** approach so docs work for both humans and AI agents.

**Before making changes**, read `.docs-config.json` in the repo root for repo-specific values (GitHub repo, branch, site title, description).

## What we adopt from Cyfrin

- **README in repo root** — Quick start, structure, usage. Required.
- **Content organization (Diataxis)** — Quickstart, how-tos, reference where applicable.
- **Single source of truth** — Docs in README, and optionally `docs/`. Keep in sync.
- **Local customizations** — Repo-specific agent instructions go below the marker in this file.

## Project structure

See README.md for this repo’s layout. Keep README accurate.

## Updating the template

To refresh from Cyfrin (if you use their install script):

```bash
curl -fsSL https://raw.githubusercontent.com/Cyfrin/claude-docs-prompts/main/install.sh | bash
```

<!-- LOCAL CUSTOMIZATIONS — everything below this line is preserved on update -->

---

## Repo-specific instructions for AI agents

- Prefer editing README and docs under `docs/` for human + AI consumption.
- Follow Diataxis: quickstart first, then how-tos, then reference.
CLAUDE
  CREATED+=("CLAUDE.md")
else
  if ! grep -qF "$MARKER" CLAUDE.md 2>/dev/null; then
    echo "" >> CLAUDE.md
    echo "$MARKER" >> CLAUDE.md
    echo "" >> CLAUDE.md
    echo "---" >> CLAUDE.md
    echo "" >> CLAUDE.md
    echo "## Repo-specific instructions for AI agents" >> CLAUDE.md
    UPDATED+=("CLAUDE.md (marker added)")
  fi
fi

# 2. .docs-config.json (only if missing)
if [ ! -f ".docs-config.json" ]; then
  cat > .docs-config.json <<CONFIG
{
  "github_repo": "$GITHUB_REPO",
  "github_branch": "main",
  "production_url": "",
  "site_title": "$SITE_TITLE",
  "site_description": "Documentation for this project"
}
CONFIG
  CREATED+=(".docs-config.json")
fi

# 3. docs/DOCS_STANDARD.md (only if missing)
mkdir -p docs
if [ ! -f "docs/DOCS_STANDARD.md" ]; then
  cat > docs/DOCS_STANDARD.md <<'STD'
# Documentation standard

This project uses the **[Cyfrin claude-docs-prompts](https://github.com/Cyfrin/claude-docs-prompts)** approach:

- **Humans** — Clear README, quick start, reference.
- **AI agents** — Consistent structure; `CLAUDE.md` describes the repo. Repo-specific instructions go below the marker in `CLAUDE.md`.

## What we use

| Convention           | Use here                    |
|----------------------|-----------------------------|
| Root `CLAUDE.md`     | Agent instructions + marker |
| `.docs-config.json`  | Repo-specific config        |
| README in root       | Quick start, usage          |
| Local customizations| Below marker in CLAUDE.md   |

## Keeping up to date

Re-run the docs-standard installer in this repo, or:

```bash
curl -fsSL https://raw.githubusercontent.com/Cyfrin/claude-docs-prompts/main/install.sh | bash
```

Edit `.docs-config.json` by hand; it is not overwritten.
STD
  CREATED+=("docs/DOCS_STANDARD.md")
fi

# Build artifact arrays as JSON (POSIX-safe)
if [ ${#CREATED[@]} -eq 0 ] && [ ${#UPDATED[@]} -eq 0 ]; then
  SUMMARY="Docs standard already present (no changes)"
fi
CREATED_JSON="[]"
for c in "${CREATED[@]}"; do
  s="\"$(echo "$c" | sed 's/"/\\"/g')\""
  [ "$CREATED_JSON" = "[]" ] && CREATED_JSON="[$s" || CREATED_JSON="$CREATED_JSON,$s"
done
[ ${#CREATED[@]} -gt 0 ] && CREATED_JSON="${CREATED_JSON}]"
UPDATED_JSON="[]"
for u in "${UPDATED[@]}"; do
  s="\"$(echo "$u" | sed 's/"/\\"/g')\""
  [ "$UPDATED_JSON" = "[]" ] && UPDATED_JSON="[$s" || UPDATED_JSON="$UPDATED_JSON,$s"
done
[ ${#UPDATED[@]} -gt 0 ] && UPDATED_JSON="${UPDATED_JSON}]"

echo "{\"skill\":\"docs-standard-install\",\"status\":\"$STATUS\",\"summary\":\"$SUMMARY\",\"artifacts\":{\"target\":\"$TARGET\",\"files_created\":$CREATED_JSON,\"files_updated\":$UPDATED_JSON},\"metadata\":{\"timestamp\":\"$(date -u +%FT%TZ)\",\"upstream\":\"https://github.com/Cyfrin/claude-docs-prompts\"}}"
