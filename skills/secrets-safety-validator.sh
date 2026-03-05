#!/usr/bin/env bash
# Skill 28: Secrets & Key Safety Validator
# Scans for hardcoded secrets, private keys, and credential exposure
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
cd "$ROOT"

STATUS="pass"
SUMMARY="No secrets or credential exposure detected"
FINDINGS=()
VIOLATIONS=()
WARNINGS=()

# Private key patterns (Ethereum, Bitcoin, generic)
PRIVATE_KEY_PATTERNS=(
  "0x[a-fA-F0-9]{64}"  # Ethereum private key
  "-----BEGIN.*PRIVATE KEY-----"  # PEM format
  "xprv[a-zA-Z0-9]{100,}"  # Bitcoin extended private key
  "\"privateKey\"\s*:\s*\"[^\"]+\""  # JSON privateKey field
  "private_key\s*=\s*['\"][^'\"]+['\"]"  # Assignment
)

# API key patterns
API_KEY_PATTERNS=(
  "sk-[a-zA-Z0-9]{48}"  # OpenAI API key
  "AIza[0-9A-Za-z\\-_]{35}"  # Google API key
  "AKIA[0-9A-Z]{16}"  # AWS Access Key ID
  "['\"]api[_-]?key['\"]\s*[:=]\s*['\"][^'\"]{20,}['\"]"  # Generic API key
  "bearer\s+[a-zA-Z0-9\\-._~+/]+=*"  # Bearer token
)

# Secret patterns
SECRET_PATTERNS=(
  "password\s*=\s*['\"][^'\"]{8,}['\"]"
  "secret\s*=\s*['\"][^'\"]{8,}['\"]"
  "token\s*=\s*['\"][^'\"]{20,}['\"]"
)

# Files to scan (exclude common non-source files)
FILES_TO_SCAN=$(find . -type f \
  -not -path "*/node_modules/*" \
  -not -path "*/lib/*" \
  -not -path "*/build/*" \
  -not -path "*/dist/*" \
  -not -path "*/.git/*" \
  -not -path "*/coverage/*" \
  -not -name "*.lock" \
  -not -name "*.log" \
  -not -name "*.md" \
  2>/dev/null || echo "")

if [ -z "$FILES_TO_SCAN" ]; then
  STATUS="warn"
  SUMMARY="No files found to scan for secrets"
else
  # Scan for private keys
  for pattern in "${PRIVATE_KEY_PATTERNS[@]}"; do
    matches=$(echo "$FILES_TO_SCAN" | xargs grep -nHE "$pattern" 2>/dev/null || echo "")
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        file=$(echo "$match" | cut -d: -f1)
        line=$(echo "$match" | cut -d: -f2)

        # Skip .env.example and test files
        if [[ ! "$file" =~ \.example$ ]] && [[ ! "$file" =~ test|spec|fixture ]]; then
          VIOLATIONS+=("CRITICAL: Potential private key in $file:$line")
          STATUS="fail"
        fi
      done <<< "$matches"
    fi
  done

  # Scan for API keys
  for pattern in "${API_KEY_PATTERNS[@]}"; do
    matches=$(echo "$FILES_TO_SCAN" | xargs grep -nHEi "$pattern" 2>/dev/null || echo "")
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        file=$(echo "$match" | cut -d: -f1)
        line=$(echo "$match" | cut -d: -f2)

        # Skip .env.example and test files
        if [[ ! "$file" =~ \.example$ ]] && [[ ! "$file" =~ test|spec|fixture ]]; then
          VIOLATIONS+=("HIGH: Potential API key in $file:$line")
          if [ "$STATUS" != "fail" ]; then
            STATUS="warn"
          fi
        fi
      done <<< "$matches"
    fi
  done

  # Scan for generic secrets
  for pattern in "${SECRET_PATTERNS[@]}"; do
    matches=$(echo "$FILES_TO_SCAN" | xargs grep -nHEi "$pattern" 2>/dev/null || echo "")
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        file=$(echo "$match" | cut -d: -f1)
        line=$(echo "$match" | cut -d: -f2)

        # Skip .env.example, test files, and comments
        if [[ ! "$file" =~ \.example$ ]] && [[ ! "$file" =~ test|spec|fixture ]] && ! echo "$match" | grep -q "^\s*//\|^\s*#\|^\s*\*"; then
          WARNINGS+=("MEDIUM: Potential secret in $file:$line")
          if [ "$STATUS" = "pass" ]; then
            STATUS="warn"
          fi
        fi
      done <<< "$matches"
    fi
  done

  # Check .gitignore for .env exclusion
  if [ -f ".gitignore" ]; then
    if ! grep -qE "^\.env$|^\.env\.local$|^\.env\.\*" ".gitignore" 2>/dev/null; then
      WARNINGS+=("WARNING: .env files not properly excluded in .gitignore")
      if [ "$STATUS" = "pass" ]; then
        STATUS="warn"
      fi
    else
      FINDINGS+=(".gitignore properly excludes .env files")
    fi
  else
    WARNINGS+=("WARNING: No .gitignore file found")
    if [ "$STATUS" = "pass" ]; then
      STATUS="warn"
    fi
  fi

  # Check for .env files in repository
  ENV_FILES=$(find . -maxdepth 2 -name ".env" -o -name ".env.local" 2>/dev/null || echo "")
  if [ -n "$ENV_FILES" ]; then
    # Check if they're tracked by git
    if git rev-parse --git-dir > /dev/null 2>&1; then
      while IFS= read -r env_file; do
        if git ls-files --error-unmatch "$env_file" >/dev/null 2>&1; then
          VIOLATIONS+=("CRITICAL: $env_file is tracked by git (should be in .gitignore)")
          STATUS="fail"
        else
          FINDINGS+=("$env_file exists but is properly untracked")
        fi
      done <<< "$ENV_FILES"
    fi
  fi

  # Check for hardcoded localhost URLs with credentials
  localhost_creds=$(echo "$FILES_TO_SCAN" | xargs grep -nHE "(http|https)://[^:]+:[^@]+@localhost" 2>/dev/null || echo "")
  if [ -n "$localhost_creds" ]; then
    while IFS= read -r match; do
      file=$(echo "$match" | cut -d: -f1)
      line=$(echo "$match" | cut -d: -f2)
      WARNINGS+=("MEDIUM: Hardcoded credentials in URL at $file:$line")
      if [ "$STATUS" = "pass" ]; then
        STATUS="warn"
      fi
    done <<< "$localhost_creds"
  fi

  # Check for AWS credentials
  aws_creds=$(echo "$FILES_TO_SCAN" | xargs grep -nHE "aws_secret_access_key|AWSSecretKey" 2>/dev/null || echo "")
  if [ -n "$aws_creds" ]; then
    while IFS= read -r match; do
      file=$(echo "$match" | cut -d: -f1)
      line=$(echo "$match" | cut -d: -f2)
      if [[ ! "$file" =~ \.example$ ]] && [[ ! "$file" =~ test|spec|fixture ]]; then
        VIOLATIONS+=("CRITICAL: AWS credentials in $file:$line")
        STATUS="fail"
      fi
    done <<< "$aws_creds"
  fi

  # Build summary
  if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    SUMMARY="${#VIOLATIONS[@]} critical secret violations detected"
  elif [ ${#WARNINGS[@]} -gt 0 ]; then
    SUMMARY="${#WARNINGS[@]} potential secret issues detected"
  else
    SUMMARY="No secrets or credential exposure detected"
  fi

  # Combine all findings
  for violation in "${VIOLATIONS[@]}"; do
    FINDINGS+=("$violation")
  done
  for warning in "${WARNINGS[@]}"; do
    FINDINGS+=("$warning")
  done
fi

# Build JSON array for findings
if [ ${#FINDINGS[@]} -eq 0 ]; then
  FINDINGS_JSON="[]"
elif command -v jq >/dev/null 2>&1; then
  FINDINGS_JSON=$(printf '%s\n' "${FINDINGS[@]}" | jq -R . | jq -s .)
else
  FINDINGS_JSON="["
  first=true
  for f in "${FINDINGS[@]}"; do
    escaped=$(echo "$f" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    if [ "$first" = true ]; then
      FINDINGS_JSON="${FINDINGS_JSON}\"$escaped\""
      first=false
    else
      FINDINGS_JSON="${FINDINGS_JSON},\"$escaped\""
    fi
  done
  FINDINGS_JSON="${FINDINGS_JSON}]"
fi

cat <<JSON
{
  "skill":"secrets-safety-validator",
  "status":"$STATUS",
  "summary":"$SUMMARY",
  "artifacts":{
    "findings":$FINDINGS_JSON,
    "violations":${#VIOLATIONS[@]},
    "warnings":${#WARNINGS[@]}
  },
  "metadata":{
    "timestamp":"$(date -u +%FT%TZ)",
    "runner":"local"
  }
}
JSON
