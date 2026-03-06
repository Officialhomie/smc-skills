---
description: Circuit breakers — emergency mechanisms (pause, shutdown, rate limits) that allow a protocol to halt or limit operations when an exploit or abnormal condition is detected.
tags: [security, emergency, operations, defi]
links: [governance, monitoring-operations, access-control, phase-02-security, phase-05-standards, phase-09-operations]
---

# Circuit Breakers

Circuit breakers are on-chain mechanisms that halt or constrain protocol operations in response to detected threats. The primary patterns are:

- **Pause:** Halts all or specific functions. Implemented via OpenZeppelin's `Pausable` with `whenNotPaused` modifiers.
- **Emergency shutdown:** Irreversible halt that moves the protocol into wind-down mode, allowing users to withdraw but not deposit.
- **Rate limiting:** Caps how much value can leave the protocol per time window, limiting exploit drain speed.

## Authorization Model

Circuit breakers must be callable faster than normal [[governance]] allows. The standard pattern is a **guardian multisig** (2-of-3 or 3-of-5 signers) with pause authority. This removes the timelock for emergency actions while keeping the guardian accountable to governance for unpausing.

The pause function needs [[access-control]] — if anyone can pause the protocol, it becomes a denial-of-service vector. If no one can pause quickly enough, it cannot stop live exploits.

## Relationship to Monitoring

A circuit breaker without [[monitoring-operations]] is a tool with no trigger. Effective protocols pair circuit breakers with automated anomaly detection (unusual withdrawal volume, gas spikes, unexpected admin key activity) that alerts guardians or triggers automated pause.

## Skills that Check for Circuit Breakers

- `emergency-procedures-validator.sh` — validates that pause mechanisms exist and are properly access-controlled
- `pausable-check.sh` — checks for OpenZeppelin Pausable implementation and modifier coverage
- `circuit-breaker-status-checker.sh` — monitors live circuit breaker state and guardian key health
- `emergency-response-validator.sh` — validates that emergency response runbooks and contracts are in place

```bash
./domains/smart-contracts/emergency-procedures-validator.sh | jq .artifacts.findings
./domains/smart-contracts/pausable-check.sh | jq .artifacts.coverage
./domains/smart-contracts/circuit-breaker-status-checker.sh | jq .artifacts.status
```

## Signals

- `"status":"fail"` from `emergency-procedures-validator.sh` — no pause function or selfdestruct without access control
- `"status":"fail"` from `pausable-check.sh` — value-transferring functions lack `whenNotPaused`
- `"status":"warn"` from `circuit-breaker-status-checker.sh` — guardian key is a single EOA or stale

## Related Concepts

- [[governance]] — circuit breakers must act faster than governance; guardian pattern bridges the gap
- [[monitoring-operations]] — circuit breakers need triggers; monitoring provides the detection layer
- [[access-control]] — pause functions must be restricted; unrestricted pause is a DoS vector
