---
description: Checks-Effects-Interactions (CEI) — the Solidity pattern that prevents reentrancy by requiring all state changes to complete before any external call is made.
tags: [security, pattern, solidity, reentrancy-defense]
links: [reentrancy, state-machines, phase-02-security, phase-05-standards]
---

# Checks-Effects-Interactions

CEI is the primary structural defense against [[reentrancy]]. The pattern mandates a strict ordering within every function:

1. **Checks** — validate all preconditions (`require`, `revert`)
2. **Effects** — update all state variables
3. **Interactions** — make external calls (transfers, calls to other contracts)

If state is updated after an external call, a malicious callee can re-enter the function and observe state that does not reflect the first invocation.

## When CEI Is Not Enough

CEI prevents the most common reentrancy patterns but fails for cross-function reentrancy: two functions A and B share state, and re-entering B from within A's external call violates the state assumptions even if each function individually follows CEI.

For cross-function reentrancy, OpenZeppelin's `ReentrancyGuard` (`nonReentrant` modifier) provides a mutex that prevents any re-entry into guarded functions regardless of call path.

## Relationship to State Machines

In [[state-machines]], CEI is the enforcement mechanism that ensures a state transition is atomic. Violating CEI means an external observer can see the contract in a transitional state — which in a state machine is an illegal state.

## Skills that Check for CEI

- `external-call-audit.sh` — detects state changes after external calls (confirmed CEI violations)
- `reentrancy-pattern-check.sh` — detects low-level call patterns that commonly coincide with CEI violations
- `static-analysis.sh` — Slither's `reentrancy` detectors report CEI violations

```bash
./domains/smart-contracts/external-call-audit.sh | jq .artifacts.findings
./domains/smart-contracts/reentrancy-pattern-check.sh | jq .artifacts.matches
```

## Signals

- `"status":"fail"` from `external-call-audit.sh` — confirmed state-after-call (CEI violation)
- `"status":"warn"` from `reentrancy-pattern-check.sh` — external call pattern without nonReentrant guard

## Related Concepts

- [[reentrancy]] — CEI is the canonical defense against this attack class
- [[state-machines]] — CEI ensures atomic state transitions in multi-step protocols
