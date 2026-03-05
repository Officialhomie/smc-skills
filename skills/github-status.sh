#!/usr/bin/env bash
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"
STATUS="warn"
SUMMARY="GitHub CLI not available or not authenticated"
PR_COUNT="0"
LAST_SAFE="none"
if command -v gh >/dev/null 2>&1; then
  if gh auth status -h github.com >/dev/null 2>&1; then
    STATUS="pass"
    SUMMARY="GitHub status retrieved"
    PR_COUNT=$(gh pr list --state open 2>/dev/null | wc -l | tr -d ' ')
    RAW=$(gh run list --limit 1 --json conclusion,displayTitle 2>/dev/null) || true
    LAST_RUN=$(echo "$RAW" | sed -n 's/.*"conclusion":"\([^"]*\)".*"displayTitle":"\([^"]*\)".*/\1: \2/p' | head -1 || echo "none")
    LAST_SAFE=$(echo "$LAST_RUN" | sed 's/"/_/g' | head -c 80)
    [ -z "$LAST_SAFE" ] && LAST_SAFE="none"
  fi
fi
echo "{\"skill\":\"github-status\",\"status\":\"$STATUS\",\"summary\":\"$SUMMARY\",\"artifacts\":{\"open_prs\":$PR_COUNT,\"last_run\":\"$LAST_SAFE\"},\"metadata\":{\"runner\":\"local\"}}"
