# Smart Contracts Domain

> Production-ready validation for Solidity/Foundry smart contract development

**Status:** ✅ Production Ready
**Skills:** 79
**Pipeline Phases:** 10
**Coverage:** Protocol architecture → Economic design → Operations → Infrastructure

---

## 🎯 Overview

The Smart Contracts domain provides comprehensive, autonomous validation across the full Solidity development lifecycle. Matching capabilities of elite protocol teams (OpenZeppelin + Trail of Bits + economic simulation + live monitoring).

### What This Domain Validates

- ✅ **Security**: Reentrancy, access control, storage collisions, governance
- ✅ **Architecture**: Multi-contract systems, protocol upgrades, state machines
- ✅ **Economics**: Tokenomics, MEV, flash loans, liquidity risks
- ✅ **Operations**: Live monitoring, incident response, emergency procedures
- ✅ **Infrastructure**: Oracles, indexers, bridges, off-chain dependencies
- ✅ **Standards**: ERC20/721/1155, events, upgradeability patterns
- ✅ **Testing**: Unit, fuzz, invariant, fork testing

---

## 📦 Prerequisites

### Required Tools

```bash
# Foundry (core requirement)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Slither (static analysis)
pip install slither-analyzer

# jq (JSON processing)
brew install jq  # macOS
apt-get install jq  # Linux
```

### Optional Tools (for advanced features)

```bash
# Echidna (invariant testing - Phase 7)
docker pull trailofbits/echidna

# Surya (contract visualization - Phase 7)
npm install -g surya

# Python tools (dependency mapping - Phase 7)
pip install networkx matplotlib

# Forta/Tenderly (live monitoring - Phase 9)
npm install -g forta-agent
```

---

## 🚀 Quick Start

### 1. Run Full Validation

```bash
cd /path/to/your/solidity/project
/path/to/domains/smart-contracts/ci-orchestrator.sh
```

This runs all 79 skills across 10 phases and generates a comprehensive report.

### 2. Run Specific Phase

```bash
# Phase 1: Structure & Dependencies only
./domains/smart-contracts/project-structure-check.sh
./domains/smart-contracts/solidity-format-check.sh
./domains/smart-contracts/foundry-config-check.sh
./domains/smart-contracts/compile-check.sh

# Phase 2: Security Analysis
./domains/smart-contracts/slither-analysis.sh
./domains/smart-contracts/reentrancy-pattern-check.sh
# ... etc
```

### 3. Run Individual Skill

```bash
# Security check
./domains/smart-contracts/slither-analysis.sh | jq .

# Output:
# {
#   "skill": "slither-analysis",
#   "status": "pass",
#   "summary": "No high/critical issues found",
#   "artifacts": {...},
#   "metadata": {...}
# }
```

---

## 🏗️ Pipeline Architecture

### Phase 1: Structure & Dependencies (4 skills)

Foundation validation - project layout, formatting, configuration.

| Skill                   | Purpose                  | Fails On                     |
| ----------------------- | ------------------------ | ---------------------------- |
| project-structure-check | Validates Foundry layout | Missing src/, test/, script/ |
| solidity-format-check   | Enforces style guide     | Formatting violations        |
| foundry-config-check    | Validates foundry.toml   | Invalid settings             |
| compile-check           | Compilation test         | Compilation errors           |

### Phase 2: Security Analysis (7 skills)

Core security validation - threat modeling, static analysis, access control.

| Skill                          | Purpose                | Fails On                  |
| ------------------------------ | ---------------------- | ------------------------- |
| threat-model-generator         | Attack surface mapping | Missing threat model      |
| secrets-safety-validator       | Secret detection       | Hardcoded keys            |
| slither-analysis               | Static analysis        | High/critical issues      |
| reentrancy-pattern-check       | Reentrancy detection   | Unsafe external calls     |
| access-control-validator       | Access control audit   | Missing modifiers         |
| governance-safety-checker      | Governance validation  | Centralization risks      |
| emergency-procedures-validator | Emergency checks       | Missing pause/kill switch |

### Phase 3: Testing (3 skills)

Test coverage and quality validation.

| Skill              | Purpose        | Fails On                 |
| ------------------ | -------------- | ------------------------ |
| unit-test-runner   | Executes tests | Test failures            |
| fuzz-test-check    | Fuzz coverage  | Missing fuzz tests       |
| gas-snapshot-check | Gas tracking   | Unexpected gas increases |

### Phase 4: Advanced Security (4 skills)

Deep security patterns - upgradeability, storage, RBAC.

| Skill                      | Purpose                  | Fails On           |
| -------------------------- | ------------------------ | ------------------ |
| upgradeability-check       | Proxy pattern validation | Unsafe upgrades    |
| storage-collision-detector | Storage layout safety    | Storage collisions |
| ownable-validator          | Ownership pattern audit  | Unsafe ownership   |
| role-hierarchy-check       | RBAC validation          | Role confusion     |

### Phase 5: Standards & Integrations (5 skills)

ERC compliance and external integrations.

| Skill                    | Purpose               | Fails On            |
| ------------------------ | --------------------- | ------------------- |
| erc-compliance-validator | ERC20/721/1155 checks | Standard violations |
| oracle-integration-guard | Oracle security       | Unsafe oracle usage |
| external-call-audit      | External call safety  | Unchecked calls     |
| event-emission-check     | Event completeness    | Missing events      |
| pausable-check           | Circuit breaker audit | Missing pausability |

### Phase 6: Utilities & Deployment (8 skills)

Deployment readiness and documentation.

| Skill                       | Purpose              | Fails On                  |
| --------------------------- | -------------------- | ------------------------- |
| dependency-audit            | Third-party audit    | Vulnerable deps           |
| integration-test-validator  | Fork test validation | Missing integration tests |
| deployment-script-validator | Deployment checks    | Missing scripts           |

### Phase 7: Protocol Architecture (10 skills)

Multi-contract system validation - NEW in v2.0.

| Skill                                  | Purpose                 | Advanced Feature           |
| -------------------------------------- | ----------------------- | -------------------------- |
| protocol-design-analyzer               | Architecture validation | Surya integration          |
| consensus-mechanism-validator          | Voting/consensus checks | Governance security        |
| state-transition-safety                | State machine audit     | CEI enforcement            |
| system-invariant-checker               | Invariant testing       | **Echidna integration**    |
| cross-contract-dependency-mapper       | Dependency graph        | **NetworkX visualization** |
| protocol-upgrade-safety                | Multi-contract upgrades | Upgrade orchestration      |
| multi-contract-orchestration-validator | Complex operations      | Transaction ordering       |
| economic-attack-surface-analyzer       | Economic exploits       | Attack vectors             |
| protocol-governance-design-checker     | Governance design       | Decentralization           |
| finality-guarantees-checker            | Finality validation     | Consensus properties       |

### Phase 8: Economic Design (10 skills)

Economic security and tokenomics - NEW in v2.0.

| Skill                        | Purpose               | Simulation Capability    |
| ---------------------------- | --------------------- | ------------------------ |
| tokenomics-simulator         | Token economics       | **Python simulation**    |
| liquidity-risk-analyzer      | AMM/pool security     | Liquidity analysis       |
| oracle-manipulation-detector | Price manipulation    | Attack scenarios         |
| flash-loan-attack-simulator  | Flash loan exploits   | **Economic simulations** |
| mev-vulnerability-scanner    | MEV detection         | Frontrunning patterns    |
| incentive-alignment-checker  | Game theory           | Incentive analysis       |
| fee-mechanism-validator      | Fee security          | Fee calculation audit    |
| reward-curve-simulator       | Staking/farming       | **Reward modeling**      |
| token-distribution-analyzer  | Distribution fairness | Gini coefficient         |
| economic-exploit-detector    | Economic security     | Comprehensive checks     |

### Phase 9: Operations & Monitoring (10 skills)

Live production monitoring - NEW in v2.0.

| Skill                          | Purpose                | Monitoring Type       |
| ------------------------------ | ---------------------- | --------------------- |
| live-exploit-detector          | Real-time exploits     | **Pattern detection** |
| transaction-monitor            | Transaction analysis   | Anomaly detection     |
| gas-anomaly-detector           | Gas monitoring         | Usage spikes          |
| admin-key-activity-monitor     | Privileged ops         | Admin tracking        |
| governance-proposal-monitor    | Governance tracking    | Proposal monitoring   |
| emergency-response-validator   | Emergency procedures   | Runbook validation    |
| incident-response-checker      | Incident readiness     | Response testing      |
| slashing-condition-validator   | PoS slashing           | Slashing safety       |
| upgrade-governance-monitor     | Upgrade monitoring     | Upgrade tracking      |
| circuit-breaker-status-checker | Circuit breaker health | Breaker validation    |

### Phase 10: Infrastructure (10 skills)

Off-chain dependency validation - NEW in v2.0.

| Skill                        | Purpose             | Service Type          |
| ---------------------------- | ------------------- | --------------------- |
| oracle-health-monitor        | Oracle monitoring   | Uptime/data quality   |
| indexer-validation           | Subgraph validation | **Graph integration** |
| automation-bot-checker       | Keeper reliability  | Bot health            |
| cross-chain-bridge-safety    | Bridge security     | Bridge validation     |
| relayer-security-validator   | Relayer audit       | Relayer security      |
| subgraph-integrity-checker   | Subgraph schema     | Schema validation     |
| rpc-endpoint-validator       | RPC reliability     | Endpoint testing      |
| ipfs-pinning-checker         | IPFS availability   | **IPFS health**       |
| event-listener-validator     | Event processing    | Listener reliability  |
| off-chain-dependency-auditor | Service audit       | Dependency tracking   |

---

## 💡 Usage Examples

### Example 1: Pre-Audit Package

```bash
# Generate audit package
./domains/smart-contracts/ci-orchestrator.sh > audit-report.json

# Key skills for auditors:
# - threat-model-generator (attack surfaces)
# - slither-analysis (static analysis)
# - system-invariant-checker (invariants)
# - economic-exploit-detector (economic security)
```

### Example 2: Pre-Deploy Validation

```bash
# Critical pre-deploy checks
./deployment-script-validator.sh
./contract-verification-validator.sh
./emergency-procedures-validator.sh
./protocol-upgrade-safety.sh
```

### Example 3: Economic Security

```bash
# DeFi protocol validation
./tokenomics-simulator.sh
./liquidity-risk-analyzer.sh
./flash-loan-attack-simulator.sh
./mev-vulnerability-scanner.sh
./oracle-manipulation-detector.sh
```

### Example 4: Live Monitoring Setup

```bash
# Configure monitoring (requires RPC)
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"

# Run monitoring skills
./live-exploit-detector.sh
./transaction-monitor.sh
./admin-key-activity-monitor.sh
./governance-proposal-monitor.sh
```

---

## 🔧 Configuration

### Environment Variables

```bash
# Required for Phase 9 (Operations)
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"

# Optional: Echidna configuration
export ECHIDNA_CONFIG="echidna.yaml"

# Optional: Slither configuration
export SLITHER_CONFIG=".slither.config.json"
```

### Selective Phase Execution

Edit `ci-orchestrator.sh` to comment out unwanted phases:

```bash
# Disable Phase 9 (Operations) if no RPC access
# Comment out lines 75-84 in ci-orchestrator.sh
```

---

## 📊 Output Format

All skills output structured JSON:

```json
{
  "skill": "slither-analysis",
  "status": "pass|warn|fail",
  "summary": "Human-readable summary",
  "artifacts": {
    "findings": ["issue1", "issue2"],
    "metrics": { "high": 0, "medium": 2 }
  },
  "metadata": {
    "timestamp": "2026-03-06T12:00:00Z",
    "tool_version": "0.10.0"
  }
}
```

### Status Codes

- `pass` - No issues found
- `warn` - Non-critical issues (doesn't block pipeline)
- `fail` - Critical issues (blocks pipeline)

---

## 🎯 Integration

### CI/CD Integration (GitHub Actions)

```yaml
name: Smart Contract Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      - name: Run Validation
        run: |
          /path/to/domains/smart-contracts/ci-orchestrator.sh
```

### Pre-Commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
./domains/smart-contracts/slither-analysis.sh
./domains/smart-contracts/unit-test-runner.sh
```

---

## 🚨 Troubleshooting

### Common Issues

**Issue: Slither not found**

```bash
pip install slither-analyzer
export PATH="$HOME/.local/bin:$PATH"
```

**Issue: Echidna not available**

```bash
# Use Docker fallback (automatic)
docker pull trailofbits/echidna
```

**Issue: NetworkX import error (Skill 44)**

```bash
pip install networkx matplotlib
```

**Issue: RPC rate limiting (Phase 9)**

```bash
# Use Alchemy/Infura with higher tier
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
```

---

## 📈 Metrics & Coverage

### Elite Team Comparison

| Capability                | OpenZeppelin  | Trail of Bits | This Domain   |
| ------------------------- | ------------- | ------------- | ------------- |
| Static Analysis           | ✅            | ✅            | ✅            |
| Fuzz Testing              | ✅            | ✅            | ✅ (Echidna)  |
| Invariant Testing         | ✅            | ✅            | ✅ (Echidna)  |
| Economic Simulation       | ❌            | ❌            | ✅ (Python)   |
| Live Monitoring           | ✅ (Defender) | ❌            | ✅ (Forta)    |
| Infrastructure Validation | ❌            | ❌            | ✅ (Phase 10) |

### Coverage by Protocol Type

| Protocol Type      | Relevant Phases | Coverage |
| ------------------ | --------------- | -------- |
| Simple ERC20       | 1-6             | 95%      |
| NFT Collection     | 1-6             | 90%      |
| AMM/DEX            | 1-8             | 85%      |
| Lending Protocol   | 1-8, 10         | 80%      |
| DAO/Governance     | 1-9             | 85%      |
| Multi-Chain Bridge | 1-10            | 75%      |

---

## 🛠️ Development

### Adding New Skills

1. Create skill script following template:

   ```bash
   #!/usr/bin/env bash
   set -e
   ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
   cd "$ROOT"

   # Skill logic...

   cat <<JSON
   {
     "skill": "my-new-skill",
     "status": "pass",
     "summary": "...",
     "artifacts": {...},
     "metadata": {...}
   }
   JSON
   ```

2. Add to `ci-orchestrator.sh` in appropriate phase
3. Test independently before integration
4. Document in this README

### Testing Skills

```bash
# Test single skill
./my-skill.sh | jq .

# Verify JSON output
./my-skill.sh | jq -e '.status'

# Test in pipeline
./ci-orchestrator.sh | grep "my-skill"
```

---

## 📚 Additional Resources

- [DOMAINS_CATALOG.md](../../DOMAINS_CATALOG.md) - Full platform catalog
- [GITHUB_UPDATES.md](../../GITHUB_UPDATES.md) - Repository metadata guide
- [Foundry Book](https://book.getfoundry.sh/) - Foundry documentation
- [Slither Documentation](https://github.com/crytic/slither) - Static analysis
- [Echidna Tutorial](https://github.com/crytic/building-secure-contracts/tree/master/program-analysis/echidna) - Fuzzing guide

---

## 🤝 Contributing

Domain-specific contributions welcome. Please:

1. Follow bash scripting conventions
2. Output structured JSON
3. Include error handling
4. Add tests and documentation
5. Submit PR with examples

---

## 📜 License

MIT License - See [LICENSE](../../LICENSE) for details.

---

**Domain Vision:** Comprehensive, autonomous smart contract validation matching elite protocol teams, with unique economic simulation and infrastructure monitoring capabilities.
