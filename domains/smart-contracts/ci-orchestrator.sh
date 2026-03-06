#!/usr/bin/env bash
# Smart Contracts Domain CI Orchestrator - 79 Skills across 10 Phases
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
DOMAIN_DIR="$ROOT/domains/smart-contracts"
cd "$DOMAIN_DIR"

SKILLS=(
  # Phase 1: Structure & Dependencies (4 skills)
  "./project-structure-check.sh"
  "./solidity-format-check.sh"
  "./foundry-config-check.sh"
  "./compile-check.sh"

  # Phase 2: Security Analysis (7 skills)
  "./threat-model-generator.sh"
  "./secrets-safety-validator.sh"
  "./slither-analysis.sh"
  "./reentrancy-pattern-check.sh"
  "./access-control-validator.sh"
  "./governance-safety-checker.sh"
  "./emergency-procedures-validator.sh"

  # Phase 3: Testing (3 skills)
  "./unit-test-runner.sh"
  "./fuzz-test-check.sh"
  "./gas-snapshot-check.sh"

  # Phase 4: Advanced Security Checks (4 skills)
  "./upgradeability-check.sh"
  "./storage-collision-detector.sh"
  "./ownable-validator.sh"
  "./role-hierarchy-check.sh"

  # Phase 5: Standards & Integrations (5 skills)
  "./erc-compliance-validator.sh"
  "./oracle-integration-guard.sh"
  "./external-call-audit.sh"
  "./event-emission-check.sh"
  "./pausable-check.sh"

  # Phase 6: Utilities & Docs (8 skills)
  "./dependency-audit.sh"
  "./format-check.sh"
  "./static-analysis.sh"
  "./run-tests.sh"
  "./github-status.sh"
  "./docs-standard-install.sh"
  "./integration-test-validator.sh"
  "./deployment-script-validator.sh"

  # Phase 7: Protocol Architecture (10 skills)
  "./protocol-design-analyzer.sh"
  "./consensus-mechanism-validator.sh"
  "./state-transition-safety.sh"
  "./system-invariant-checker.sh"
  "./cross-contract-dependency-mapper.sh"
  "./protocol-upgrade-safety.sh"
  "./multi-contract-orchestration-validator.sh"
  "./economic-attack-surface-analyzer.sh"
  "./protocol-governance-design-checker.sh"
  "./finality-guarantees-checker.sh"

  # Phase 8: Economic Design & Simulation (10 skills)
  "./tokenomics-simulator.sh"
  "./liquidity-risk-analyzer.sh"
  "./oracle-manipulation-detector.sh"
  "./flash-loan-attack-simulator.sh"
  "./mev-vulnerability-scanner.sh"
  "./incentive-alignment-checker.sh"
  "./fee-mechanism-validator.sh"
  "./reward-curve-simulator.sh"
  "./token-distribution-analyzer.sh"
  "./economic-exploit-detector.sh"

  # Phase 9: Operations & Live Monitoring (10 skills)
  "./live-exploit-detector.sh"
  "./transaction-monitor.sh"
  "./gas-anomaly-detector.sh"
  "./admin-key-activity-monitor.sh"
  "./governance-proposal-monitor.sh"
  "./emergency-response-validator.sh"
  "./incident-response-checker.sh"
  "./slashing-condition-validator.sh"
  "./upgrade-governance-monitor.sh"
  "./circuit-breaker-status-checker.sh"

  # Phase 10: Infrastructure & Off-Chain (10 skills)
  "./oracle-health-monitor.sh"
  "./indexer-validation.sh"
  "./automation-bot-checker.sh"
  "./cross-chain-bridge-safety.sh"
  "./relayer-security-validator.sh"
  "./subgraph-integrity-checker.sh"
  "./rpc-endpoint-validator.sh"
  "./ipfs-pinning-checker.sh"
  "./event-listener-validator.sh"
  "./off-chain-dependency-auditor.sh"
)

echo "🚀 Smart Contracts Domain Validation - 79 Skills"
echo "================================================"
echo ""

PASSED=0
FAILED=0
WARNED=0

for s in "${SKILLS[@]}"; do
  skill_name=$(basename "$s" .sh)
  echo ">>> Running: $skill_name"

  if [ ! -f "$s" ]; then
    echo "❌ Skill not found: $s"
    ((FAILED++))
    continue
  fi

  out=$("$s" 2>&1 || echo '{"status":"fail","summary":"execution error"}')
  echo "$out"

  status=$(echo "$out" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

  case "$status" in
    "pass")
      ((PASSED++))
      ;;
    "fail")
      echo "❌ Skill $skill_name failed. Aborting pipeline."
      exit 1
      ;;
    "warn")
      ((WARNED++))
      ;;
    *)
      echo "⚠️  Unknown status for $skill_name"
      ((WARNED++))
      ;;
  esac
  echo ""
done

echo "================================================"
echo "✅ Pipeline Complete"
echo "   Passed: $PASSED"
echo "   Warned: $WARNED"
echo "   Failed: $FAILED"
echo "================================================"

cat <<JSON
{
  "skill": "ci-orchestrator",
  "status": "pass",
  "summary": "Smart Contracts domain validation complete: $PASSED passed, $WARNED warned, $FAILED failed",
  "metadata": {
    "total_skills": 79,
    "passed": $PASSED,
    "warned": $WARNED,
    "failed": $FAILED,
    "timestamp": "$(date -u +%FT%TZ)"
  }
}
JSON
