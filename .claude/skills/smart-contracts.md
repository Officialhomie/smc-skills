---
description: Smart Contracts domain — 79 Solidity/Foundry validation skills across 10 phases from project structure through live infrastructure monitoring.
tags: [domain, smart-contracts, foundry, solidity]
links: [phase-01-foundation, phase-02-security, phase-03-testing, phase-04-advanced-security, phase-05-standards, phase-06-utilities, phase-07-protocol-architecture, phase-08-economic-design, phase-09-operations, phase-10-infrastructure]
---

# Smart Contracts Domain

This domain validates Solidity protocols through a 10-phase pipeline of 79 skills. **Phases run in strict order**: a `"status":"fail"` in any phase exits the pipeline immediately via `ci-orchestrator.sh`. Running Phase 8 economic analysis on a project that doesn't compile (Phase 1 failure) produces meaningless results.

## The 10-Phase Pipeline

**[[phase-01-foundation]] (4 skills):** Structural prerequisites. Project structure, Solidity formatting, Foundry config, compilation. Nothing else runs without a clean compile.

**[[phase-02-security]] (7 skills):** The most critical phase. Identifies [[reentrancy]], broken [[access-control]], missing [[governance]] controls, and [[circuit-breakers]]. Catches the vulnerabilities most commonly exploited in production. [[threat-modeling]] produces the attack surface matrix that guides all subsequent analysis.

**[[phase-03-testing]] (3 skills):** Unit tests, fuzz coverage, and gas snapshots. Fuzz testing exercises [[system-invariants]] automatically across large random input spaces. An invariant failure here is a critical finding.

**[[phase-04-advanced-security]] (4 skills):** [[upgradeability]], [[proxy-patterns]], [[storage-collisions]], and ownership hierarchy. Directly relevant for protocols using OpenZeppelin proxy infrastructure.

**[[phase-05-standards]] (5 skills):** [[erc-standards]] compliance, [[oracle-manipulation]] guards, external call safety (connects back to [[reentrancy]]), event emission, and [[circuit-breakers]] coverage.

**[[phase-06-utilities]] (8 skills):** Dependency auditing, formatting, additional static analysis, GitHub CI configuration, docs standard, integration tests, and deployment script validation.

**[[phase-07-protocol-architecture]] (10 skills):** Multi-contract systems, [[state-machines]], [[system-invariants]] via Echidna, [[governance]] design, cross-contract dependencies, upgrade safety, and [[cross-chain-security]] finality.

**[[phase-08-economic-design]] (10 skills):** [[flash-loans]], [[mev]], [[oracle-manipulation]], [[tokenomics]], [[liquidity-risk]], [[economic-attacks]]. Fills the gap that code-only audits miss: economic exploitability.

**[[phase-09-operations]] (10 skills):** Live [[monitoring-operations]], [[circuit-breakers]] status, [[governance]] proposal monitoring, incident response, and admin key activity. Validates that the protocol can detect and respond to attacks in production.

**[[phase-10-infrastructure]] (10 skills):** [[oracle-manipulation]] feed health, bridge and relayer safety ([[cross-chain-security]]), indexer integrity, RPC endpoints, IPFS pinning, automation bots, and off-chain dependency mapping. All require live connections.

## Running the Full Pipeline

```bash
# From repo root
./domains/smart-contracts/ci-orchestrator.sh

# Single phase (example: security)
cd domains/smart-contracts
for skill in threat-model-generator secrets-safety-validator slither-analysis \
             reentrancy-pattern-check access-control-validator \
             governance-safety-checker emergency-procedures-validator; do
  ./$skill.sh | jq '{skill: .skill, status: .status, summary: .summary}'
done
```

## Reference Documentation

The canonical reference is at repo root:
- `DOMAINS_CATALOG.md` — complete skill-to-phase mapping with descriptions
- `SKILLS_CATALOG.md` — detailed parameters, status codes, and example outputs per skill
- `domains/smart-contracts/README.md` — domain-specific setup and usage guide
