#!/usr/bin/env bash
# Skill 66: Incident Response Checker
# Checks for incident response documentation and mechanisms
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="incident response documentation analyzed"
INCIDENT_FINDINGS=()

# Check for incident response documentation files
INCIDENT_DOCS=(
  "INCIDENT_RESPONSE.md"
  "SECURITY_INCIDENT.md"
  "INCIDENT.md"
  "EMERGENCY_PROCEDURES.md"
  "DISASTER_RECOVERY.md"
  "RUNBOOK.md"
  "SECURITY_RUNBOOK.md"
)

FOUND_DOCS=0

for doc in "${INCIDENT_DOCS[@]}"; do
  if [ -f "$doc" ] || [ -f "docs/$doc" ] || [ -f ".github/$doc" ]; then
    INCIDENT_FINDINGS+=("Incident response documentation found: $doc")
    FOUND_DOCS=$((FOUND_DOCS + 1))
  fi
done

if [ "$FOUND_DOCS" -eq 0 ]; then
  INCIDENT_FINDINGS+=("No incident response documentation found")
  STATUS="warn"
else
  INCIDENT_FINDINGS+=("$FOUND_DOCS incident response documentation file(s) present")
fi

# Check for security contacts/reporting mechanism
SECURITY_FILES=(
  "SECURITY.md"
  ".github/SECURITY.md"
  "SECURITY_CONTACTS.md"
  "CONTACT_SECURITY.txt"
)

FOUND_SECURITY=0

for sec in "${SECURITY_FILES[@]}"; do
  if [ -f "$sec" ]; then
    INCIDENT_FINDINGS+=("Security contact information found: $sec")
    FOUND_SECURITY=$((FOUND_SECURITY + 1))
  fi
done

if [ "$FOUND_SECURITY" -eq 0 ]; then
  INCIDENT_FINDINGS+=("No security contact information found (create SECURITY.md)")
  STATUS="warn"
fi

# Check for incident severity levels
INCIDENT_LEVELS_DOCS=$(find . -name "INCIDENT*" -o -name "EMERGENCY*" 2>/dev/null | xargs grep -l "severity\|critical\|high\|medium\|low" || true)

if [ -n "$INCIDENT_LEVELS_DOCS" ]; then
  INCIDENT_FINDINGS+=("Incident severity classification detected")
else
  INCIDENT_FINDINGS+=("No incident severity levels defined (recommend creating classification)")
  STATUS="warn"
fi

# Check for escalation procedures
ESCALATION_DOCS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "escalat\|notify\|alert\|page\|oncall" 2>/dev/null || true)

if [ -n "$ESCALATION_DOCS" ]; then
  INCIDENT_FINDINGS+=("Escalation procedures documented")
else
  INCIDENT_FINDINGS+=("No escalation/notification procedures documented")
  STATUS="warn"
fi

# Check for in-code incident reporting hooks
INCIDENT_HOOK_FILES=$(find src contracts -name "*.sol" 2>/dev/null | xargs grep -l "emit.*Incident\|emit.*Alert\|emit.*Emergency\|log.*incident" || true)

if [ -n "$INCIDENT_HOOK_FILES" ]; then
  while IFS= read -r file; do
    # Count incident events
    EVENT_COUNT=$(grep -c "emit.*Incident\|emit.*Alert\|emit.*Emergency" "$file" || echo "0")

    INCIDENT_FINDINGS+=("$file: $EVENT_COUNT incident/alert events defined")
  done <<< "$INCIDENT_HOOK_FILES"
else
  INCIDENT_FINDINGS+=("No incident/alert events found in contracts")
  STATUS="warn"
fi

# Check for monitoring/alerting integration
MONITORING_PATTERNS=(
  "monitor"
  "alert"
  "metric"
  "observability"
  "prometheus"
  "grafana"
  "datadog"
  "sentry"
)

MONITORING_FILES=$(find . -name "*.json" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs grep -l "${MONITORING_PATTERNS[0]}" 2>/dev/null || true)

if [ -n "$MONITORING_FILES" ]; then
  INCIDENT_FINDINGS+=("Monitoring/alerting configuration detected")
else
  INCIDENT_FINDINGS+=("No monitoring configuration found (recommend setting up alerts)")
  STATUS="warn"
fi

# Check for incident rollback procedures
ROLLBACK_DOCS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "rollback\|revert\|undo\|restore" 2>/dev/null || true)

if [ -n "$ROLLBACK_DOCS" ]; then
  INCIDENT_FINDINGS+=("Rollback procedures documented")
else
  INCIDENT_FINDINGS+=("No rollback procedures documented")
  STATUS="warn"
fi

# Check for incident communication templates
COMMS_DOCS=$(find . -name "*.md" -o -name "*.txt" 2>/dev/null | xargs grep -l "template\|message\|announce\|status.*update" 2>/dev/null || true)

if [ -n "$COMMS_DOCS" ]; then
  INCIDENT_FINDINGS+=("Communication templates/procedures documented")
else
  INCIDENT_FINDINGS+=("No incident communication templates found")
  STATUS="warn"
fi

# Check for post-incident review process
POSTMORTEM_DOCS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "postmortem\|post-mortem\|retrospective\|lessons.*learned" 2>/dev/null || true)

if [ -n "$POSTMORTEM_DOCS" ]; then
  INCIDENT_FINDINGS+=("Post-incident review process documented")
else
  INCIDENT_FINDINGS+=("No post-incident review process documented")
  STATUS="warn"
fi

# Check for incident tracking system references
TRACKING_PATTERNS=(
  "GitHub.*Issues"
  "JIRA"
  "incident tracking"
  "issue tracker"
)

TRACKING_REFS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "GitHub.*issue\|JIRA\|incident.*track\|issue.*track" 2>/dev/null || true)

if [ -n "$TRACKING_REFS" ]; then
  INCIDENT_FINDINGS+=("Incident tracking system referenced")
else
  INCIDENT_FINDINGS+=("No incident tracking system referenced")
  STATUS="warn"
fi

# Check for backup/recovery procedures
BACKUP_DOCS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "backup\|backup\|recovery\|restore\|snapshot" 2>/dev/null || true)

if [ -n "$BACKUP_DOCS" ]; then
  INCIDENT_FINDINGS+=("Backup/recovery procedures documented")
else
  INCIDENT_FINDINGS+=("No backup/recovery procedures documented")
  STATUS="warn"
fi

# Check for incident response team assignments
TEAM_DOCS=$(find . -name "*.md" 2>/dev/null | xargs grep -l "team\|owner\|responsible\|contact" 2>/dev/null || true)

if [ -n "$TEAM_DOCS" ]; then
  INCIDENT_FINDINGS+=("Incident response team/ownership defined")
else
  INCIDENT_FINDINGS+=("No incident response team assignments documented")
  STATUS="warn"
fi

# Build JSON array
if [ ${#INCIDENT_FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${INCIDENT_FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="[\"${INCIDENT_FINDINGS[0]}\""
  for i in "${INCIDENT_FINDINGS[@]:1}"; do
    FINDINGS_JSON="$FINDINGS_JSON,\"$i\""
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"incident-response-checker",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "incident_findings":$FINDINGS_JSON,
    "finding_count":${#INCIDENT_FINDINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)"
  }
}
JSON
