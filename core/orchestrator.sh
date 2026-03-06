#!/usr/bin/env bash
# Core Orchestrator - Web3 Systems Architecture Platform
# Runs domain-specific validation pipelines
set -e

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

# Parse arguments
DOMAIN=""
PHASE=""
SECURITY_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --phase)
      PHASE="$2"
      shift 2
      ;;
    --security)
      SECURITY_ONLY=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate domain
if [ -z "$DOMAIN" ]; then
  echo "Error: --domain required"
  echo "Usage: ./core/orchestrator.sh --domain <domain> [--phase <N>] [--security]"
  echo ""
  echo "Available domains:"
  ls -1 domains/
  exit 1
fi

DOMAIN_DIR="$ROOT/domains/$DOMAIN"
if [ ! -d "$DOMAIN_DIR" ]; then
  echo "Error: Domain '$DOMAIN' not found in domains/"
  exit 1
fi

# Check for domain orchestrator
DOMAIN_ORCHESTRATOR="$DOMAIN_DIR/ci-orchestrator.sh"
if [ ! -f "$DOMAIN_ORCHESTRATOR" ]; then
  echo "Error: No orchestrator found at $DOMAIN_ORCHESTRATOR"
  exit 1
fi

# Run domain orchestrator
echo "🚀 Running $DOMAIN domain validation..."
echo ""

if [ "$SECURITY_ONLY" = true ]; then
  echo "🛡️  Security-only mode"
  # TODO: Implement security-only filtering
fi

if [ -n "$PHASE" ]; then
  echo "📊 Phase $PHASE only"
  # TODO: Implement phase filtering
fi

# Execute domain orchestrator
exec "$DOMAIN_ORCHESTRATOR"
