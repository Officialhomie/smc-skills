---
description: Phase 5 Standards & Integrations — 5 skills covering ERC compliance, oracle integration safety, external call auditing, event emission, and pausable mechanism coverage.
tags: [phase, standards, erc, oracles]
links: [erc-standards, oracle-manipulation, reentrancy, circuit-breakers, phase-04-advanced-security, phase-06-utilities]
---

# Phase 5: Standards & Integrations

This phase validates that the protocol correctly implements token standards and safely integrates with external systems. [[erc-standards]] compliance failures cause silent integration breakage. Oracle integration failures lead to [[oracle-manipulation]] exploits. External call patterns that violate [[checks-effects-interactions]] introduce [[reentrancy]] risk.

## Skills in this Phase

- `erc-compliance-validator.sh` — validates ERC20/721/1155/4626 interface compliance, detects fee-on-transfer/rebasing token handling, checks for EIP-2612 permit patterns. See [[erc-standards]].
- `oracle-integration-guard.sh` — detects spot price reads without TWAP, missing staleness validation, single-source oracle dependencies. See [[oracle-manipulation]].
- `external-call-audit.sh` — audits checks-effects-interactions violations, missing `nonReentrant` guards on external calls, unvalidated return values. See [[reentrancy]].
- `event-emission-check.sh` — validates that required ERC events (Transfer, Approval, etc.) are emitted per spec, and that state-changing functions emit indexable events.
- `pausable-check.sh` — checks that value-transferring functions implement `whenNotPaused` modifier coverage. See [[circuit-breakers]].

## Running this Phase

```bash
cd domains/smart-contracts
./erc-compliance-validator.sh | jq .artifacts.violations
./oracle-integration-guard.sh | jq .artifacts.violations
./external-call-audit.sh | jq .artifacts.findings
./event-emission-check.sh | jq .artifacts.missing_events
./pausable-check.sh | jq .artifacts.coverage
```

## Blocking Conditions

- `"status":"fail"` from `erc-compliance-validator.sh` — missing required interface functions or return value mismatch
- `"status":"fail"` from `oracle-integration-guard.sh` — spot price oracle used for collateral valuation or liquidation
- `"status":"fail"` from `external-call-audit.sh` — confirmed CEI violation (state change after external call)

## Next Phase

After passing Phase 5, proceed to [[phase-06-utilities]].
