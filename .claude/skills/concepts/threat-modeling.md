---
description: Threat modeling — the systematic identification of protocol attack surfaces, adversary capabilities, and trust boundaries before security testing begins.
tags: [security, methodology, protocol-architecture]
links: [access-control, reentrancy, economic-attacks, phase-02-security]
---

# Threat Modeling

Threat modeling maps who can attack the protocol, what assets are at risk, and through which paths. It produces an attack surface matrix that guides which security checks to prioritize. Done well, it prevents the common failure of performing exhaustive low-level checks while missing a systemic architectural vulnerability.

## Key Questions

**Who are the adversaries?**
- External attackers (MEV bots, white/black hat hackers)
- Privileged insiders (admin key holders, governance participants)
- Economic adversaries (whales, competitors)

**What are the assets?**
- User funds in the protocol
- Admin/upgrade keys
- Oracle price feeds
- Off-chain relayer keys

**What are the trust boundaries?**
- Contracts you own vs. third-party contracts you call
- On-chain state vs. off-chain data (oracles, bridges)
- EOAs vs. multisigs vs. contracts

## Trust Boundary Failures

Most critical vulnerabilities occur at trust boundaries — places where the protocol makes assumptions about external inputs that an adversary can violate:
- Calling an untrusted contract without [[reentrancy]] protection
- Trusting a price feed without staleness validation (see oracle nodes)
- Assuming [[access-control]] is sufficient without modeling insider threats

## [[economic-attacks]] Surface

Threat modeling should explicitly include economic attack scenarios: what happens if an adversary controls 10% of liquidity? 51% of governance tokens? Can accumulate a large short position before disclosing a vulnerability? These are not code bugs but are as damaging.

## Skills that Support Threat Modeling

- `threat-model-generator.sh` — generates an attack surface matrix from contract analysis
- `secrets-safety-validator.sh` — validates that credentials are not exposed in trust boundaries
- `access-control-validator.sh` — maps all trust boundaries and access control enforcement points

```bash
./domains/smart-contracts/threat-model-generator.sh | jq .artifacts.attack_surface
./domains/smart-contracts/secrets-safety-validator.sh | jq .artifacts.findings
```

## Signals

- `"status":"fail"` from `threat-model-generator.sh` — critical trust boundary with no protection identified
- `"status":"warn"` — external contract calls with no reentrancy protection or return value checking

## Related Concepts

- [[access-control]] — trust boundaries require access control enforcement
- [[reentrancy]] — trust boundary violations at external calls are the reentrancy attack surface
- [[economic-attacks]] — threat modeling must include economic adversaries, not just code exploiters
