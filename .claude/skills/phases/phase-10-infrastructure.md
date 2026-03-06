---
description: Phase 10 Infrastructure & Off-Chain — 10 skills covering oracle health, indexer validation, automation bots, cross-chain bridge safety, relayer security, subgraph integrity, RPC endpoints, IPFS pinning, event listeners, and off-chain dependencies.
tags: [phase, infrastructure, off-chain, bridges]
links: [oracle-manipulation, cross-chain-security, monitoring-operations, phase-09-operations]
---

# Phase 10: Infrastructure & Off-Chain

This final phase validates the off-chain infrastructure that DeFi protocols depend on: oracle feeds, indexers, automation bots, bridges, relayers, and RPC endpoints. Failures here don't show up in on-chain code audits but can take down a protocol or enable [[oracle-manipulation]] exploits.

Many of these checks require live connections to external services. They are designed to run continuously in production environments, not just at deployment time.

## Skills in this Phase

- `oracle-health-monitor.sh` — monitors Chainlink and custom oracle feed freshness, deviation from cross-source median, circuit breaker status. See [[oracle-manipulation]].
- `indexer-validation.sh` — validates that The Graph or custom indexer subgraphs are synchronized and not serving stale data
- `automation-bot-checker.sh` — validates Chainlink Keepers or custom automation bots for uptime and proper authorization
- `cross-chain-bridge-safety.sh` — validates bridge message verification, replay protection, finality requirements, and validator set health. See [[cross-chain-security]].
- `relayer-security-validator.sh` — validates relayer authorization models and message integrity for meta-transaction and cross-chain systems
- `subgraph-integrity-checker.sh` — validates that subgraph entities correctly reflect on-chain state, detects sync lag
- `rpc-endpoint-validator.sh` — tests RPC endpoint availability, response latency, and data consistency across providers
- `ipfs-pinning-checker.sh` — validates that protocol metadata (ABI, documentation, NFT assets) is persistently pinned
- `event-listener-validator.sh` — validates that event listeners are correctly filtering and processing on-chain events
- `off-chain-dependency-auditor.sh` — audits all off-chain service dependencies for single points of failure and vendor risk

## Running this Phase

```bash
cd domains/smart-contracts
./oracle-health-monitor.sh | jq .artifacts.feed_status
./cross-chain-bridge-safety.sh | jq .artifacts.vulnerabilities
./relayer-security-validator.sh | jq .artifacts.findings
./rpc-endpoint-validator.sh | jq .artifacts.availability
./off-chain-dependency-auditor.sh | jq .artifacts.single_points_of_failure
```

## Blocking Conditions

- `"status":"fail"` from `cross-chain-bridge-safety.sh` — missing replay protection or insufficient validator threshold
- `"status":"fail"` from `oracle-health-monitor.sh` — primary price feed stale or returning zero
- `"status":"fail"` from `relayer-security-validator.sh` — relayer can forge or modify messages

## [[monitoring-operations]] for Infrastructure

Infrastructure health requires ongoing [[monitoring-operations]]. These checks should run on a scheduled basis (every 5–60 minutes depending on the check) in production, not only at deployment. Failures trigger [[circuit-breakers]] or guardian alerts.

## End of Pipeline

Phase 10 is the final phase. A clean run through all 10 phases (79 skills) indicates the protocol is ready for audit or production deployment with appropriate caveats from `"status":"warn"` findings.
