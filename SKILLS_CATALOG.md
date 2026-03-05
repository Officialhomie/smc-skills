# Smart Contract Skills Catalog

Complete reference for all 26 smart contract security and quality skills.

## Quick Start

```bash
# Run all skills
/Users/mac/skills-setup-homie/skills/ci-orchestrator.sh

# Run single skill
/Users/mac/skills-setup-homie/skills/slither-analysis.sh | jq .

# Add skills to project
/Users/mac/skills-setup-homie/add-skills.sh /path/to/project
```

## Global Commands

From anywhere, use Claude Code commands:

- `/smc-skills` - List and run skills
- `/smc-audit` - Run security audit
- `/smc-init-project <name>` - Bootstrap new project

---

## Skills 01-10: Foundation

### 01. Project Structure Check

**Path:** `project-structure-check.sh`
**Purpose:** Validates canonical smart contract project layout
**Status Codes:** `pass`, `fail`
**Checks:**

- Required directories: `contracts`, `test`, `scripts`, `tools/skills`, `docs`, `ci`

**Example Output:**

```json
{
  "skill": "project-structure-check",
  "status": "pass",
  "summary": "Project structure valid",
  "artifacts": {
    "missing_directories": []
  }
}
```

---

### 02. Solidity Format Check

**Path:** `solidity-format-check.sh`
**Purpose:** Enforces consistent formatting using `forge fmt`
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Solidity code formatting via `forge fmt --check`

---

### 03. Foundry Config Check

**Path:** `foundry-config-check.sh`
**Purpose:** Ensures `foundry.toml` exists and contains required settings
**Status Codes:** `pass`, `fail`
**Checks:**

- `foundry.toml` exists
- Required keys: `optimizer`, `solc_version`

---

### 04. Compile Check

**Path:** `compile-check.sh`
**Purpose:** Validates contracts compile without errors
**Status Codes:** `pass`, `fail`
**Checks:**

- `forge build` completes successfully

---

### 05. Unit Test Runner

**Path:** `unit-test-runner.sh`
**Purpose:** Runs Foundry test suite
**Status Codes:** `pass`, `fail`
**Checks:**

- `forge test` executes and passes

---

### 06. Fuzz Test Check

**Path:** `fuzz-test-check.sh`
**Purpose:** Runs fuzz tests with configurable runs
**Status Codes:** `pass`, `fail`
**Checks:**

- Fuzz tests execute (default: 256 runs)

---

### 07. Gas Snapshot Check

**Path:** `gas-snapshot-check.sh`
**Purpose:** Generates gas usage snapshots for regression testing
**Status Codes:** `pass`, `fail`
**Checks:**

- `forge snapshot` generates `gas-snapshot.txt`

---

### 08. Slither Analysis

**Path:** `slither-analysis.sh`
**Purpose:** Runs Slither static analysis for vulnerability detection
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Slither executes and generates JSON report
- Counts HIGH/MEDIUM severity issues

**Artifacts:**

- `build/slither.json` - Full report

---

### 09. Dependency Audit

**Path:** `dependency-audit.sh`
**Purpose:** Updates and audits Foundry dependencies
**Status Codes:** `pass`
**Checks:**

- Runs `forge update`
- Manual review required

---

### 10. Reentrancy Pattern Check

**Path:** `reentrancy-pattern-check.sh`
**Purpose:** Detects low-level call patterns prone to reentrancy
**Status Codes:** `pass`, `warn`
**Checks:**

- Scans for `call.value`, `.call{value:}`
- Reports matches for manual review

---

## Skills 11-20: Advanced Security

### 11. Access Control Validator

**Path:** `access-control-validator.sh`
**Purpose:** Validates Ownable, AccessControl patterns
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- `onlyOwner` modifier usage
- `hasRole`/`onlyRole` for AccessControl
- Critical functions (mint, burn, pause) have access control

**Critical Findings:**

- ❌ Critical functions without access control

---

### 12. Upgradeability Check

**Path:** `upgradeability-check.sh`
**Purpose:** Validates UUPS, Transparent Proxy patterns
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- No constructors in upgradeable contracts (use `initializer`)
- `initializer` modifier present
- Storage gaps (`__gap`) for upgrade safety
- `_authorizeUpgrade` in UUPS contracts

**Critical Findings:**

- ❌ Upgradeable contract uses constructor
- ⚠️ Missing storage gaps

---

### 13. Storage Collision Detector

**Path:** `storage-collision-detector.sh`
**Purpose:** Detects potential storage slot collisions in upgradeable contracts
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Storage gaps in upgradeable contracts
- State variables without gaps
- Generates `forge inspect storage-layout`

**Artifacts:**

- `build/storage-layout.json`

---

### 14. Event Emission Check

**Path:** `event-emission-check.sh`
**Purpose:** Ensures critical state changes emit events
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Critical functions emit events: `transferOwnership`, `mint`, `burn`, `pause`, etc.
- Event definitions exist

**Critical Functions Monitored:**

- transferOwnership, mint, burn, approve, transfer, pause, unpause, withdraw, deposit, setFee, updateConfig

---

### 15. Pausable Check

**Path:** `pausable-check.sh`
**Purpose:** Validates emergency pause mechanisms
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- `pause()` has access control
- `unpause()` exists
- `whenNotPaused` modifier used
- Suggests pausable for critical functions

---

### 16. Ownable Validator

**Path:** `ownable-validator.sh`
**Purpose:** Validates proper Ownable implementation
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Ownable initialization
- `onlyOwner` modifier usage
- Recommends `Ownable2Step` over `Ownable`
- Warns about `renounceOwnership` (can lock contract)

---

### 17. Role Hierarchy Check

**Path:** `role-hierarchy-check.sh`
**Purpose:** Validates AccessControl role hierarchy and admin roles
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Role definitions (`bytes32 ROLE`)
- `DEFAULT_ADMIN_ROLE` management
- `_grantRole` in constructor
- Role admin hierarchy (`_setRoleAdmin`)
- `hasRole` checks in modifiers

**Security:**

- ⚠️ Direct `_grantRole` outside constructor

---

### 18. ERC Compliance Validator

**Path:** `erc-compliance-validator.sh`
**Purpose:** Validates ERC20, ERC721, ERC1155 compliance
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

**ERC20:**

- Functions: `totalSupply`, `balanceOf`, `transfer`, `allowance`, `approve`, `transferFrom`
- Events: `Transfer`, `Approval`

**ERC721:**

- Functions: `balanceOf`, `ownerOf`, `safeTransferFrom`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`
- Events: `Transfer`

**ERC1155:**

- Functions: `balanceOf`, `balanceOfBatch`, `setApprovalForAll`, `isApprovedForAll`, `safeTransferFrom`, `safeBatchTransferFrom`

**ERC165:**

- `supportsInterface` for NFT contracts

---

### 19. Oracle Integration Guard

**Path:** `oracle-integration-guard.sh`
**Purpose:** Validates safe oracle integration (Chainlink, etc.)
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Price staleness checks (`updatedAt`, `timeStamp`)
- Zero price validation
- Round completeness (`answeredInRound`)
- Circuit breaker / fallback mechanisms
- Oracle address validation
- Decimals handling

**Critical Findings:**

- ❌ Oracle price data without staleness check
- ❌ No validation for zero oracle price

---

### 20. External Call Audit

**Path:** `external-call-audit.sh`
**Purpose:** Audits external calls for reentrancy and security issues
**Status Codes:** `pass`, `fail`, `warn`
**Checks:**

- Reentrancy guards (`nonReentrant`)
- Checks-Effects-Interactions pattern
- Return value handling for `.call()`
- Deprecated `.send()` usage
- `delegatecall` with access control

**Patterns Detected:**

- `call{value:}`, `.call()`, `.delegatecall()`, `.staticcall()`, `.transfer()`, `.send()`

**Critical Findings:**

- ❌ External calls without reentrancy guard
- ❌ State change after external call (CEI violation)
- ❌ `delegatecall` without access control (CRITICAL)

---

## Running Skills

### Individual Skill

```bash
cd /path/to/smart-contract-project
/Users/mac/skills-setup-homie/skills/slither-analysis.sh | jq .
```

### Category-Based

```bash
# Security audit only
for skill in slither-analysis reentrancy-pattern-check access-control-validator external-call-audit; do
  /Users/mac/skills-setup-homie/skills/$skill.sh
done
```

### Full CI/CD

```bash
/Users/mac/skills-setup-homie/skills/ci-orchestrator.sh
```

---

## Integration with Projects

### Add to Existing Project

```bash
# Copy skills to project
/Users/mac/skills-setup-homie/add-skills.sh /path/to/project

# Or symlink (skills stay in central repo)
/Users/mac/skills-setup-homie/add-skills.sh --link /path/to/project

# Then run from project
cd /path/to/project
./tools/skills/ci-orchestrator.sh
```

### New Project

```bash
# Bootstrap complete project with skills
/Users/mac/skills-setup-homie/smc-init my-protocol

cd my-protocol
./tools/skills/ci-orchestrator.sh
```

---

## Artifact Schema

All skills output JSON in this format:

```json
{
  "skill": "skill-name",
  "status": "pass|fail|warn",
  "summary": "human-readable summary",
  "artifacts": {
    "skill-specific-data": "..."
  },
  "metadata": {
    "timestamp": "ISO8601",
    "runner": "local"
  }
}
```

---

## Security Severity Mapping

| Status | Severity        | Action Required       |
| ------ | --------------- | --------------------- |
| `fail` | CRITICAL / HIGH | Fix before deployment |
| `warn` | MEDIUM / LOW    | Review and address    |
| `pass` | INFO            | Monitor               |

---

## Recommended Workflows

### Pre-Commit

```bash
./tools/skills/solidity-format-check.sh
./tools/skills/compile-check.sh
./tools/skills/unit-test-runner.sh
```

### Pre-Deploy (Testnet)

```bash
./tools/skills/ci-orchestrator.sh
```

### Pre-Deploy (Mainnet)

```bash
# Run all security skills
for skill in slither-analysis reentrancy-pattern-check access-control-validator \
             external-call-audit oracle-integration-guard upgradeability-check \
             storage-collision-detector erc-compliance-validator; do
  /Users/mac/skills-setup-homie/skills/$skill.sh
done

# Manual review + professional audit
```

---

## Extension Guide

To add new skills:

1. **Create skill script** in `/Users/mac/skills-setup-homie/skills/`
2. **Follow naming convention**: `kebab-case.sh`
3. **Output JSON artifact** with status/summary/artifacts
4. **Make executable**: `chmod +x`
5. **Update orchestrator** if needed
6. **Document** in this catalog

---

**Total Skills:** 26
**Last Updated:** 2026-03-05
**Location:** `/Users/mac/skills-setup-homie/skills/`
