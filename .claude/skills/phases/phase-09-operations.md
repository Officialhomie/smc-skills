---
description: Phase 9 Operations & Live Monitoring — 10 skills covering exploit detection, transaction monitoring, gas anomalies, admin key activity, governance proposals, emergency response, incident handling, slashing conditions, upgrade monitoring, and circuit breaker status.
tags: [phase, operations, monitoring, security]
links: [monitoring-operations, governance, circuit-breakers, phase-08-economic-design, phase-10-infrastructure]
---

# Phase 9: Operations & Live Monitoring

This phase validates the live monitoring and incident response infrastructure. Unlike earlier phases that analyze static code, Phase 9 checks whether the protocol has the operational tooling to detect and respond to attacks in production.

A protocol that passes Phases 1–8 but has no monitoring is vulnerable to live exploits that could have been stopped within minutes. This phase ensures [[monitoring-operations]] capabilities exist and [[circuit-breakers]] are functional before production deployment.

## Skills in this Phase

- `live-exploit-detector.sh` — monitors for active exploit patterns: flash loan sequences, large unexpected withdrawals, multi-call patterns. See [[monitoring-operations]].
- `transaction-monitor.sh` — analyzes transaction patterns for anomalies: volume spikes, unusual callers, unexpected function calls
- `gas-anomaly-detector.sh` — detects unusual gas consumption patterns that indicate contract abuse or inefficiency
- `admin-key-activity-monitor.sh` — tracks multisig and admin key activity, flags unexpected signers or timing
- `governance-proposal-monitor.sh` — monitors live [[governance]] proposals for suspicious parameters, short timelocks, or high-value targets
- `emergency-response-validator.sh` — validates that emergency response runbooks, contact lists, and execution procedures are documented and tested
- `incident-response-checker.sh` — validates incident response playbooks for common exploit scenarios
- `slashing-condition-validator.sh` — validates slashing conditions and parameters for validator/staker systems
- `upgrade-governance-monitor.sh` — tracks upgrade-related [[governance]] proposals specifically, flags zero-delay upgrades
- `circuit-breaker-status-checker.sh` — monitors live circuit breaker state, guardian key health, and pause mechanism operability. See [[circuit-breakers]].

## Running this Phase

```bash
cd domains/smart-contracts
./live-exploit-detector.sh | jq .artifacts.alerts
./transaction-monitor.sh | jq .artifacts.anomalies
./admin-key-activity-monitor.sh | jq .artifacts.activity
./governance-proposal-monitor.sh | jq .artifacts.proposals
./circuit-breaker-status-checker.sh | jq .artifacts.status
./emergency-response-validator.sh | jq .artifacts.gaps
```

## Blocking Conditions

- `"status":"fail"` from `live-exploit-detector.sh` — active exploit pattern detected (immediate response required)
- `"status":"fail"` from `circuit-breaker-status-checker.sh` — circuit breaker is non-functional or guardian key is compromised
- `"status":"fail"` from `emergency-response-validator.sh` — no emergency response procedure exists for a high-severity scenario

## Next Phase

After passing Phase 9, proceed to [[phase-10-infrastructure]].
