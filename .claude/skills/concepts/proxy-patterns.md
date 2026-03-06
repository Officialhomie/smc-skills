---
description: Proxy patterns — the Transparent, UUPS, and Beacon proxy architectures used for contract upgradeability, each with distinct security tradeoffs.
tags: [upgradeability, proxy, solidity, patterns]
links: [upgradeability, storage-collisions, access-control, phase-04-advanced-security]
---

# Proxy Patterns

Proxy patterns delegate calls from a persistent storage contract (proxy) to a swappable logic contract (implementation). Three patterns dominate production usage:

## Transparent Proxy (OpenZeppelin)

The proxy contract intercepts calls and routes admin calls (upgrade, admin management) to itself, and all other calls to the implementation. The admin address cannot call implementation functions directly — this prevents selector clash attacks where a function in the implementation shares a 4-byte selector with a proxy admin function.

**Risk:** Higher gas overhead. The proxy must check every call against the admin address.

## UUPS (Universal Upgradeable Proxy Standard, EIP-1822)

Upgrade logic lives in the implementation contract, not the proxy. The proxy is minimal (just `delegatecall`). This saves gas but moves security responsibility to the implementation: if the implementation doesn't include upgrade logic in the next version, the proxy becomes permanently stuck.

**Risk:** Forgetting to include upgrade functionality in a new implementation permanently bricks upgradeability. [[access-control]] on the `upgradeTo` function is critical — it's in the implementation, not the proxy.

## Beacon Proxy

Multiple proxy contracts all point to a single Beacon contract that holds the implementation address. Upgrading the Beacon upgrades all proxies simultaneously — ideal for factory-deployed contract instances.

**Risk:** The Beacon is a single point of failure. Compromising Beacon ownership upgrades every instance at once. [[governance]] of Beacon ownership requires the strongest controls.

## [[storage-collisions]] in Proxies

All proxy patterns share the storage collision risk: if the proxy's own storage slots overlap with the implementation's state variables, writes to implementation state overwrite proxy metadata (like the implementation address). EIP-1967 standardizes proxy storage slots to avoid this.

## Skills that Check for Proxy Patterns

- `upgradeability-check.sh` — identifies which proxy pattern is in use, validates EIP-1967 slots
- `storage-collision-detector.sh` — verifies no overlap between proxy and implementation storage

```bash
./domains/smart-contracts/upgradeability-check.sh | jq .artifacts.proxy_type
./domains/smart-contracts/storage-collision-detector.sh | jq .artifacts.collisions
```

## Related Concepts

- [[upgradeability]] — the broader concern; proxy patterns are the mechanism
- [[storage-collisions]] — the primary technical risk in all proxy implementations
- [[access-control]] — upgrade functions in UUPS must be access-controlled in the implementation
