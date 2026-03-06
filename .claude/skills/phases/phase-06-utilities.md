---
description: Phase 6 Utilities & Docs — 8 skills covering dependency auditing, formatting, static analysis, test running, GitHub integration, documentation standards, and deployment validation.
tags: [phase, utilities, ci, docs]
links: [phase-05-standards, phase-07-protocol-architecture]
---

# Phase 6: Utilities & Docs

This phase handles cross-cutting concerns: dependency security, code quality enforcement, additional static analysis passes, and documentation standards validation. It also includes GitHub integration checks and deployment script validation.

These checks produce `"status":"warn"` for most findings rather than hard fails, but dependency vulnerabilities and deployment script errors can produce `"status":"fail"`.

## Skills in this Phase

- `dependency-audit.sh` — audits npm/forge dependencies for known vulnerabilities and version pinning compliance
- `format-check.sh` — validates code formatting consistency across Solidity and supporting files
- `static-analysis.sh` — runs additional static analysis tools beyond Slither (e.g. Mythril, semgrep rules)
- `run-tests.sh` — wrapper that runs the full test suite and aggregates results
- `github-status.sh` — validates GitHub Actions CI configuration and branch protection rules
- `docs-standard-install.sh` — validates that the Cyfrin docs standard is installed and CLAUDE.md is current
- `integration-test-validator.sh` — validates integration test coverage against external protocol dependencies
- `deployment-script-validator.sh` — validates deployment scripts for correct initialization order, constructor arguments, and post-deployment verification steps

## Running this Phase

```bash
cd domains/smart-contracts
./dependency-audit.sh | jq .artifacts.vulnerabilities
./format-check.sh | jq .artifacts.violations
./static-analysis.sh | jq .artifacts.findings
./deployment-script-validator.sh | jq .artifacts.issues
./github-status.sh | jq .artifacts.configuration
```

## Blocking Conditions

- `"status":"fail"` from `dependency-audit.sh` — critical CVE in a direct dependency
- `"status":"fail"` from `deployment-script-validator.sh` — deployment script will fail or produce invalid initialization state

## Next Phase

After passing Phase 6, proceed to [[phase-07-protocol-architecture]].
