#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"
SKILLS=(
  "tools/skills/project-structure-check.sh"
  "tools/skills/solidity-format-check.sh"
  "tools/skills/foundry-config-check.sh"
  "tools/skills/compile-check.sh"
  "tools/skills/unit-test-runner.sh"
  "tools/skills/fuzz-test-check.sh"
  "tools/skills/gas-snapshot-check.sh"
  "tools/skills/slither-analysis.sh"
  "tools/skills/dependency-audit.sh"
  "tools/skills/reentrancy-pattern-check.sh"
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
