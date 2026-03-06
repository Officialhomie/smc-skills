#!/usr/bin/env bash
# Skill 69: Circuit Breaker Status Checker
# Checks circuit breaker implementations
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="circuit breaker patterns analyzed"
BREAKER_FINDINGS=()

# Check for circuit breaker patterns
CIRCUIT_BREAKER_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "circuit.*breaker\|breaker\|CircuitBreaker" || true)

if [ -n "$CIRCUIT_BREAKER_FILES" ]; then
  while IFS= read -r file; do
    BREAKER_FINDINGS+=("$file: Circuit breaker pattern detected")

    # Check for breaker states
    STATE_PATTERNS=(
      "Closed"
      "Open"
      "HalfOpen"
    )

    FOUND_STATES=0

    for state in "${STATE_PATTERNS[@]}"; do
      if grep -q "$state\|$state\|State.*$state" "$file"; then
        FOUND_STATES=$((FOUND_STATES + 1))
      fi
    done

    if [ "$FOUND_STATES" -lt 2 ]; then
      BREAKER_FINDINGS+=("$file: Incomplete circuit breaker state machine ($FOUND_STATES states)")
      STATUS="warn"
    else
      BREAKER_FINDINGS+=("$file: Complete state machine with $FOUND_STATES states")
    fi

    # Check for trip/reset logic
    if grep -q "trip\|open.*breaker" "$file"; then
      BREAKER_FINDINGS+=("$file: Trip logic implemented")

      # Check for trip threshold
      if ! grep -q "threshold\|limit\|count.*failed\|error.*count"; then
        BREAKER_FINDINGS+=("$file: Trip logic without threshold")
        STATUS="warn"
      fi
    else
      BREAKER_FINDINGS+=("$file: No trip mechanism detected")
      STATUS="warn"
    fi

    # Check for reset logic
    if grep -q "reset\|close.*breaker\|recover" "$file"; then
      BREAKER_FINDINGS+=("$file: Reset logic implemented")

      # Check for reset timeout
      if ! grep -q "timeout\|delay\|resetTime\|recovery.*time"; then
        BREAKER_FINDINGS+=("$file: Reset without timeout (add recovery delay)")
        STATUS="warn"
      fi
    else
      BREAKER_FINDINGS+=("$file: No reset mechanism detected")
      STATUS="warn"
    fi
  done <<< "$CIRCUIT_BREAKER_FILES"
else
  BREAKER_FINDINGS+=("No circuit breaker pattern detected")
fi

# Check for rate limiting patterns (related to circuit breaker)
RATE_LIMIT_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "rate.*limit\|rateLimit\|per.*block\|per.*time" || true)

if [ -n "$RATE_LIMIT_FILES" ]; then
  while IFS= read -r file; do
    BREAKER_FINDINGS+=("$file: Rate limiting pattern detected")

    # Check for limit enforcement
    LIMIT_LINES=$(grep -n "require.*<\|require.*<=\|require.*>\|require.*>=" "$file" | head -5)

    if [ -n "$LIMIT_LINES" ]; then
      BREAKER_FINDINGS+=("$file: Limit enforcement detected")
    else
      BREAKER_FINDINGS+=("$file: Rate limit without enforcement")
      STATUS="warn"
    fi
  done <<< "$RATE_LIMIT_FILES"
fi

# Check for transaction amount limits
AMOUNT_LIMIT_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "MAX_.*AMOUNT\|maxAmount\|max_amount\|transaction.*limit" || true)

if [ -n "$AMOUNT_LIMIT_FILES" ]; then
  while IFS= read -r file; do
    BREAKER_FINDINGS+=("$file: Transaction amount limit detected")

    # Check if limit is enforced in critical functions
    if grep -q "transfer\|withdraw\|burn"; then
      TRANSFER_FUNCS=$(grep -n "function.*transfer\|function.*withdraw\|function.*burn" "$file" || true)

      while IFS= read -r func_line; do
        [ -z "$func_line" ] && continue

        LINE_NUM=$(echo "$func_line" | cut -d: -f1)
        FUNC_CONTEXT=$(tail -n +$LINE_NUM "$file" | head -15)

        if ! echo "$FUNC_CONTEXT" | grep -q "MAX_\|require.*amount"; then
          BREAKER_FINDINGS+=("$file:$LINE_NUM: Transfer function without amount check")
          STATUS="warn"
        fi
      done <<< "$TRANSFER_FUNCS"
    fi
  done <<< "$AMOUNT_LIMIT_FILES"
fi

# Check for position/exposure limits
POSITION_LIMIT_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "position.*limit\|exposure\|max.*position\|maxLiquidity" || true)

if [ -n "$POSITION_LIMIT_FILES" ]; then
  while IFS= read -r file; do
    BREAKER_FINDINGS+=("$file: Position/exposure limit detected")

    # Check if limits are enforced
    if ! grep -q "require.*<\|require.*position\|require.*exposure"; then
      BREAKER_FINDINGS+=("$file: Position limit without enforcement")
      STATUS="warn"
    fi
  done <<< "$POSITION_LIMIT_FILES"
fi

# Check for emergency pause (related to circuit breaker)
PAUSE_BREAKER=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "pause.*emergency\|emergency.*pause" || true)

if [ -n "$PAUSE_BREAKER" ]; then
  BREAKER_FINDINGS+=("Emergency pause mechanism detected (acts as circuit breaker)")
else
  BREAKER_FINDINGS+=("No emergency pause detected (consider adding)")
  STATUS="warn"
fi

# Check for circuit breaker events
BREAKER_EVENTS=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emit.*CircuitBreaker\|emit.*Trip\|emit.*Reset" || true)

if [ -n "$BREAKER_EVENTS" ]; then
  while IFS= read -r file; do
    EVENT_COUNT=$(grep -c "emit" "$file" | grep -E "Trip|Reset|CircuitBreaker" || echo "0")

    BREAKER_FINDINGS+=("$file: Circuit breaker events detected")
  done <<< "$BREAKER_EVENTS"
else
  BREAKER_FINDINGS+=("No circuit breaker events found (add for monitoring)")
  STATUS="warn"
fi

# Check for threshold monitoring
THRESHOLD_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "threshold" || true)

if [ -n "$THRESHOLD_FILES" ]; then
  while IFS= read -r file; do
    THRESHOLD_COUNT=$(grep -c "threshold" "$file" || echo "0")

    BREAKER_FINDINGS+=("$file: $THRESHOLD_COUNT threshold(s) defined")

    # Check if thresholds are configurable
    if grep -q "setThreshold\|updateThreshold\|threshold.*="; then
      BREAKER_FINDINGS+=("$file: Thresholds are configurable")

      # Check if threshold updates are protected
      UPDATE_LINES=$(grep -n "setThreshold\|updateThreshold" "$file" || true)

      while IFS= read -r line_info; do
        [ -z "$line_info" ] && continue

        LINE_NUM=$(echo "$line_info" | cut -d: -f1)
        UPDATE_CONTEXT=$(tail -n +$LINE_NUM "$file" | head -10)

        if ! echo "$UPDATE_CONTEXT" | grep -q "onlyOwner\|onlyGovernance\|onlyRole"; then
          BREAKER_FINDINGS+=("$file:$LINE_NUM: Threshold update without access control")
          STATUS="warn"
        fi
      done <<< "$UPDATE_LINES"
    fi
  done <<< "$THRESHOLD_FILES"
fi

# Check for recovery/cooldown periods
COOLDOWN_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "cooldown\|recovery.*period\|timeout" || true)

if [ -n "$COOLDOWN_FILES" ]; then
  while IFS= read -r file; do
    BREAKER_FINDINGS+=("$file: Recovery/cooldown period detected")

    # Check if cooldown is enforced
    if ! grep -q "require.*time\|require.*block"; then
      BREAKER_FINDINGS+=("$file: Cooldown without enforcement")
      STATUS="warn"
    fi
  done <<< "$COOLDOWN_FILES"
fi

# Check for monitoring/alerting integration
MONITORING_BREAKER=$(find . -name "*.md" -o -name "*.txt" 2>/dev/null | xargs grep -l "circuit.*breaker\|breaker.*alert" 2>/dev/null || true)

if [ -n "$MONITORING_BREAKER" ]; then
  BREAKER_FINDINGS+=("Circuit breaker monitoring documented")
else
  BREAKER_FINDINGS+=("No circuit breaker monitoring documentation")
  STATUS="warn"
fi

# Check for circuit breaker testing
TEST_BREAKER=$(find . -name "*test*" 2>/dev/null | xargs grep -l "circuit.*breaker\|breaker.*test" 2>/dev/null || true)

if [ -n "$TEST_BREAKER" ]; then
  BREAKER_FINDINGS+=("Circuit breaker testing detected")
else
  BREAKER_FINDINGS+=("No circuit breaker tests found (test all states and transitions)")
  STATUS="warn"
fi

# Check for historical state tracking
HISTORY_BREAKER=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "history\|log.*breaker\|breaker.*event" || true)

if [ -n "$HISTORY_BREAKER" ]; then
  BREAKER_FINDINGS+=("Circuit breaker history tracking detected")
fi

# Build JSON array
if [ ${#BREAKER_FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${BREAKER_FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${BREAKER_FINDINGS[0]}\""
  for b in "${BREAKER_FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$b\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"circuit-breaker-status-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "breaker_findings":$FINDINGS_JSON,
    "finding_count":${#BREAKER_FINDINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
