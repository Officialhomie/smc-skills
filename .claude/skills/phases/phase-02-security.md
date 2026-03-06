---
description: Phase 2 Security Analysis — 7 skills covering threat modeling, secrets scanning, static analysis, reentrancy, access control, governance, and emergency procedures.
tags: [phase, security, smart-contracts]
links: [reentrancy, access-control, threat-modeling, governance, circuit-breakers, phase-01-foundation, phase-03-testing]
---

# Phase 2: Security Analysis

This phase is the most critical security gate in the pipeline. It should be run after [[phase-01-foundation]] confirms the project compiles. The 7 skills here catch the vulnerabilities most commonly exploited in production: control flow attacks ([[reentrancy]]), broken permission systems ([[access-control]]), missing emergency mechanisms ([[circuit-breakers]]), and systemic design gaps identified by [[threat-modeling]].

A `"status":"fail"` from any skill in this phase is a deployment blocker.

## Skills in this Phase

- `threat-model-generator.sh` — generates an attack surface matrix across contracts. See [[threat-modeling]].
- `secrets-safety-validator.sh` — scans for hardcoded private keys, API credentials, and exposed mnemonics.
- `slither-analysis.sh` — runs Slither static analysis, outputs `build/slither.json` with all detectors.
- `reentrancy-pattern-check.sh` — detects `.call{value:}` and low-level call patterns without `nonReentrant`. See [[reentrancy]].
- `access-control-validator.sh` — validates Ownable and AccessControl patterns, detects missing modifiers on sensitive functions. See [[access-control]].
- `governance-safety-checker.sh` — checks timelock existence, quorum settings, centralization risk, and insider threat surface. See [[governance]].
- `emergency-procedures-validator.sh` — validates that pause mechanisms and circuit breakers exist and are properly access-controlled. See [[circuit-breakers]].

## Running this Phase

```bash
cd domains/smart-contracts

# Run individually
./threat-model-generator.sh | jq .artifacts.attack_surface
./secrets-safety-validator.sh | jq .artifacts.findings
./slither-analysis.sh | jq .artifacts.issues
./reentrancy-pattern-check.sh | jq .artifacts.matches
./access-control-validator.sh | jq .artifacts.violations
./governance-safety-checker.sh | jq .artifacts.findings
./emergency-procedures-validator.sh | jq .artifacts.findings
```

## Critical Findings that Block Deployment

- `"status":"fail"` from `access-control-validator.sh` — critical functions callable by any address
- `"status":"fail"` from `reentrancy-pattern-check.sh` — active reentrancy vectors confirmed
- `"status":"fail"` from `emergency-procedures-validator.sh` — no pause function or `selfdestruct` without access control
- `"status":"fail"` from `secrets-safety-validator.sh` — credentials exposed in code or repo history

## Next Phase

After passing Phase 2, proceed to [[phase-03-testing]].
