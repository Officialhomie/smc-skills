#!/usr/bin/env bash
# Optional: create GitHub repo and push. Set SMC_GITHUB_VISIBILITY=public|private (default: private).
# Run from repo root: ./tools/skills/github-repo-setup.sh
set -e
ROOT="$(git rev-parse --show-toplevel)" || ROOT="$PWD"
cd "$ROOT"
STATUS="warn"
SUMMARY="GitHub repo setup skipped (gh not installed or not authenticated)"
REPO_URL=""
if command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    REPO_URL=$(git remote get-url origin)
    STATUS="pass"
    SUMMARY="Remote origin already set: $REPO_URL"
  elif [ -n "${SMC_GITHUB_CREATE:-}" ]; then
    VIS="${SMC_GITHUB_VISIBILITY:-private}"
    if gh repo create --source=. --remote=origin --"$VIS" --push 2>/dev/null; then
      REPO_URL=$(git remote get-url origin)
      STATUS="pass"
      SUMMARY="Created repo and pushed to $REPO_URL"
    else
      STATUS="fail"
      SUMMARY="gh repo create or push failed"
    fi
  else
    SUMMARY="Set SMC_GITHUB_CREATE=1 to create repo and push (origin not set)"
  fi
fi
echo "{\"skill\":\"github-repo-setup\",\"status\":\"$STATUS\",\"summary\":\"$SUMMARY\",\"artifacts\":{\"repo_url\":\"$REPO_URL\"},\"metadata\":{\"runner\":\"local\"}}"
