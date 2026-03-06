---
description: State machines — the explicit modeling of protocol states and valid transitions, enabling formal reasoning about safety, liveness, and correctness of multi-step flows.
tags: [protocol-architecture, security, formal-methods, solidity]
links: [system-invariants, reentrancy, checks-effects-interactions, phase-07-protocol-architecture]
---

# State Machines

Complex DeFi protocols are state machines: they have a finite set of states (e.g. `Active`, `Paused`, `Liquidating`, `Settled`) and a set of valid transitions between them (e.g. `Active → Paused` requires admin authorization, `Liquidating → Settled` requires debt repayment).

Modeling protocol flows explicitly as state machines enables:
- Formal reasoning about reachability (can an illegal state be reached?)
- Identification of missing transition guards (can you skip a required step?)
- Detection of stuck states (can the protocol be permanently locked?)

## [[reentrancy]] and State Machines

Reentrancy is particularly dangerous in state machine protocols because it allows external code to re-enter during a state transition before it completes — leaving the protocol in an illegal intermediate state. [[checks-effects-interactions]] is the enforcement mechanism that makes transitions atomic.

## [[system-invariants]] as State Machine Properties

State machine safety properties are a class of [[system-invariants]]: invariants that hold across all states and all transitions. For example: "total debt can never exceed total collateral" is an invariant of a lending protocol's state machine. Fuzz testing with Echidna/Foundry invariant tests the entire state space systematically.

## Common Failure Patterns

**Skipped states:** A user calls `settle()` without going through `liquidating()` first because the guard only checks the end state, not the precondition that `liquidating` was reached.

**Stuck states:** A state can be entered but has no valid transition out (e.g. a governance vote that can be created but not executed because the execution function is missing or broken).

**Parallel transitions:** Two concurrent transactions attempt the same transition simultaneously; one succeeds and one operates on now-invalid state.

## Skills that Check State Machine Safety

- `state-transition-safety.sh` — maps protocol states and validates transition guards
- `system-invariant-checker.sh` — runs Echidna to verify invariants across the full state space
- `protocol-design-analyzer.sh` — analyzes overall protocol architecture for state machine completeness

```bash
./domains/smart-contracts/state-transition-safety.sh | jq .artifacts.violations
./domains/smart-contracts/system-invariant-checker.sh | jq .artifacts.invariant_failures
```

## Signals

- `"status":"fail"` from `state-transition-safety.sh` — skippable states, stuck states, or unguarded transitions
- `"status":"fail"` from `system-invariant-checker.sh` — invariant falsified by fuzzer

## Related Concepts

- [[system-invariants]] — invariants are the formal expression of state machine safety properties
- [[reentrancy]] — mid-transition re-entry corrupts state machine atomicity
- [[checks-effects-interactions]] — the pattern that enforces atomic transitions in Solidity
