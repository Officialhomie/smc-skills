---
description: Liquidity risk — the danger that insufficient liquidity depth causes slippage, failed liquidations, depegs, or cascading insolvency in DeFi protocols.
tags: [defi, economics, liquidity, risk]
links: [economic-attacks, flash-loans, tokenomics, oracle-manipulation, phase-08-economic-design]
---

# Liquidity Risk

Liquidity risk arises when a protocol cannot function correctly because there is insufficient liquidity to execute required operations at fair prices. It manifests in several DeFi-specific ways:

## Liquidation Failure

Lending protocols depend on liquidators being able to sell seized collateral at near-market price. If the collateral asset has low liquidity (thin order books, small AMM pools), a large liquidation will cause severe slippage — the protocol may not recover enough value to cover the debt, creating bad debt that socializes losses to depositors.

## Depeg Risk

Stablecoins and pegged assets (liquid staking tokens, synthetic assets) maintain their peg through arbitrage. If liquidity in the primary peg-maintaining pools drops below the level needed to make arbitrage profitable, the asset depegs. Large depegs trigger liquidation cascades in protocols that treat the asset as equivalent to its peg.

## [[flash-loans]] and Liquidity

Flash loan-funded liquidity removal is an attack vector: borrowing a large amount and withdrawing liquidity from a pool temporarily creates the low-liquidity conditions described above, enabling [[oracle-manipulation]] or forced bad liquidations. The loan is repaid after extracting value from the protocol under duress.

## [[tokenomics]] Interaction

Token emission schedules affect liquidity depth. High emissions incentivize liquidity provision but also mercenary capital that exits when rewards drop, creating sudden liquidity cliffs. See [[tokenomics]] for emission design considerations.

## Skills that Check for Liquidity Risk

- `liquidity-risk-analyzer.sh` — evaluates protocol dependencies on external liquidity, models thin-market scenarios
- `token-distribution-analyzer.sh` — identifies concentrated token holders who could drain liquidity
- `economic-attack-surface-analyzer.sh` — maps liquidity-dependent attack surfaces

```bash
./domains/smart-contracts/liquidity-risk-analyzer.sh | jq .artifacts.risks
./domains/smart-contracts/token-distribution-analyzer.sh | jq .artifacts.concentration
```

## Signals

- `"status":"fail"` from `liquidity-risk-analyzer.sh` — protocol becomes insolvent under realistic thin-market scenario
- `"status":"warn"` — collateral asset has insufficient DEX liquidity relative to protocol TVL

## Related Concepts

- [[economic-attacks]] — low liquidity is the enabling condition for many economic attacks
- [[flash-loans]] — can temporarily manufacture low-liquidity conditions
- [[tokenomics]] — emission design determines long-term liquidity sustainability
- [[oracle-manipulation]] — thin liquidity makes spot price oracles trivially manipulable
