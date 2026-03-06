---
description: Access control — the enforcement of permission checks that restrict which addresses can invoke sensitive contract functions, preventing unauthorized state mutations.
tags: [security, permissions, solidity, defi]
links: [governance, reentrancy, upgradeability, erc-standards, phase-02-security, phase-04-advanced-security]
---

# Access Control

Access control determines which addresses are authorized to call sensitive functions. Without it, any external account can invoke admin operations: minting tokens, pausing protocols, withdrawing funds, or upgrading contract logic.

Solidity patterns for access control include OpenZeppelin's `Ownable` (single owner), `AccessControl` (role-based), and `Ownable2Step` (two-step ownership transfer to prevent accidental renouncement).

## Why It Matters

[[governance]] is macro-access-control: it restricts which proposals can execute which functions. A well-designed protocol delegates sensitive functions to a governance contract rather than an EOA, making access control a prerequisite for trustless operation.

[[upgradeability]] creates a critical access control surface: the proxy upgrade function must be restricted to a multisig or governance contract, not a single EOA. Unrestricted upgrade functions allow an attacker to replace contract logic entirely.

Access control does not protect against [[reentrancy]] — a permissioned function can still be called back into if it makes external calls before finalizing state. These are separate concerns.

## Skills that Check for Access Control

- `access-control-validator.sh` — validates Ownable and AccessControl patterns, detects missing modifiers
- `ownable-validator.sh` — checks for Ownable/Ownable2Step usage and owner-only function coverage
- `role-hierarchy-check.sh` — maps role relationships and detects privilege escalation paths
- `governance-safety-checker.sh` — checks that governance is the authorized caller for admin functions

```bash
./domains/smart-contracts/access-control-validator.sh | jq .artifacts.violations
./domains/smart-contracts/ownable-validator.sh | jq .artifacts.findings
./domains/smart-contracts/role-hierarchy-check.sh | jq .artifacts.roles
```

## Signals

- `"status":"fail"` from `access-control-validator.sh` — critical functions callable by any address
- `"status":"fail"` from `ownable-validator.sh` — ownership not set or renounced with functions still active
- `"status":"warn"` from `role-hierarchy-check.sh` — role hierarchy allows lateral privilege escalation

## Related Concepts

- [[governance]] — the system-level access control layer for protocol-wide decisions
- [[upgradeability]] — upgrade functions are the most critical access control surface
- [[reentrancy]] — orthogonal; permissions don't prevent reentrant calls
- [[erc-standards]] — ERC20 `approve`/`transferFrom` create access delegation patterns requiring scrutiny
