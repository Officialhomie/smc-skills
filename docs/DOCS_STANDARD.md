# Documentation standard

This project uses the **[Cyfrin claude-docs-prompts](https://github.com/Cyfrin/claude-docs-prompts)** approach as the standard for documentation so that:

- **Humans** get clear READMEs, quick starts, and reference.
- **AI agents** (Claude, Cursor, etc.) get consistent structure and a single `CLAUDE.md` that describes the repo and how to work with it.

## What we use from Cyfrin

| Cyfrin convention        | How we use it here                                      |
|--------------------------|---------------------------------------------------------|
| Root `CLAUDE.md`         | Agent instructions + pointer to this standard           |
| `.docs-config.json`      | Repo-specific values (title, description, repo URL)     |
| README in root           | Quick start, structure, usage, JSON artifact format     |
| Diataxis-style content   | Quickstart → how-tos → reference in README & SKILLS_CATALOG |
| Local customizations     | Repo-specific section below marker in `CLAUDE.md`        |
| Update from upstream     | `curl -fsSL .../install.sh \| bash` to refresh template  |

## What we don’t use (docs-site specific)

The Cyfrin template also defines things for **Next.js docs sites** (PrevNextNav, PageActions, llms.txt, search index, MDX, etc.). This repo is a **CLI/skills toolkit**, not a docs site, so we only adopt the parts above. We do not add:

- Next.js/MDX app structure
- `config/docs.json` or nav tree
- `scripts/check-links.ts`, `build-llms-txt.ts`, `build-search-index.ts`
- Tailwind/MDX/lucide-react conventions

## Where docs live

- **README.md** — First thing humans and agents see. Keep it accurate and up to date.
- **SKILLS_CATALOG.md** — Full list and description of each skill.
- **docs/** — Longer or meta docs (e.g. this file). Link from README when relevant.
- **CLAUDE.md** — For AI: project layout, conventions, and repo-specific instructions.

## Keeping the standard up to date

- Re-run the Cyfrin install when you want to pull template changes:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/Cyfrin/claude-docs-prompts/main/install.sh | bash
  ```
- Everything in `CLAUDE.md` **below** the line `<!-- LOCAL CUSTOMIZATIONS ... -->` is kept when you update.
- Edit `.docs-config.json` by hand; the install script does not overwrite it.
