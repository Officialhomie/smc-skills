---
description: Cross-chain security — the risks specific to bridges, relayers, and cross-chain message passing protocols, including replay attacks, oracle finality, and validator collusion.
tags: [security, cross-chain, bridges, infrastructure]
links: [monitoring-operations, oracle-manipulation, governance, phase-07-protocol-architecture, phase-10-infrastructure]
---

# Cross-Chain Security

Cross-chain protocols (bridges, message passing, liquid staking across chains) introduce security risks that don't exist in single-chain systems. Bridges have been responsible for some of the largest DeFi exploits, often due to validator set compromise or message verification failures.

## Key Attack Surfaces

**Replay attacks:** A valid message on chain A is replayed on chain B or replayed multiple times. Bridges must include chain ID and nonce in all messages and validate both.

**Validator collusion:** Many bridges rely on a validator set (multisig or PoS) to attest that an event occurred on the source chain. If the validator set is compromised or colluded, they can forge withdrawal messages. The number of validators and their key security determine the attack cost.

**Finality assumptions:** Bridges must wait for source chain finality before releasing funds on the destination. If a bridge releases funds before source-chain finality (e.g. after 1 confirmation on a PoW chain), a deep reorganization can double-spend.

**[[oracle-manipulation]] in cross-chain contexts:** Cross-chain price oracles aggregate prices from multiple chains. If one chain's price is manipulable, the aggregate can be manipulated.

## [[monitoring-operations]] for Bridges

Bridges require continuous live monitoring: unusual withdrawal volumes, validator key activity, message queue depth, and bridge reserve levels should all be monitored with automated alerts. A bridge that is being drained often shows anomalous patterns minutes before the exploit completes.

## [[governance]] of Bridge Parameters

Validator set changes, fee parameters, and chain additions/removals must be gated behind [[governance]] with appropriate timelocks. Bridge admin keys are among the most valuable targets in DeFi.

## Skills that Check for Cross-Chain Security

- `cross-chain-bridge-safety.sh` — validates bridge message verification, replay protection, and finality handling
- `relayer-security-validator.sh` — validates relayer authorization and message integrity
- `finality-guarantees-checker.sh` — checks that cross-chain finality assumptions are correctly modeled

```bash
./domains/smart-contracts/cross-chain-bridge-safety.sh | jq .artifacts.vulnerabilities
./domains/smart-contracts/relayer-security-validator.sh | jq .artifacts.findings
./domains/smart-contracts/finality-guarantees-checker.sh | jq .artifacts.assumptions
```

## Signals

- `"status":"fail"` from `cross-chain-bridge-safety.sh` — missing replay protection or insufficient validator threshold
- `"status":"fail"` from `relayer-security-validator.sh` — relayer can forge or modify messages
- `"status":"warn"` — bridge releases funds before finality threshold

## Related Concepts

- [[monitoring-operations]] — bridges require continuous live monitoring; static audits are insufficient
- [[oracle-manipulation]] — cross-chain price data is a manipulation surface
- [[governance]] — bridge admin capabilities require the strongest governance controls
