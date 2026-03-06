---
description: Storage collisions — when two contracts sharing storage (via proxy delegation) write to the same storage slot with different type interpretations, corrupting state.
tags: [security, upgradeability, proxy, solidity, storage]
links: [proxy-patterns, upgradeability, phase-04-advanced-security]
---

# Storage Collisions

In Solidity, state variables are assigned to storage slots sequentially starting at slot 0. When a proxy delegates calls to an implementation, both contracts share the same storage. If the proxy stores data (e.g. the implementation address) in slot 0, and the implementation also declares a state variable at slot 0, writes to either variable overwrite the same storage location.

## Types of Collisions

**Proxy-Implementation collision:** The proxy contract needs to store its own metadata (implementation address, admin address). If these are stored in low-numbered slots (0, 1, 2...), they overlap with the implementation's first state variables. EIP-1967 solves this by storing proxy metadata in pseudo-random high slots derived from `keccak256("eip1967.proxy.implementation") - 1`.

**Upgrade-induced layout collision:** When an [[upgradeability]] contract is upgraded, the new implementation must not insert new variables before existing ones. Inserting a variable at position 2 in a 5-variable layout shifts variables 3–5 to new slots, where they read as zero (or worse, as other variables' data).

**Inheritance order collision:** Solidity allocates storage by linearizing inheritance (C3 linearization). Changing the order of base contracts in a child contract changes which parent's variables land in which slots.

## Detection

OpenZeppelin's `@openzeppelin/upgrades-plugins` (Hardhat/Foundry plugin) detects layout incompatibilities at upgrade time. The `storage-collision-detector.sh` skill replicates this analysis.

## Skills that Check for Storage Collisions

- `storage-collision-detector.sh` — validates storage layout compatibility between proxy and implementation, and across upgrade versions
- `upgradeability-check.sh` — checks for EIP-1967 slot usage in proxy storage

```bash
./domains/smart-contracts/storage-collision-detector.sh | jq .artifacts.collisions
./domains/smart-contracts/upgradeability-check.sh | jq .artifacts.eip1967_compliance
```

## Signals

- `"status":"fail"` from `storage-collision-detector.sh` — confirmed slot overlap between proxy metadata and implementation state
- `"status":"warn"` — storage layout change detected between implementation versions (requires manual review)

## Related Concepts

- [[proxy-patterns]] — the architectural pattern that creates storage sharing between proxy and implementation
- [[upgradeability]] — the broader concern; storage collisions are the most dangerous technical failure mode
