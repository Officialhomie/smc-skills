---
description: Oracle manipulation — attacks that corrupt the price data a protocol consumes from external oracles, enabling profitable arbitrage, liquidation exploitation, or collateral inflation.
tags: [security, defi, oracles, price-manipulation]
links: [flash-loans, mev, monitoring-operations, phase-05-standards, phase-08-economic-design, phase-10-infrastructure]
---

# Oracle Manipulation

Oracles bridge on-chain contracts with off-chain data (primarily price feeds). When a protocol trusts a manipulable price source, an attacker can distort the reported price within a single transaction to extract value — inflating collateral, triggering false liquidations, or draining reserves.

The most common manipulation vector is spot price from a DEX liquidity pool: [[flash-loans]] allow an attacker to temporarily move the pool price with no capital requirement, take advantage of the inflated/deflated price in a dependent protocol, then repay the loan — all atomically.

## Manipulation Vectors

**Spot price manipulation:** Reading price directly from a DEX pool's reserves (e.g. `reserve1/reserve0`) is trivially manipulable within a transaction. Time-weighted average prices (TWAP) from Uniswap V2/V3 require sustained capital across multiple blocks — dramatically increasing attack cost.

**Stale feeds:** Chainlink feeds have a heartbeat and deviation threshold. A feed that hasn't updated in 24+ hours may report a stale price. Protocols must validate `updatedAt` against a maximum staleness threshold.

**[[mev]] interaction:** Oracle price updates can be sandwiched — a bot observes a price feed update in the mempool and frontrun/backruns transactions that depend on it.

## Skills that Check for Oracle Safety

- `oracle-integration-guard.sh` — detects spot price reads without TWAP, missing staleness checks
- `oracle-manipulation-detector.sh` — simulates price manipulation scenarios for AMM-derived feeds
- `oracle-health-monitor.sh` — monitors live feed freshness and deviation from cross-source median

```bash
./domains/smart-contracts/oracle-integration-guard.sh | jq .artifacts.violations
./domains/smart-contracts/oracle-manipulation-detector.sh | jq .artifacts.vulnerabilities
./domains/smart-contracts/oracle-health-monitor.sh | jq .artifacts.feed_status
```

## Signals

- `"status":"fail"` from `oracle-integration-guard.sh` — spot price used for collateral valuation or liquidation
- `"status":"fail"` from `oracle-manipulation-detector.sh` — confirmed profitable manipulation path exists
- `"status":"warn"` from `oracle-health-monitor.sh` — feed stale beyond acceptable threshold

## Related Concepts

- [[flash-loans]] — primary capital source for spot price manipulation; no external funding needed
- [[mev]] — oracle updates are MEV opportunities; validators can reorder around them
- [[monitoring-operations]] — oracle health requires continuous live monitoring, not just static audit
