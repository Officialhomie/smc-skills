---
description: Phase 1 Foundation — 4 skills that validate project structure, Solidity formatting, Foundry configuration, and compilation before any security analysis can begin.
tags: [phase, foundation, foundry, solidity]
links: [phase-02-security]
---

# Phase 1: Foundation

This phase validates the structural prerequisites. Without a compiling project with correct configuration, all subsequent phases produce unreliable results. Phase 1 is the gate: a `"status":"fail"` here means the CI pipeline halts immediately.

## Skills in this Phase

- `project-structure-check.sh` — validates expected directory layout (`src/`, `test/`, `script/`), `foundry.toml` presence, and git repository setup
- `solidity-format-check.sh` — runs `forge fmt --check` and validates Solidity file formatting
- `foundry-config-check.sh` — validates `foundry.toml` settings: optimizer, solc version, remappings, fuzz run count
- `compile-check.sh` — runs `forge build` and validates zero compilation errors or warnings

## Running this Phase

```bash
cd domains/smart-contracts
./project-structure-check.sh | jq .
./solidity-format-check.sh | jq .
./foundry-config-check.sh | jq .
./compile-check.sh | jq .
```

## Blocking Conditions

- `"status":"fail"` from `compile-check.sh` — project does not compile; all other phases are invalid
- `"status":"fail"` from `foundry-config-check.sh` — missing or invalid foundry configuration

## Next Phase

After all 4 skills pass, proceed to [[phase-02-security]].
