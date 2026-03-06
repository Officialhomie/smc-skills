---
description: Phase 7 Protocol Architecture — 10 skills covering multi-contract design, consensus mechanisms, state transition safety, system invariants, cross-contract dependencies, upgrade safety, governance design, and finality guarantees.
tags: [phase, protocol-architecture, formal-methods, defi]
links: [state-machines, system-invariants, governance, cross-chain-security, upgradeability, phase-06-utilities, phase-08-economic-design]
---

# Phase 7: Protocol Architecture

This phase analyzes the protocol as a whole system rather than individual contracts. It examines how contracts interact, whether [[state-machines]] are correctly modeled across contract boundaries, whether [[system-invariants]] hold under adversarial fuzzing, and whether [[governance]] and upgrade paths are safely designed.

This phase is most valuable for complex multi-contract systems (lending protocols, DEXes, yield vaults, bridges). Simple single-contract deployments may produce mostly `"status":"pass"` with limited findings.

## Skills in this Phase

- `protocol-design-analyzer.sh` — analyzes overall protocol architecture, contract interaction graphs, and design pattern compliance
- `consensus-mechanism-validator.sh` — validates consensus/quorum mechanisms in DAO and multi-party contracts
- `state-transition-safety.sh` — maps protocol [[state-machines]], validates transition guards, identifies stuck/skippable states
- `system-invariant-checker.sh` — runs Echidna invariant campaigns against protocol harnesses. See [[system-invariants]].
- `cross-contract-dependency-mapper.sh` — maps all external contract dependencies and trust assumptions
- `protocol-upgrade-safety.sh` — validates the complete upgrade process for systemic risks. See [[upgradeability]].
- `multi-contract-orchestration-validator.sh` — validates orchestration patterns across contracts (factory, registry, router)
- `economic-attack-surface-analyzer.sh` — maps economic attack vectors across the full protocol surface
- `protocol-governance-design-checker.sh` — analyzes governance architecture for centralization risks and systemic weaknesses. See [[governance]].
- `finality-guarantees-checker.sh` — validates cross-chain finality assumptions. See [[cross-chain-security]].

## Running this Phase

```bash
cd domains/smart-contracts
./protocol-design-analyzer.sh | jq .artifacts.issues
./state-transition-safety.sh | jq .artifacts.violations
./system-invariant-checker.sh | jq .artifacts.invariant_failures
./cross-contract-dependency-mapper.sh | jq .artifacts.trust_assumptions
./protocol-governance-design-checker.sh | jq .artifacts.risks
./economic-attack-surface-analyzer.sh | jq .artifacts.attack_vectors
```

## Blocking Conditions

- `"status":"fail"` from `system-invariant-checker.sh` — invariant falsified (indicates real attack path)
- `"status":"fail"` from `state-transition-safety.sh` — stuck state or skippable critical transition
- `"status":"fail"` from `protocol-upgrade-safety.sh` — upgrade process can brick the protocol or transfer control

## Next Phase

After passing Phase 7, proceed to [[phase-08-economic-design]].
