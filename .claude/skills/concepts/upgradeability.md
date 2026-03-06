---
description: Upgradeability — the ability to change a deployed contract's logic via proxy patterns, introducing storage layout constraints, initialization risks, and governance requirements.
tags: [security, upgradeability, proxy, solidity]
links: [proxy-patterns, storage-collisions, governance, access-control, phase-04-advanced-security, phase-07-protocol-architecture]
---

# Upgradeability

Upgradeable contracts separate storage (proxy) from logic (implementation). The proxy stores all state and delegates calls to the implementation. Replacing the implementation address updates protocol behavior without redeploying storage.

This flexibility comes with significant risks:

## Storage Layout Constraints

The implementation contract's storage layout must be append-only compatible with the proxy. Adding a variable in the middle of existing state variables shifts slot assignments, causing [[storage-collisions]] where new variables overwrite old ones. OpenZeppelin's `@openzeppelin/upgrades-plugins` enforces layout compatibility automatically.

## Initialization

Upgradeable contracts cannot use constructors — they must use `initialize()` functions with `initializer` modifiers. An uninitialized proxy can be initialized by an attacker, granting them ownership or admin roles.

## Governance Requirements

The upgrade function — typically `upgradeTo(address)` — is the most powerful operation in an upgradeable protocol. It must be gated behind [[governance]] with the longest timelocks. A single-EOA upgrade key means one compromised private key can replace all protocol logic. See [[access-control]] for the access model and [[governance]] for timelock requirements.

## Proxy Patterns

Different [[proxy-patterns]] (Transparent, UUPS, Beacon) have different security tradeoffs. UUPS moves upgrade logic to the implementation, saving gas but requiring careful access control. Transparent proxies have selector clash protections. Beacon proxies allow upgrading many contracts at once.

## Skills that Check for Upgradeability

- `upgradeability-check.sh` — detects proxy pattern type, validates initialize guards, checks upgrade access control
- `storage-collision-detector.sh` — validates storage layout compatibility across upgrades
- `protocol-upgrade-safety.sh` — analyzes the full upgrade process for systemic risks

```bash
./domains/smart-contracts/upgradeability-check.sh | jq .artifacts.findings
./domains/smart-contracts/storage-collision-detector.sh | jq .artifacts.collisions
./domains/smart-contracts/protocol-upgrade-safety.sh | jq .artifacts.risks
```

## Signals

- `"status":"fail"` from `upgradeability-check.sh` — unprotected `initialize()` or single-EOA upgrade key
- `"status":"fail"` from `storage-collision-detector.sh` — confirmed storage layout incompatibility
- `"status":"warn"` — UUPS implementation with owner role in storage slot 0

## Related Concepts

- [[proxy-patterns]] — the specific implementation patterns (Transparent, UUPS, Beacon) and their tradeoffs
- [[storage-collisions]] — the concrete failure mode when storage layouts are incompatible
- [[governance]] — upgrade authority requires the strongest governance controls
- [[access-control]] — the upgrade function must be restricted to governance or multisig
