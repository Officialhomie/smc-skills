# Documentation standard (human + AI)

This repo follows the **[Cyfrin claude-docs-prompts](https://github.com/Cyfrin/claude-docs-prompts)** standard so documentation works for both humans and AI agents.

**Before making changes**, read `.docs-config.json` in the repo root for repo-specific values (GitHub repo, branch, site title, description). Use these when docs reference the repo or published content.

## What we adopt from Cyfrin

- **README in repo root** — Explains how to run/use the project (quick start, structure, usage). Required.
- **Content organization (Diataxis)** — Quickstart, installation/how-to, reference, explanation where applicable.
- **Single source of truth** — Docs live in `README.md`, `SKILLS_CATALOG.md`, and `docs/`. Keep them in sync.
- **Local customizations** — Repo-specific agent instructions go below the marker in this file (see bottom).

## Project structure (this repo)

```
skills-setup-homie/
  skills/                 # All skill scripts (source of truth). Run from project root or via add-skills.
  add-skills.sh           # CLI: install skills into any project (copy or --link)
  smc-init                # Bootstrap new Foundry project with skills
  README.md               # Quick start, structure, usage, JSON format
  SKILLS_CATALOG.md       # Full skill reference
  docs/                   # Extended docs (standards, guides)
  .docs-config.json       # Repo config (from Cyfrin convention)
  CLAUDE.md               # This file — agent instructions + standard
```

## Writing docs (human + AI)

- **README.md** — Quick start, structure, how to add skills, run orchestrator, JSON artifact format. Keep paths and examples accurate (e.g. `skills/`, `add-skills.sh`).
- **SKILLS_CATALOG.md** — One entry per skill: name, path, purpose, artifact schema. Update when adding or changing skills.
- **docs/** — Deeper guides (e.g. DOCS_STANDARD.md, upgrade guides). Use clear headings and lists so agents can parse.
- **CLAUDE.md** — Agent-facing: project layout, conventions, where to find things. Repo-specific instructions below the marker.

All docs should be readable as plain Markdown and avoid assuming a specific doc site (no MDX-only or Next.js-only content).

## Skill scripts and artifacts

- Every script in `skills/` is executable, POSIX-friendly, and emits **one JSON object** to stdout.
- Standard fields: `skill`, `status` (pass|fail|warn), `summary`, `artifacts`, `metadata`.
- Scripts resolve project root via `git rev-parse --show-toplevel` or `PWD` so they work from any subdirectory or when invoked from another repo after `add-skills.sh`.

## Updating the Cyfrin template

To refresh the docs template from upstream (e.g. after Cyfrin changes):

```bash
curl -fsSL https://raw.githubusercontent.com/Cyfrin/claude-docs-prompts/main/install.sh | bash
```

This updates the template portion of `CLAUDE.md` and preserves everything below the local customizations marker. `.docs-config.json` is never overwritten.

<!-- LOCAL CUSTOMIZATIONS — everything below this line is preserved on update -->

---

## Repo-specific instructions for AI agents

- **Skills location:** All skill scripts live in `skills/` at repo root. Canonical path: `/Users/mac/skills-setup-homie/skills/` (or `$REPO_ROOT/skills/`).
- **Adding skills to a project:** Run `./add-skills.sh` (from this repo) with no args to install into current directory, or `./add-skills.sh /path/to/project`. Use `--link` to symlink instead of copy.
- **Orchestrator:** After installing skills into a project, run `./tools/skills/ci-orchestrator.sh` from that project. The orchestrator runs each skill in order and exits on first `"status":"fail"`.
- **New skills:** Add script to `skills/`, `chmod +x`, emit JSON with `skill`, `status`, `summary`, `artifacts`, `metadata`. Update `ci-orchestrator.sh` and `SKILLS_CATALOG.md`.
- **Docs:** When editing README or SKILLS_CATALOG, keep examples and paths consistent with the structure above. Follow the Cyfrin-inspired standard: clear quickstart, how-tos, and reference.
