---
description: System invariants — properties that must hold true across all protocol states and all possible transaction sequences, used as the foundation for fuzz testing and formal verification.
tags: [security, formal-methods, testing, protocol-architecture]
links: [state-machines, economic-attacks, phase-03-testing, phase-07-protocol-architecture]
---

# System Invariants

A system invariant is a property that must always be true regardless of what sequence of operations has been performed. Examples:

- `totalBorrowed <= totalDeposited` — solvency invariant for a lending protocol
- `sum(balances) == totalSupply` — conservation invariant for an ERC20 token
- `collateralValue >= debtValue * collateralizationRatio` — safety invariant for a CDP system
- `paused == true → no withdrawals succeed` — state machine invariant

Invariants are the machine-checkable form of protocol correctness. They transform informal security requirements ("this protocol should never be insolvent") into automated tests.

## Fuzz Testing with Invariants

Foundry's invariant testing and Echidna run thousands of random transaction sequences and check that invariants hold after every step. This explores the state space far more thoroughly than unit tests, finding attack paths that manual review misses.

The `system-invariant-checker.sh` skill runs Echidna against the protocol's defined invariant harnesses. Invariant test contracts must be written and maintained alongside the protocol.

## Invariants and [[economic-attacks]]

Every successful economic attack violates an invariant: the attacker extracted more value than was valid to extract. Defining invariants that capture this — "total value withdrawn cannot exceed total value deposited + accrued interest" — allows fuzzing to discover the attack path before deployment.

## Invariants and [[state-machines]]

State machine safety properties are invariants. "The protocol cannot be in `Liquidating` state and `Paused` state simultaneously" is an invariant. State machine analysis (see [[state-machines]]) and invariant testing are complementary: state machine analysis finds structural gaps; invariant fuzzing finds reachable violations.

## Skills that Use Invariants

- `system-invariant-checker.sh` — runs Echidna invariant campaigns against protocol harnesses
- `fuzz-test-check.sh` — validates Foundry fuzz test coverage and invariant test harnesses exist
- `protocol-design-analyzer.sh` — identifies what invariants should exist based on protocol design

```bash
./domains/smart-contracts/system-invariant-checker.sh | jq .artifacts.invariant_failures
./domains/smart-contracts/fuzz-test-check.sh | jq .artifacts.coverage
```

## Signals

- `"status":"fail"` from `system-invariant-checker.sh` — invariant falsified by fuzzer (critical finding)
- `"status":"warn"` from `fuzz-test-check.sh` — no invariant test harnesses exist for value-handling contracts
- `"status":"warn"` — invariant tests exist but corpus is small (< 10,000 runs)

## Related Concepts

- [[state-machines]] — state machine safety properties are a class of invariants
- [[economic-attacks]] — all economic attacks violate some invariant; define invariants to find them
