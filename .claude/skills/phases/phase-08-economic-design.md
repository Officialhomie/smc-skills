---
description: Phase 8 Economic Design & Simulation — 10 skills covering tokenomics modeling, liquidity risk, oracle manipulation, flash loan attacks, MEV, incentive alignment, fee mechanisms, reward curves, token distribution, and economic exploit detection.
tags: [phase, economics, defi, tokenomics, mev]
links: [flash-loans, mev, oracle-manipulation, tokenomics, liquidity-risk, economic-attacks, phase-07-protocol-architecture, phase-09-operations]
---

# Phase 8: Economic Design & Simulation

This phase analyzes the protocol's economic security: whether the incentive design is sustainable, whether [[flash-loans]] can be used to manipulate price-sensitive functions, whether [[mev]] opportunities are inadvertently created, and whether [[oracle-manipulation]] paths exist.

Economic vulnerabilities are often as damaging as code vulnerabilities but are invisible to code-only audits. This phase fills that gap.

## Skills in this Phase

- `tokenomics-simulator.sh` — models emission schedules, dilution effects, and incentive sustainability. See [[tokenomics]].
- `liquidity-risk-analyzer.sh` — evaluates protocol dependencies on external liquidity, models thin-market scenarios. See [[liquidity-risk]].
- `oracle-manipulation-detector.sh` — simulates price manipulation scenarios for AMM-derived and Chainlink feeds. See [[oracle-manipulation]].
- `flash-loan-attack-simulator.sh` — models flash loan attack paths against price-sensitive functions. See [[flash-loans]].
- `mev-vulnerability-scanner.sh` — identifies protocol functions susceptible to frontrunning, sandwiching, and liquidation MEV. See [[mev]].
- `incentive-alignment-checker.sh` — evaluates whether incentive design aligns participant behavior with protocol health
- `fee-mechanism-validator.sh` — validates fee structure sustainability and value capture mechanisms
- `reward-curve-simulator.sh` — simulates APY curves across TVL ranges and emission phases
- `token-distribution-analyzer.sh` — analyzes holder concentration, vesting schedules, whale positions
- `economic-exploit-detector.sh` — simulates known [[economic-attacks]] patterns against the protocol

## Running this Phase

```bash
cd domains/smart-contracts
./tokenomics-simulator.sh | jq .artifacts.projections
./liquidity-risk-analyzer.sh | jq .artifacts.risks
./oracle-manipulation-detector.sh | jq .artifacts.vulnerabilities
./flash-loan-attack-simulator.sh | jq .artifacts.attack_paths
./mev-vulnerability-scanner.sh | jq .artifacts.vulnerabilities
./economic-exploit-detector.sh | jq .artifacts.exploits
```

## Blocking Conditions

- `"status":"fail"` from `flash-loan-attack-simulator.sh` — profitable flash loan attack path confirmed
- `"status":"fail"` from `oracle-manipulation-detector.sh` — confirmed profitable manipulation path exists
- `"status":"fail"` from `economic-exploit-detector.sh` — economic attack with realistic capital succeeds
- `"status":"fail"` from `tokenomics-simulator.sh` — protocol becomes insolvent within modeled time horizon

## Next Phase

After passing Phase 8, proceed to [[phase-09-operations]].
