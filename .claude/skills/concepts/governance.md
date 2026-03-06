---
description: Governance — the system of smart contracts and processes that control protocol-level decisions, including parameter changes, upgrades, and treasury management.
tags: [governance, security, defi, protocol]
links: [access-control, circuit-breakers, upgradeability, flash-loans, phase-02-security, phase-07-protocol-architecture, phase-09-operations]
---

# Governance

Governance controls who can change protocol parameters, upgrade contract logic, and spend treasury funds. It sits at the top of the [[access-control]] hierarchy: rather than granting admin rights to an EOA, a well-designed protocol routes all sensitive operations through a governance contract with timelocks and voting.

## Design Properties

**Timelock:** A mandatory delay between a proposal passing and its execution. This gives users time to exit before changes take effect and prevents flash governance attacks. Standard minimum is 48 hours; high-stakes protocols use 7–14 days.

**Quorum and voting threshold:** Sufficient participation prevents a small token holder from passing arbitrary proposals. If governance tokens are concentrated, these thresholds may be ineffective.

**[[flash-loans]] and governance:** If voting power snapshots are taken at the same block as the vote, flash-loan-borrowed tokens can be used to vote. Protocols must snapshot at a prior block (`block.number - 1` or a checkpoint mechanism).

## Emergency Governance

[[circuit-breakers]] (pause, emergency shutdown) should be executable faster than normal governance allows. Most protocols implement a guardian multisig with pause authority that can act immediately while full governance handles recovery. See [[circuit-breakers]] for the pattern.

## [[upgradeability]] Governance

Upgrade authority — the ability to change proxy implementation addresses — is the most powerful governance capability. It must be gated behind the longest timelocks and highest thresholds, because a malicious upgrade can replace all protocol logic.

## Skills that Check for Governance Safety

- `governance-safety-checker.sh` — validates timelock existence, quorum settings, centralization risk
- `governance-proposal-monitor.sh` — monitors live proposals for suspicious parameters or short timelocks
- `upgrade-governance-monitor.sh` — tracks upgrade-related governance proposals specifically
- `protocol-governance-design-checker.sh` — analyzes governance architecture for systemic weaknesses

```bash
./domains/smart-contracts/governance-safety-checker.sh | jq .artifacts.findings
./domains/smart-contracts/protocol-governance-design-checker.sh | jq .artifacts.risks
```

## Signals

- `"status":"fail"` from `governance-safety-checker.sh` — no timelock, or admin is a single EOA
- `"status":"warn"` — timelock shorter than 48 hours for parameter changes
- `"status":"fail"` from `upgrade-governance-monitor.sh` — upgrade proposed with zero or minimal delay

## Related Concepts

- [[access-control]] — governance is the macro-layer; individual functions still need modifiers
- [[circuit-breakers]] — emergency controls that must operate faster than standard governance
- [[upgradeability]] — upgrade functions are the most powerful governance capability
- [[flash-loans]] — can enable governance attacks if voting snapshots are not properly delayed
