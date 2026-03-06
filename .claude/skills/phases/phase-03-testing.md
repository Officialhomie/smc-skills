---
description: Phase 3 Testing — 3 skills covering unit tests, fuzz testing for invariant coverage, and gas snapshots for performance baselines.
tags: [phase, testing, foundry, fuzz]
links: [system-invariants, phase-02-security, phase-04-advanced-security]
---

# Phase 3: Testing

This phase validates test quality and coverage. Unit tests confirm expected behavior; fuzz testing exercises [[system-invariants]] across a large random input space; gas snapshots establish performance baselines for regression detection.

Low test coverage does not fail the pipeline by default but produces `"status":"warn"` output that should be addressed before production deployment.

## Skills in this Phase

- `unit-test-runner.sh` — runs `forge test` and validates that all unit tests pass with coverage metrics
- `fuzz-test-check.sh` — validates that Foundry fuzz and invariant test harnesses exist for value-handling contracts and runs them. See [[system-invariants]].
- `gas-snapshot-check.sh` — runs `forge snapshot` and compares against the committed gas snapshot baseline; flags regressions

## Running this Phase

```bash
cd domains/smart-contracts
./unit-test-runner.sh | jq .artifacts.coverage
./fuzz-test-check.sh | jq .artifacts.invariant_failures
./gas-snapshot-check.sh | jq .artifacts.regressions
```

## Blocking Conditions

- `"status":"fail"` from `unit-test-runner.sh` — test suite fails; cannot proceed
- `"status":"fail"` from `fuzz-test-check.sh` — invariant falsified by fuzzer (critical: indicates a real attack path)

## Gas Snapshot Guidance

A gas regression (increase > 10%) in a hot path (e.g. `deposit`, `withdraw`, `swap`) is a `"status":"warn"`. This may indicate unintended logic changes or optimization regressions.

## Next Phase

After passing Phase 3, proceed to [[phase-04-advanced-security]].
