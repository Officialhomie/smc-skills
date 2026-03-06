---
description: Phase 4 Advanced Security — 4 skills covering upgradeability safety, storage collision detection, ownership validation, and role hierarchy analysis.
tags: [phase, security, upgradeability, proxy]
links: [upgradeability, proxy-patterns, storage-collisions, access-control, phase-03-testing, phase-05-standards]
---

# Phase 4: Advanced Security

This phase focuses on the security concerns specific to upgradeable contract architectures and ownership hierarchies. While Phase 2 covers general access control, this phase dives into the proxy-specific risks that arise when contracts can be upgraded: [[storage-collisions]], [[proxy-patterns]] misconfigurations, and [[upgradeability]] authorization gaps.

These checks are most relevant for protocols using OpenZeppelin's TransparentUpgradeableProxy, UUPS, or Beacon proxies.

## Skills in this Phase

- `upgradeability-check.sh` — detects proxy pattern type, validates EIP-1967 slot usage, checks `initialize()` guard and upgrade function access control. See [[upgradeability]].
- `storage-collision-detector.sh` — validates storage layout compatibility between proxy and implementation, checks for EIP-1967 compliance, detects cross-upgrade layout incompatibilities. See [[storage-collisions]].
- `ownable-validator.sh` — checks for Ownable/Ownable2Step usage, validates owner-only function coverage, detects renounced ownership with active admin functions. See [[access-control]].
- `role-hierarchy-check.sh` — maps AccessControl role relationships, identifies privilege escalation paths, checks DEFAULT_ADMIN_ROLE protection.

## Running this Phase

```bash
cd domains/smart-contracts
./upgradeability-check.sh | jq .artifacts.findings
./storage-collision-detector.sh | jq .artifacts.collisions
./ownable-validator.sh | jq .artifacts.findings
./role-hierarchy-check.sh | jq .artifacts.roles
```

## Proxy Pattern Identification

The `upgradeability-check.sh` skill identifies which [[proxy-patterns]] is in use. Different patterns require different checks:
- **Transparent Proxy:** Check ProxyAdmin access control
- **UUPS:** Check that new implementations include upgrade logic
- **Beacon:** Check Beacon ownership and timelock

## Blocking Conditions

- `"status":"fail"` from `upgradeability-check.sh` — unprotected `initialize()` or single-EOA upgrade authority
- `"status":"fail"` from `storage-collision-detector.sh` — confirmed slot overlap between proxy metadata and implementation state
- `"status":"fail"` from `ownable-validator.sh` — ownership renounced with active owner-only functions

## Next Phase

After passing Phase 4, proceed to [[phase-05-standards]].
