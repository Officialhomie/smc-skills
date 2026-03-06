#!/usr/bin/env bash
# Skill 79: Off-Chain Dependency Auditor
# Audits third-party service dependencies
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="off-chain dependency audit completed"
FINDINGS=()

# Check package.json for external dependencies
if [ -f "package.json" ]; then
  # Count dependencies
  TOTAL_DEPS=$(grep -c '".*":' package.json | tr -d ' ' || echo "0")

  # Check for outdated dependencies
  if command -v npm >/dev/null 2>&1; then
    OUTDATED_COUNT=$(npm outdated 2>/dev/null | wc -l || echo "0")

    if [ "$OUTDATED_COUNT" -gt 1 ]; then
      FINDINGS+=("package.json: $OUTDATED_COUNT outdated dependencies detected")
      STATUS="warn"
    fi
  fi

  # Check for critical dependencies without version pins
  UNPINNED=$(grep -E '"\*"|"latest"|"~"' package.json | wc -l || echo "0")

  if [ "$UNPINNED" -gt 0 ]; then
    FINDINGS+=("package.json: $UNPINNED dependencies with unpinned versions")
    STATUS="warn"
  fi

  # Check for known vulnerable packages
  VULNERABLE_PATTERNS=("lodash" "extend" "serialize-javascript" "minimist" "yargs-parser")

  for pkg in "${VULNERABLE_PATTERNS[@]}"; do
    if grep -q "\"$pkg\"" package.json; then
      VER=$(grep "\"$pkg\"" package.json | head -1 | awk -F'"' '{print $(NF-1)}')
      FINDINGS+=("package.json: Potentially vulnerable '$pkg' ($VER) - check advisory")
      STATUS="warn"
    fi
  done
fi

# Check for external API calls
API_CALLS=$(find src -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "fetch\|axios\|request\|http.get\|http.post" 2>/dev/null || true)

if [ -n "$API_CALLS" ]; then
  while IFS= read -r file; do
    # Check for API endpoint validation
    if grep -q "fetch\|axios\|http\." "$file"; then
      if ! grep -q "https://\|secure\|tls\|certificate" "$file"; then
        FINDINGS+=("$file: HTTP calls without HTTPS requirement")
        STATUS="warn"
      fi
    fi

    # Check for timeout configuration on external calls
    if grep -q "fetch\|axios\|request" "$file"; then
      if ! grep -q "timeout\|maxDuration\|deadline" "$file"; then
        FINDINGS+=("$file: External API calls without timeout")
        STATUS="warn"
      fi
    fi

    # Check for retry logic
    API_CALL_COUNT=$(grep -c "fetch\|axios\|request\|\.get\|\.post" "$file" || echo "0")

    if [ "$API_CALL_COUNT" -gt 3 ]; then
      if ! grep -q "retry\|attempt\|exponential\|backoff" "$file"; then
        FINDINGS+=("$file: Multiple API calls ($API_CALL_COUNT) without retry logic")
        STATUS="warn"
      fi
    fi

    # Check for API key exposure
    if grep -q "API_KEY\|apiKey\|api.key\|authorization" "$file"; then
      if grep "apiKey.*=\|API_KEY.*=" "$file" | grep -v "process.env\|config\." >/dev/null; then
        FINDINGS+=("$file: Potential hardcoded API key")
        STATUS="fail"
      fi
    fi

    # Check for response validation
    if grep -q "fetch\|\.get\|\.post" "$file"; then
      if ! grep -q "status.*check\|response.*valid\|json.*parse" "$file"; then
        FINDINGS+=("$file: API responses without validation")
        STATUS="warn"
      fi
    fi
  done <<< "$API_CALLS"
fi

# Check for environment variable documentation
ENV_VARS=$(find . -name ".env*" 2>/dev/null)

if [ -n "$ENV_VARS" ]; then
  # Count environment variables
  ENV_COUNT=$(cat $ENV_VARS 2>/dev/null | grep -v "^#" | grep "=" | wc -l || echo "0")

  # Check if .env.example exists
  if [ ! -f ".env.example" ]; then
    FINDINGS+=("Missing .env.example for documenting required environment variables")
    STATUS="warn"
  fi

  # Check for unencrypted secrets in .env
  while IFS= read -r file; do
    if [ "$file" == ".env" ]; then
      UNENCRYPTED=$(grep -E "PRIVATE.*KEY|SECRET|PASSWORD|TOKEN" "$file" 2>/dev/null | wc -l || echo "0")

      if [ "$UNENCRYPTED" -gt 0 ]; then
        FINDINGS+=(".env: Unencrypted secrets detected (should use secret manager)")
        STATUS="fail"
      fi
    fi
  done <<< "$ENV_VARS"
fi

# Check for third-party service integrations
SERVICE_INTEGRATIONS=$(find src -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "slack\|discord\|telegram\|aws\|gcp\|azure\|firebase" 2>/dev/null || true)

if [ -n "$SERVICE_INTEGRATIONS" ]; then
  SERVICE_COUNT=$(echo "$SERVICE_INTEGRATIONS" | wc -l || echo "0")

  # Check for service availability monitoring
  if [ "$SERVICE_COUNT" -gt 0 ]; then
    while IFS= read -r file; do
      if ! grep -q "fallback\|backup\|circuit.*breaker\|health.*check" "$file"; then
        FINDINGS+=("$file: Third-party service without fallback/health check")
        STATUS="warn"
      fi
    done <<< "$SERVICE_INTEGRATIONS"
  fi
fi

# Check for dependency audit configuration
if [ -f "audit-config.json" ] || [ -f ".auditrc" ] || grep -q "audit" package.json 2>/dev/null; then
  # Audit is configured, good sign
  :
else
  FINDINGS+=("No dependency audit configuration found (consider npm audit or similar)")
  STATUS="warn"
fi

# Build JSON array
if [ ${#FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${FINDINGS[0]}\""
  for f in "${FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$f\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"off-chain-dependency-auditor",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "api_integration_files":"$(echo "$API_CALLS" | wc -l | tr -d ' ')",
    "service_integrations":"$(echo "$SERVICE_INTEGRATIONS" | wc -l | tr -d ' ')"
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
