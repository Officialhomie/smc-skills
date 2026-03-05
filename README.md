# Smart Contract Skills System

Root-level skill scripts for Solidity/Foundry projects. Use from Claude Code, CLI, or any project to ensure security and quality.

## 🎯 Quick Start

```bash
# List all skills
ls /Users/mac/skills-setup-homie/skills/

# Run single skill
/Users/mac/skills-setup-homie/skills/slither-analysis.sh | jq .

# Run full CI suite
/Users/mac/skills-setup-homie/skills/ci-orchestrator.sh

# Add skills to project
/Users/mac/skills-setup-homie/add-skills.sh /path/to/my-project

# Bootstrap new project with skills
/Users/mac/skills-setup-homie/smc-init my-protocol
```

## 📁 Structure

```
skills-setup-homie/
├── skills/                           # 26 executable skill scripts
│   ├── project-structure-check.sh    # 01: Project layout validation
│   ├── solidity-format-check.sh      # 02: Format enforcement
│   ├── foundry-config-check.sh       # 03: Config validation
│   ├── compile-check.sh              # 04: Compilation
│   ├── unit-test-runner.sh           # 05: Unit tests
│   ├── fuzz-test-check.sh            # 06: Fuzz tests
│   ├── gas-snapshot-check.sh         # 07: Gas benchmarks
│   ├── slither-analysis.sh           # 08: Static analysis
│   ├── dependency-audit.sh           # 09: Dependency check
│   ├── reentrancy-pattern-check.sh   # 10: Reentrancy detection
│   ├── access-control-validator.sh   # 11: Access control patterns
│   ├── upgradeability-check.sh       # 12: Proxy patterns
│   ├── storage-collision-detector.sh # 13: Storage safety
│   ├── event-emission-check.sh       # 14: Event completeness
│   ├── pausable-check.sh             # 15: Emergency pause
│   ├── ownable-validator.sh          # 16: Ownable validation
│   ├── role-hierarchy-check.sh       # 17: Role-based access
│   ├── erc-compliance-validator.sh   # 18: ERC20/721/1155
│   ├── oracle-integration-guard.sh   # 19: Oracle safety
│   ├── external-call-audit.sh        # 20: External call security
│   ├── format-check.sh               # General formatting
│   ├── static-analysis.sh            # General static analysis
│   ├── run-tests.sh                  # Test runner
│   ├── github-status.sh              # GitHub integration
│   ├── github-repo-setup.sh          # Repo setup
│   └── ci-orchestrator.sh            # Runs all skills
├── add-skills.sh                     # Install skills to project
├── smc-init                          # Bootstrap new project
├── SKILLS_CATALOG.md                 # Full skill documentation
└── README.md                         # This file
```

## 🚀 Claude Code Integration

### Global Commands

From anywhere, invoke via Claude Code:

- `/smc-skills` - List and run skills interactively
- `/smc-audit` - Run comprehensive security audit
- `/smc-init-project <name>` - Bootstrap new Foundry project

These commands are registered in:

- `/Users/mac/.claude/commands/smc-skills.md`
- `/Users/mac/.claude/commands/smc-audit.md`
- `/Users/mac/.claude/commands/smc-init-project.md`

## 📦 26 Skills Overview

### Foundation (01-10)

| #   | Skill                    | Purpose                 |
| --- | ------------------------ | ----------------------- |
| 01  | project-structure-check  | Validate project layout |
| 02  | solidity-format-check    | Enforce formatting      |
| 03  | foundry-config-check     | Validate foundry.toml   |
| 04  | compile-check            | Build compilation       |
| 05  | unit-test-runner         | Run unit tests          |
| 06  | fuzz-test-check          | Fuzz testing            |
| 07  | gas-snapshot-check       | Gas benchmarks          |
| 08  | slither-analysis         | Static analysis         |
| 09  | dependency-audit         | Dependency check        |
| 10  | reentrancy-pattern-check | Reentrancy detection    |

### Advanced Security (11-20)

| #   | Skill                      | Purpose                 |
| --- | -------------------------- | ----------------------- |
| 11  | access-control-validator   | Access control patterns |
| 12  | upgradeability-check       | Proxy patterns          |
| 13  | storage-collision-detector | Storage safety          |
| 14  | event-emission-check       | Event completeness      |
| 15  | pausable-check             | Emergency pause         |
| 16  | ownable-validator          | Ownable validation      |
| 17  | role-hierarchy-check       | Role-based access       |
| 18  | erc-compliance-validator   | ERC20/721/1155          |
| 19  | oracle-integration-guard   | Oracle safety           |
| 20  | external-call-audit        | External call security  |

See [SKILLS_CATALOG.md](SKILLS_CATALOG.md) for complete documentation.

## 🔧 Usage Patterns

### 1. Run Skills Directly

```bash
# Single skill with JSON output
/Users/mac/skills-setup-homie/skills/slither-analysis.sh | jq .

# Security-focused skills
for skill in slither-analysis reentrancy-pattern-check access-control-validator \
             external-call-audit oracle-integration-guard; do
  echo "Running $skill..."
  /Users/mac/skills-setup-homie/skills/$skill.sh
done
```

### 2. Add to Existing Project

```bash
# Copy skills to project
/Users/mac/skills-setup-homie/add-skills.sh /path/to/my-project

# Or symlink (skills stay in central location)
/Users/mac/skills-setup-homie/add-skills.sh --link /path/to/my-project

# Then run from project
cd /path/to/my-project
./tools/skills/ci-orchestrator.sh
```

### 3. Bootstrap New Project

```bash
# Create complete project with skills
/Users/mac/skills-setup-homie/smc-init my-defi-protocol

cd my-defi-protocol
tree -L 2

# Output:
# my-defi-protocol/
# ├── src/
# ├── test/
# ├── script/
# ├── tools/
# │   └── skills/        # All 26 skills installed
# ├── .github/
# │   └── workflows/
# ├── foundry.toml
# └── README.md

# Run CI checks
./tools/skills/ci-orchestrator.sh
```

## 🛡️ Security Audit Workflow

Comprehensive security audit using skills:

```bash
cd /path/to/smart-contract-project

# Phase 1: Static Analysis
/Users/mac/skills-setup-homie/skills/compile-check.sh
/Users/mac/skills-setup-homie/skills/slither-analysis.sh
/Users/mac/skills-setup-homie/skills/reentrancy-pattern-check.sh

# Phase 2: Access Control
/Users/mac/skills-setup-homie/skills/access-control-validator.sh
/Users/mac/skills-setup-homie/skills/ownable-validator.sh
/Users/mac/skills-setup-homie/skills/role-hierarchy-check.sh

# Phase 3: External Integrations
/Users/mac/skills-setup-homie/skills/external-call-audit.sh
/Users/mac/skills-setup-homie/skills/oracle-integration-guard.sh

# Phase 4: Upgradeability & Storage
/Users/mac/skills-setup-homie/skills/upgradeability-check.sh
/Users/mac/skills-setup-homie/skills/storage-collision-detector.sh

# Phase 5: Standards Compliance
/Users/mac/skills-setup-homie/skills/erc-compliance-validator.sh
/Users/mac/skills-setup-homie/skills/event-emission-check.sh
/Users/mac/skills-setup-homie/skills/pausable-check.sh

# Phase 6: Testing
/Users/mac/skills-setup-homie/skills/unit-test-runner.sh
/Users/mac/skills-setup-homie/skills/fuzz-test-check.sh
```

Or simply:

```bash
/Users/mac/skills-setup-homie/skills/ci-orchestrator.sh
```

## 📊 JSON Artifact Format

All skills output structured JSON:

```json
{
  "skill": "skill-name",
  "status": "pass|fail|warn",
  "summary": "human-readable summary",
  "artifacts": {
    "skill-specific-data": "..."
  },
  "metadata": {
    "timestamp": "2026-03-05T20:57:42Z",
    "runner": "local"
  }
}
```

## 🎯 Recommended Workflows

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
./tools/skills/solidity-format-check.sh || exit 1
./tools/skills/compile-check.sh || exit 1
./tools/skills/unit-test-runner.sh || exit 1
```

### CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
- name: Run Smart Contract CI
  run: ./tools/skills/ci-orchestrator.sh
```

### Pre-Deploy Checklist

**Testnet:**

```bash
./tools/skills/ci-orchestrator.sh
```

**Mainnet:**

```bash
# Run all security skills
/Users/mac/skills-setup-homie/skills/slither-analysis.sh
/Users/mac/skills-setup-homie/skills/external-call-audit.sh
/Users/mac/skills-setup-homie/skills/access-control-validator.sh
# ... + professional audit
```

## 🔍 Claude Code Auto-Detection

When you open a Foundry project, Claude Code will automatically:

- Detect `foundry.toml`
- Suggest running relevant skills
- Offer to run `/smc-audit` for security review

Context-aware skill suggestions:

- If `Ownable` detected → suggest `ownable-validator.sh`
- If `Upgradeable` detected → suggest `upgradeability-check.sh`
- If oracle integration → suggest `oracle-integration-guard.sh`

## 📚 Documentation

- [SKILLS_CATALOG.md](SKILLS_CATALOG.md) - Complete skill reference
- [SMC_INIT_GUIDE.md](/Users/mac/Downloads/queries/SMC_INIT_GUIDE.md) - Project bootstrap guide
- [/Users/mac/.claude/commands/](~/.claude/commands/) - Global command definitions

## 🏗️ Extending the System

To add new skills:

1. Create script in `skills/` directory
2. Follow naming convention: `kebab-case.sh`
3. Output JSON artifact with status/summary/artifacts
4. Make executable: `chmod +x`
5. Update `ci-orchestrator.sh` if needed
6. Document in `SKILLS_CATALOG.md`

Example template:

```bash
#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="check completed"
# ... your logic ...

cat <<JSON
{
  "skill":"my-new-skill",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{},
  "metadata":{"timestamp":"$(date -u +%FT%TZ)"}
}
JSON
```

## 🎓 Philosophy

**Agent-First Design:**

- Skills are autonomous, composable agents
- Each skill emits structured JSON artifacts
- Skills work from any directory (auto-detect project root)
- Fail-fast with clear error messages

**Security First:**

- 10 security-focused skills (11-20)
- CRITICAL/HIGH findings block deployment
- Enforce security best practices automatically

**Parallel Execution:**

- Skills are independent and parallelizable
- CI orchestrator runs in sequence for clarity
- Can be run in parallel for faster feedback

## 📞 Support

- Issues: Report in project repository
- Documentation: See [SKILLS_CATALOG.md](SKILLS_CATALOG.md)
- Claude Code: Use `/smc-skills` for help

---

**Total Skills:** 26
**Global Commands:** 3
**Last Updated:** 2026-03-05
**Maintained by:** Claude Code Skills System
