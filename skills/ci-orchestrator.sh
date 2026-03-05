#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"
SKILLS=(
  # Phase 1: Structure & Dependencies
  "tools/skills/project-structure-check.sh"
  "tools/skills/solidity-format-check.sh"
  "tools/skills/foundry-config-check.sh"
  "tools/skills/compile-check.sh"

  # Phase 2: Security Analysis
  "tools/skills/threat-model-generator.sh"
  "tools/skills/secrets-safety-validator.sh"
  "tools/skills/slither-analysis.sh"
  "tools/skills/reentrancy-pattern-check.sh"
  "tools/skills/access-control-validator.sh"
  "tools/skills/governance-safety-checker.sh"
  "tools/skills/emergency-procedures-validator.sh"

  # Phase 3: Testing
  "tools/skills/unit-test-runner.sh"
  "tools/skills/fuzz-test-check.sh"
  "tools/skills/gas-snapshot-check.sh"

  # Phase 4: Advanced Security Checks
  "tools/skills/upgradeability-check.sh"
  "tools/skills/storage-collision-detector.sh"
  "tools/skills/ownable-validator.sh"
  "tools/skills/role-hierarchy-check.sh"

  # Phase 5: Standards & Integrations
  "tools/skills/erc-compliance-validator.sh"
  "tools/skills/oracle-integration-guard.sh"
  "tools/skills/external-call-audit.sh"
  "tools/skills/event-emission-check.sh"
  "tools/skills/pausable-check.sh"

  # Phase 6: Utilities
  "tools/skills/dependency-audit.sh"
  "tools/skills/format-check.sh"
  "tools/skills/static-analysis.sh"
  "tools/skills/run-tests.sh"
  "tools/skills/github-status.sh"
)
for s in "${SKILLS[@]}"; do
  echo ">>> running $s"
  out=$($s)
  echo "$out"
  status=$(echo "$out" | awk '/"status"/{print $2}' | tr -d '",')
  if [ "$status" = "fail" ]; then
    echo "Skill $s failed. Aborting."
    exit 1
  fi
done
echo '{"skill":"ci-orchestrator","status":"pass","summary":"all skills completed"}'
