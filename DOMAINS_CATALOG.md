# Domains Catalog

> Comprehensive catalog of all domains and skills in the Web3 Systems Architecture Platform

**Last Updated:** 2026-03-06
**Total Domains:** 5 (1 production, 4 planned)
**Total Skills:** 79 (Smart Contracts) → Target: 300+ by Q4 2026

---

## 🏗️ Platform Architecture

The Web3 Systems Architecture Platform is organized into independent, domain-specific validation modules. Each domain can be developed, tested, and deployed independently while sharing common orchestration infrastructure.

### Domain Structure

```
domains/
├── smart-contracts/    ✅ PRODUCTION (79 skills)
├── frontend/          📋 PLANNED (50+ skills)
├── backend/           📋 PLANNED (40+ skills)
├── infrastructure/    📋 PLANNED (40+ skills)
└── security/          📋 PLANNED (30+ skills)
```

---

## 🎯 Domain 1: Smart Contracts (PRODUCTION)

**Status:** ✅ Production Ready
**Skills:** 79
**Technology Stack:** Solidity, Foundry, Slither, Echidna
**Pipeline Phases:** 10

### Phase 1: Structure & Dependencies (4 skills)

| Skill # | Name                    | Purpose                                   | Status |
| ------- | ----------------------- | ----------------------------------------- | ------ |
| 01      | project-structure-check | Validates Foundry project layout          | ✅     |
| 02      | solidity-format-check   | Enforces Solidity style guide             | ✅     |
| 03      | foundry-config-check    | Validates foundry.toml configuration      | ✅     |
| 04      | compile-check           | Verifies contracts compile without errors | ✅     |

### Phase 2: Security Analysis (7 skills)

| Skill # | Name                           | Purpose                                     | Status |
| ------- | ------------------------------ | ------------------------------------------- | ------ |
| 22      | threat-model-generator         | Generates threat models and attack surfaces | ✅     |
| 28      | secrets-safety-validator       | Detects hardcoded secrets and keys          | ✅     |
| 08      | slither-analysis               | Runs Slither static analysis                | ✅     |
| 10      | reentrancy-pattern-check       | Detects reentrancy vulnerabilities          | ✅     |
| 11      | access-control-validator       | Validates access control patterns           | ✅     |
| 32      | governance-safety-checker      | Validates governance mechanisms             | ✅     |
| 33      | emergency-procedures-validator | Checks emergency response procedures        | ✅     |

### Phase 3: Testing (3 skills)

| Skill # | Name               | Purpose                         | Status |
| ------- | ------------------ | ------------------------------- | ------ |
| 05      | unit-test-runner   | Executes Foundry unit tests     | ✅     |
| 06      | fuzz-test-check    | Validates fuzz testing coverage | ✅     |
| 07      | gas-snapshot-check | Tracks gas consumption changes  | ✅     |

### Phase 4: Advanced Security (4 skills)

| Skill # | Name                       | Purpose                            | Status |
| ------- | -------------------------- | ---------------------------------- | ------ |
| 12      | upgradeability-check       | Validates upgrade patterns (proxy) | ✅     |
| 13      | storage-collision-detector | Detects storage slot collisions    | ✅     |
| 16      | ownable-validator          | Validates ownership patterns       | ✅     |
| 17      | role-hierarchy-check       | Checks RBAC hierarchy              | ✅     |

### Phase 5: Standards & Integrations (5 skills)

| Skill # | Name                     | Purpose                             | Status |
| ------- | ------------------------ | ----------------------------------- | ------ |
| 18      | erc-compliance-validator | Validates ERC20/721/1155 compliance | ✅     |
| 19      | oracle-integration-guard | Checks oracle integration security  | ✅     |
| 20      | external-call-audit      | Audits external contract calls      | ✅     |
| 14      | event-emission-check     | Validates event completeness        | ✅     |
| 15      | pausable-check           | Checks circuit breaker patterns     | ✅     |

### Phase 6: Utilities & Deployment (8 skills)

| Skill # | Name                        | Purpose                          | Status |
| ------- | --------------------------- | -------------------------------- | ------ |
| 09      | dependency-audit            | Audits third-party dependencies  | ✅     |
| -       | format-check                | General formatting validation    | ✅     |
| -       | static-analysis             | Additional static analysis       | ✅     |
| -       | run-tests                   | Test execution wrapper           | ✅     |
| -       | github-status               | GitHub integration status        | ✅     |
| -       | docs-standard-install       | Documentation standards          | ✅     |
| 23      | integration-test-validator  | Validates fork/integration tests | ✅     |
| 24      | deployment-script-validator | Checks deployment scripts        | ✅     |

### Phase 7: Protocol Architecture (10 skills)

| Skill # | Name                                   | Purpose                                | Status |
| ------- | -------------------------------------- | -------------------------------------- | ------ |
| 40      | protocol-design-analyzer               | Multi-contract architecture validation | ✅     |
| 41      | consensus-mechanism-validator          | Consensus & voting validation          | ✅     |
| 42      | state-transition-safety                | State machine security                 | ✅     |
| 43      | system-invariant-checker               | Echidna invariant testing              | ✅     |
| 44      | cross-contract-dependency-mapper       | Dependency graph analysis              | ✅     |
| 45      | protocol-upgrade-safety                | Multi-contract upgrade validation      | ✅     |
| 46      | multi-contract-orchestration-validator | Complex operation security             | ✅     |
| 47      | economic-attack-surface-analyzer       | Economic exploit detection             | ✅     |
| 48      | protocol-governance-design-checker     | Governance mechanism validation        | ✅     |
| 49      | finality-guarantees-checker            | Finality property validation           | ✅     |

### Phase 8: Economic Design (10 skills)

| Skill # | Name                         | Purpose                                | Status |
| ------- | ---------------------------- | -------------------------------------- | ------ |
| 50      | tokenomics-simulator         | Token emission/distribution simulation | ✅     |
| 51      | liquidity-risk-analyzer      | AMM/liquidity pool security            | ✅     |
| 52      | oracle-manipulation-detector | Price manipulation simulation          | ✅     |
| 53      | flash-loan-attack-simulator  | Flash loan exploit scenarios           | ✅     |
| 54      | mev-vulnerability-scanner    | MEV extraction detection               | ✅     |
| 55      | incentive-alignment-checker  | Game theory validation                 | ✅     |
| 56      | fee-mechanism-validator      | Fee calculation security               | ✅     |
| 57      | reward-curve-simulator       | Staking/farming economics              | ✅     |
| 58      | token-distribution-analyzer  | Distribution fairness analysis         | ✅     |
| 59      | economic-exploit-detector    | Comprehensive economic security        | ✅     |

### Phase 9: Operations & Monitoring (10 skills)

| Skill # | Name                           | Purpose                             | Status |
| ------- | ------------------------------ | ----------------------------------- | ------ |
| 60      | live-exploit-detector          | Real-time exploit pattern detection | ✅     |
| 61      | transaction-monitor            | Transaction pattern analysis        | ✅     |
| 62      | gas-anomaly-detector           | Gas consumption anomaly detection   | ✅     |
| 63      | admin-key-activity-monitor     | Privileged operation monitoring     | ✅     |
| 64      | governance-proposal-monitor    | Governance activity tracking        | ✅     |
| 65      | emergency-response-validator   | Emergency procedure testing         | ✅     |
| 66      | incident-response-checker      | Incident runbook validation         | ✅     |
| 67      | slashing-condition-validator   | PoS slashing safety                 | ✅     |
| 68      | upgrade-governance-monitor     | Upgrade proposal monitoring         | ✅     |
| 69      | circuit-breaker-status-checker | Circuit breaker health              | ✅     |

### Phase 10: Infrastructure (10 skills)

| Skill # | Name                         | Purpose                      | Status |
| ------- | ---------------------------- | ---------------------------- | ------ |
| 70      | oracle-health-monitor        | Oracle uptime & data quality | ✅     |
| 71      | indexer-validation           | Subgraph accuracy validation | ✅     |
| 72      | automation-bot-checker       | Keeper bot reliability       | ✅     |
| 73      | cross-chain-bridge-safety    | Bridge security validation   | ✅     |
| 74      | relayer-security-validator   | Relayer security auditing    | ✅     |
| 75      | subgraph-integrity-checker   | Subgraph schema validation   | ✅     |
| 76      | rpc-endpoint-validator       | RPC reliability testing      | ✅     |
| 77      | ipfs-pinning-checker         | IPFS content availability    | ✅     |
| 78      | event-listener-validator     | Event processing reliability | ✅     |
| 79      | off-chain-dependency-auditor | Third-party service auditing | ✅     |

---

## 📋 Domain 2: Frontend/DApp (PLANNED)

**Status:** 📋 Planning Phase
**Target Skills:** 50+
**Technology Stack:** React, Next.js, wagmi, viem, RainbowKit
**Target Date:** Q2 2026

### Planned Phases

1. **React Component Security** - XSS prevention, input sanitization
2. **Web3 Integration** - Wallet connection, transaction signing
3. **State Management** - Context, Redux, Zustand patterns
4. **Performance** - Code splitting, lazy loading, caching
5. **Accessibility** - WCAG compliance, keyboard navigation
6. **Testing** - Component tests, E2E tests, visual regression
7. **Build & Deploy** - Bundle optimization, CDN deployment

---

## 📋 Domain 3: Backend/API (PLANNED)

**Status:** 📋 Planning Phase
**Target Skills:** 40+
**Technology Stack:** Node.js, Express, GraphQL, Prisma
**Target Date:** Q3 2026

### Planned Phases

1. **API Security** - Authentication, authorization, rate limiting
2. **Input Validation** - Schema validation, sanitization
3. **Database Security** - SQL injection prevention, query optimization
4. **Error Handling** - Graceful degradation, logging
5. **Performance** - Caching, load balancing, horizontal scaling
6. **Testing** - Unit, integration, load testing
7. **Monitoring** - APM, error tracking, alerting

---

## 📋 Domain 4: Infrastructure/DevOps (PLANNED)

**Status:** 📋 Planning Phase
**Target Skills:** 40+
**Technology Stack:** Docker, Kubernetes, Terraform, GitHub Actions
**Target Date:** Q3 2026

### Planned Phases

1. **Container Security** - Image scanning, runtime security
2. **Orchestration** - K8s security, pod security policies
3. **CI/CD** - Pipeline security, secret management
4. **Infrastructure as Code** - Terraform best practices
5. **Monitoring** - Prometheus, Grafana, alerting
6. **Backup & Recovery** - Disaster recovery, backup validation
7. **Compliance** - SOC2, ISO27001 checks

---

## 📋 Domain 5: Security (PLANNED)

**Status:** 📋 Planning Phase
**Target Skills:** 30+
**Technology Stack:** OWASP ZAP, Burp Suite, Nuclei
**Target Date:** Q4 2026

### Planned Phases

1. **OWASP Top 10** - Automated checks for common vulnerabilities
2. **Penetration Testing** - Automated pentest scenarios
3. **Dependency Scanning** - CVE detection, license compliance
4. **Secret Scanning** - API key, private key detection
5. **Network Security** - Firewall rules, port scanning
6. **Compliance** - GDPR, SOC2, PCI-DSS checks

---

## 🚀 Roadmap

### Q1 2026 (Complete)

- ✅ Smart Contracts Domain (79 skills)
- ✅ 10-phase pipeline
- ✅ Echidna integration
- ✅ Economic simulation framework

### Q2 2026

- 📋 Frontend/DApp Domain (50+ skills)
- 📋 React security patterns
- 📋 Web3 integration testing

### Q3 2026

- 📋 Backend/API Domain (40+ skills)
- 📋 Infrastructure/DevOps Domain (40+ skills)
- 📋 GraphQL security
- 📋 Container orchestration

### Q4 2026

- 📋 Security Domain (30+ skills)
- 📋 Cross-domain integration
- 📋 **Platform Complete: 300+ skills**

---

## 🎯 Usage

### Run All Domains

```bash
# Run all enabled domains
./core/orchestrator.sh --domain smart-contracts

# Run specific phase
./core/orchestrator.sh --domain smart-contracts --phase 2

# Security-only mode
./core/orchestrator.sh --domain smart-contracts --security
```

### Run Domain-Specific

```bash
# Smart Contracts domain
cd domains/smart-contracts
./ci-orchestrator.sh

# Future: Frontend domain
cd domains/frontend
./ci-orchestrator.sh
```

---

## 📊 Platform Metrics

| Metric          | Current | Target (Q4 2026) |
| --------------- | ------- | ---------------- |
| Total Domains   | 1       | 5                |
| Total Skills    | 79      | 300+             |
| Test Coverage   | 95%     | 95%              |
| Pipeline Phases | 10      | 35+              |
| Security Checks | 48      | 120+             |

---

## 🤝 Contributing

Each domain is independently developed and maintained. To contribute:

1. Choose a domain directory
2. Follow domain-specific skill template
3. Write tests first (TDD)
4. Submit PR with skill documentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

---

**Platform Vision:** Autonomous, domain-driven validation across the full Web3 stack, matching elite protocol team capabilities (OpenZeppelin + Trail of Bits + economic simulation + live monitoring).
