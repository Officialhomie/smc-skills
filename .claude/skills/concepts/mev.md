---
description: MEV (Maximal Extractable Value) — profit extracted by reordering, inserting, or censoring transactions within a block, creating systematic value leakage from users to searchers.
tags: [security, defi, mev, economics]
links: [oracle-manipulation, flash-loans, tokenomics, phase-08-economic-design]
---

# MEV (Maximal Extractable Value)

MEV refers to value that block producers (validators, miners) or searchers can extract by controlling the order of transactions within a block. Common MEV strategies:

- **Sandwich attacks:** A searcher sees a large DEX swap in the mempool, inserts a buy before it (frontrun) and a sell after it (backrun), profiting from the price impact the victim's trade causes.
- **Liquidation frontrunning:** Multiple bots race to be first to liquidate an undercollateralized position. The winner extracts the liquidation bonus; the loser pays gas for nothing.
- **Arbitrage:** Exploiting price differences between DEXes, always available and generally considered benign MEV.
- **Oracle update sandwiching:** Observing a Chainlink price update in the mempool and positioning around protocols that will react to it. See [[oracle-manipulation]].

## Protocol-Level MEV Risk

Some protocols create MEV opportunities through their design:

**[[tokenomics]] and emissions:** If reward distribution is based on on-chain snapshots, searchers will game the snapshot timing.

**[[flash-loans]] and arbitrage:** Flash loan-funded arbitrage is a form of MEV extraction that benefits from atomic execution guarantees.

**Price-sensitive liquidations:** Any liquidation system where the bounty exceeds gas costs will attract MEV competition. Protocols should design liquidation incentives so the bounty is only marginally profitable to reduce searcher competition.

## Skills that Check for MEV Risk

- `mev-vulnerability-scanner.sh` — identifies protocol functions susceptible to frontrunning, sandwiching, or liquidation MEV
- `economic-attack-surface-analyzer.sh` — maps economic attack surfaces including MEV vectors
- `incentive-alignment-checker.sh` — evaluates whether incentive design inadvertently creates MEV opportunities

```bash
./domains/smart-contracts/mev-vulnerability-scanner.sh | jq .artifacts.vulnerabilities
./domains/smart-contracts/economic-attack-surface-analyzer.sh | jq .artifacts.mev_vectors
```

## Signals

- `"status":"fail"` from `mev-vulnerability-scanner.sh` — confirmed high-value MEV extraction path (e.g. unprotected oracle update sandwich)
- `"status":"warn"` — liquidation incentive structure creates significant MEV competition

## Related Concepts

- [[oracle-manipulation]] — oracle updates are prime MEV targets; searchers frontrun oracle-dependent state changes
- [[flash-loans]] — MEV bots use flash loans for capital-free atomic extraction
- [[tokenomics]] — emission and reward designs can inadvertently create MEV opportunities
