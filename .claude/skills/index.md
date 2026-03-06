---
description: Entry point for agents navigating the Web3 Systems Architecture Platform — 79 production skills across 10 phases of smart contract validation, organized as a traversable skill graph.
tags: [index, web3, platform, skill-graph]
links: [smart-contracts]
---

# Web3 Systems Architecture Platform — Skill Graph

This is the navigational entry point for the platform. Follow wikilinks progressively to load only what the current task requires.

## Domains

- [[smart-contracts]] — **79 skills, production ready.** Solidity/Foundry validation across 10 phases: from project structure and security analysis through economic design, live monitoring, and off-chain infrastructure.
- Frontend, Backend, Infrastructure, Security Analysis — planned domains (see `DOMAINS_CATALOG.md` for roadmap).

## How to Navigate

**From a concept** (e.g. "how does this system check for flash loan risk?"):
1. Go to `concepts/flash-loans.md` — explains the concept, names the exact skills, provides `jq` queries
2. Follow concept wikilinks to related nodes (e.g. [[smart-contracts]] → `oracle-manipulation`, `economic-attacks`)

**From a phase** (e.g. "what runs in the security phase?"):
1. Go to [[smart-contracts]] for the pipeline overview
2. Follow the phase link (e.g. `phases/phase-02-security.md`) for skill list and bash invocations

**From a task** (e.g. "run the full pipeline"):
```bash
./domains/smart-contracts/ci-orchestrator.sh
```

## Skill Graph Structure

```
index.md (here)
└── smart-contracts.md          ← domain MOC
    ├── phases/phase-01-*.md    ← what each phase validates + bash invocations
    │   └── phases/phase-02-*.md
    │       └── ...
    └── concepts/*.md           ← security/economic concepts + which skills check for them
        ├── reentrancy.md
        ├── flash-loans.md
        ├── oracle-manipulation.md
        └── ... (17 more)
```

## Reference Docs (non-graph)

- `SKILLS_CATALOG.md` — full parameter and status code reference per skill
- `DOMAINS_CATALOG.md` — complete skill-to-phase assignments and domain roadmap
- `README.md` — quick start, installation, and platform overview
