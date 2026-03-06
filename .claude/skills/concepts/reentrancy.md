---
description: Reentrancy — a control flow exploit where an external call returns to the calling contract before state is finalized, enabling repeated withdrawals or state corruption.
tags: [security, vulnerability, defi, solidity]
links: [checks-effects-interactions, flash-loans, access-control, state-machines, phase-02-security, phase-05-standards]
---

# Reentrancy

Reentrancy occurs when a contract makes an external call to an untrusted address before finishing its own state updates. The external recipient calls back into the original contract and finds stale state — enabling repeated withdrawals, corrupted balances, or bypassed access checks.

The canonical defense is the [[checks-effects-interactions]] pattern: update all internal state before any external call. A second layer of defense is OpenZeppelin's `ReentrancyGuard` (`nonReentrant` modifier).

## Why It Matters

[[flash-loans]] amplify reentrancy: an attacker borrows unlimited capital, triggers a reentrant call, and repays in a single transaction — no external funding required. This makes reentrancy critical in any contract that holds or transfers value.

[[access-control]] does not prevent reentrancy. A permissioned function can still be reentrant if it calls out to an untrusted contract before finalizing state. These are orthogonal concerns.

Reentrancy corrupts [[state-machines]]: a multi-step protocol whose state transitions are interruptible mid-flight via reentrancy will exhibit undefined behavior.

## Skills that Check for Reentrancy

- `reentrancy-pattern-check.sh` — scans for `call.value` and `.call{value:}` patterns without `nonReentrant`
- `external-call-audit.sh` — audits checks-effects-interactions violations and missing guards
- `flash-loan-attack-simulator.sh` — checks reentrancy guard presence on flash loan entry points

```bash
./domains/smart-contracts/reentrancy-pattern-check.sh | jq .artifacts.matches
./domains/smart-contracts/external-call-audit.sh | jq .artifacts.findings
./domains/smart-contracts/flash-loan-attack-simulator.sh | jq .artifacts.vulnerabilities
```

## Signals

- `"status":"fail"` from `external-call-audit.sh` — confirmed CEI violation (state change after external call)
- `"status":"warn"` from `reentrancy-pattern-check.sh` — low-level call patterns exist, manual review required
- `"status":"fail"` from `flash-loan-attack-simulator.sh` — flash loan entry point lacks `nonReentrant`

## Related Concepts

- [[checks-effects-interactions]] — the structural defense; always update state before calling out
- [[flash-loans]] — atomic amplification; unlimited capital in one transaction
- [[access-control]] — orthogonal concern; permissioned functions can still be reentrant
- [[state-machines]] — reentrancy corrupts multi-step protocol transitions
