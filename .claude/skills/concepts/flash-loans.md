---
description: Flash loans — uncollateralized loans repaid within a single transaction, enabling capital-free attacks on protocols with price-sensitive or state-sensitive logic.
tags: [security, defi, attacks, flash-loans]
links: [reentrancy, oracle-manipulation, economic-attacks, liquidity-risk, phase-08-economic-design]
---

# Flash Loans

Flash loans allow borrowing any amount of tokens from a lending pool with no collateral, provided the full loan plus fee is repaid within the same transaction. If repayment fails, the entire transaction reverts as if the loan never happened.

Legitimate uses include arbitrage, collateral swaps, and self-liquidation. As an attack vector, flash loans eliminate the capital barrier for exploits: an attacker with no funds can temporarily control tens of millions in liquidity.

## Attack Patterns

**Price manipulation:** Borrow a large amount of token A, dump it into a DEX pool to crash the price of A (or inflate token B), exploit a protocol that reads that manipulated price, then repay the loan. This is the primary driver of [[oracle-manipulation]] attacks — see that node for defense patterns.

**Governance attacks:** If a governance token's voting power is calculated at snapshot time and a protocol allows flash-loan-borrowed tokens to vote, an attacker can acquire majority voting power in a single transaction. Protocols must snapshot voting power at a prior block.

**Reentrancy amplification:** Flash loans combined with [[reentrancy]] mean an attacker can repeatedly drain a contract's funds across many reentrant calls, all funded by the initial flash loan, all within one transaction.

## Skills that Check for Flash Loan Risk

- `flash-loan-attack-simulator.sh` — models flash loan attack paths against price-sensitive functions
- `oracle-manipulation-detector.sh` — evaluates flash loan + spot price combinations specifically
- `governance-safety-checker.sh` — checks for flash-loan-votable governance token configurations

```bash
./domains/smart-contracts/flash-loan-attack-simulator.sh | jq .artifacts.attack_paths
./domains/smart-contracts/oracle-manipulation-detector.sh | jq .artifacts.vulnerabilities
```

## Signals

- `"status":"fail"` from `flash-loan-attack-simulator.sh` — profitable flash loan attack path confirmed
- `"status":"warn"` — price-sensitive function detected without flash loan resistance (TWAP, multi-block)

## Related Concepts

- [[reentrancy]] — flash loans fund reentrant attacks; combined they are the most damaging pattern
- [[oracle-manipulation]] — flash loans are the capital source for spot price manipulation
- [[economic-attacks]] — flash loans are the most common enabler of economic exploits
- [[liquidity-risk]] — high concentrated liquidity in pools increases flash loan attack surface
