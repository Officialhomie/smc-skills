---
description: Economic attacks — exploits that manipulate DeFi protocol incentives, price mechanisms, or liquidity conditions to extract value without necessarily exploiting a code bug.
tags: [security, defi, economics, attacks]
links: [flash-loans, oracle-manipulation, liquidity-risk, system-invariants, mev, phase-08-economic-design]
---

# Economic Attacks

Economic attacks exploit the economic logic of a protocol rather than (or in addition to) code vulnerabilities. A protocol can be mathematically correct and still be economically exploitable if its incentive design creates profitable manipulation paths.

## Attack Classes

**Price manipulation exploits:** Use [[oracle-manipulation]] or direct AMM pool manipulation to create favorable conditions in a dependent protocol (e.g. inflate collateral value before borrowing, then default).

**Incentive draining:** If a protocol's reward mechanism can be continuously claimed without providing the intended service (liquidity, security, computation), an attacker will drain the rewards treasury. Common in staking and yield farming designs.

**Liquidity attacks:** Withdrawing large amounts of liquidity from a protocol creates [[liquidity-risk]] conditions that enable cascading liquidations or depegs. Often funded with [[flash-loans]].

**Governance attacks:** Accumulating governance tokens to pass self-serving proposals. See [[governance]] for protections.

## [[system-invariants]] and Economic Attacks

Every economic attack ultimately violates a system invariant: total debt cannot exceed total collateral, total withdrawals cannot exceed total deposits, reward distribution must not exceed the reward budget. Defining and checking invariants with fuzzing (Echidna, Foundry fuzzer) is the primary technical defense against economic attack discovery.

## Skills that Check for Economic Attack Surface

- `economic-attack-surface-analyzer.sh` — maps all economic attack vectors in the protocol
- `economic-exploit-detector.sh` — simulates known economic attack patterns
- `incentive-alignment-checker.sh` — evaluates whether incentive design enables draining or gaming
- `flash-loan-attack-simulator.sh` — specifically tests flash loan-funded economic attacks

```bash
./domains/smart-contracts/economic-attack-surface-analyzer.sh | jq .artifacts.attack_vectors
./domains/smart-contracts/economic-exploit-detector.sh | jq .artifacts.exploits
./domains/smart-contracts/incentive-alignment-checker.sh | jq .artifacts.misalignments
```

## Signals

- `"status":"fail"` from `economic-exploit-detector.sh` — confirmed profitable attack path with realistic capital
- `"status":"fail"` from `incentive-alignment-checker.sh` — reward mechanism drainable without providing intended service
- `"status":"warn"` from `economic-attack-surface-analyzer.sh` — large attack surface requiring manual economic modeling

## Related Concepts

- [[flash-loans]] — primary capital enabler for economic attacks; removes capital barrier
- [[oracle-manipulation]] — most economic attacks require price manipulation as a component
- [[liquidity-risk]] — liquidity concentration creates conditions that enable economic attacks
- [[system-invariants]] — economic attacks are detectable as invariant violations; fuzz to find them
- [[mev]] — MEV is economic extraction at the block level; often overlaps with economic attacks
