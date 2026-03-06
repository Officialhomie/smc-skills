---
description: Tokenomics — the economic design of a protocol's token: supply schedule, emission rates, distribution, vesting, and incentive structures that determine long-term protocol health.
tags: [economics, defi, tokenomics, incentives]
links: [liquidity-risk, mev, economic-attacks, governance, phase-08-economic-design]
---

# Tokenomics

Tokenomics encompasses all aspects of a protocol token's economic design: how tokens are created, distributed, earned, and spent. Good tokenomics creates sustainable incentives that align user behavior with protocol health. Poor tokenomics creates extraction opportunities, mercenary capital, or governance attacks.

## Supply and Emission

**Inflationary emissions:** Continuously minting tokens to reward participants (liquidity providers, stakers) dilutes existing holders and creates sell pressure. The emission rate must be calibrated so that the value of incentivized activity exceeds the dilution cost.

**Vesting schedules:** Team and investor allocations with insufficient vesting create sell pressure cliffs when locks expire. Token distribution analysis should identify upcoming vesting unlocks.

**Max supply:** Hard-capped supply creates deflationary pressure as demand grows but can reduce long-term validator/sequencer incentives if protocol fees don't compensate.

## [[liquidity-risk]] and Emissions

High emissions attract mercenary liquidity providers who withdraw when rewards drop, creating liquidity cliffs. The `reward-curve-simulator.sh` models how liquidity depth changes across emission phases.

## [[mev]] and Token Design

Token mechanics create MEV: if rewards are distributed by snapshot, bots will game the snapshot. If liquidation bonuses are too high, searchers compete aggressively. See [[mev]] for protocol-level MEV risk.

## [[governance]] Token Concentration

Concentrated token ownership enables governance attacks. If a single entity holds >50% of voting power (or can acquire it via [[flash-loans]]), they can pass arbitrary proposals. Token distribution analysis should measure Gini coefficient and identify whale concentration.

## Skills that Check Tokenomics

- `tokenomics-simulator.sh` — models emission schedules, dilution, and incentive sustainability
- `token-distribution-analyzer.sh` — analyzes holder concentration, vesting schedules, whale positions
- `reward-curve-simulator.sh` — simulates APY curves and incentive sustainability across TVL ranges
- `incentive-alignment-checker.sh` — evaluates whether incentive design aligns participants with protocol health
- `fee-mechanism-validator.sh` — validates fee structure sustainability and capture mechanisms

```bash
./domains/smart-contracts/tokenomics-simulator.sh | jq .artifacts.projections
./domains/smart-contracts/token-distribution-analyzer.sh | jq .artifacts.concentration
./domains/smart-contracts/reward-curve-simulator.sh | jq .artifacts.curves
```

## Signals

- `"status":"fail"` from `tokenomics-simulator.sh` — protocol becomes insolvent within modeled time horizon
- `"status":"fail"` from `incentive-alignment-checker.sh` — primary incentive mechanism is net-negative for protocol
- `"status":"warn"` from `token-distribution-analyzer.sh` — single entity controls >33% of voting power

## Related Concepts

- [[liquidity-risk]] — emission design directly determines liquidity depth sustainability
- [[mev]] — tokenomics design creates MEV opportunities; model them proactively
- [[economic-attacks]] — concentrated token ownership enables governance and economic attacks
- [[governance]] — token distribution determines effective governance decentralization
