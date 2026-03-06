---
description: Monitoring and operations — the live detection, alerting, and response infrastructure that detects exploits and anomalies in production DeFi protocols.
tags: [operations, monitoring, security, infrastructure]
links: [circuit-breakers, governance, cross-chain-security, oracle-manipulation, phase-09-operations, phase-10-infrastructure]
---

# Monitoring and Operations

Static audits and pre-deployment testing cannot catch all exploits — live monitoring provides the last line of defense. Effective monitoring detects anomalous patterns within minutes, giving protocol guardians time to invoke [[circuit-breakers]] before losses become catastrophic.

## What to Monitor

**On-chain metrics:**
- Unusual withdrawal volumes (spike above 3σ of rolling average)
- Gas usage anomalies (unexpectedly high gas in a specific function)
- Admin key activity (multisig transactions, timelock queuing)
- [[governance]] proposal creation (especially proposals with short timelocks)
- Balance changes in protocol reserves

**Oracle health:**
- Feed freshness (`updatedAt` vs. current timestamp)
- Price deviation from cross-source median
- Circuit breaker trip status on oracle aggregators
See [[oracle-manipulation]] for oracle-specific risks.

**Bridge and cross-chain:**
- Message queue depth and processing delays
- Validator key activity
- Reserve level on both sides of the bridge
See [[cross-chain-security]] for bridge-specific monitoring.

## [[circuit-breakers]] Integration

Monitoring is the trigger for circuit breakers. Automated monitoring can directly invoke pause functions if thresholds are exceeded (e.g. withdrawal volume > 20% of TVL in one block). Human-in-the-loop monitoring pages guardians for manual assessment and action.

## Skills that Check Monitoring Infrastructure

- `live-exploit-detector.sh` — monitors for active exploit patterns in real-time
- `transaction-monitor.sh` — analyzes transaction patterns for anomalies
- `gas-anomaly-detector.sh` — detects unusual gas consumption indicating contract abuse
- `admin-key-activity-monitor.sh` — tracks multisig and admin key activity
- `oracle-health-monitor.sh` — monitors oracle feed freshness and deviation

```bash
./domains/smart-contracts/live-exploit-detector.sh | jq .artifacts.alerts
./domains/smart-contracts/transaction-monitor.sh | jq .artifacts.anomalies
./domains/smart-contracts/oracle-health-monitor.sh | jq .artifacts.feed_status
./domains/smart-contracts/admin-key-activity-monitor.sh | jq .artifacts.activity
```

## Signals

- `"status":"fail"` from `live-exploit-detector.sh` — active exploit pattern detected (immediate response required)
- `"status":"warn"` from `gas-anomaly-detector.sh` — unusual gas pattern in value-handling function
- `"status":"warn"` from `admin-key-activity-monitor.sh` — unexpected admin transaction from unfamiliar address

## Related Concepts

- [[circuit-breakers]] — monitoring triggers circuit breakers; they are the response layer
- [[governance]] — governance proposals require monitoring; malicious proposals need early detection
- [[cross-chain-security]] — bridges require continuous monitoring more than static protocols
- [[oracle-manipulation]] — oracle feed health is a primary monitoring target
