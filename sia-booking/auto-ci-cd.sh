#!/bin/bash

# ==========================================
# SIA Booking - Autonomous Secure CI/CD
# ==========================================

echo "🛡️ Starting Security & Quality Validation with [AI Agent - Gatekeeper]..."

# 1. Get files change
CHANGED_FILES=$(git diff --name-only master)

if [ -z "$CHANGED_FILES" ]; then
    echo " equality ✅ No new file changes to validate."
    exit 0
fi

echo "🔍 Files to validate: $CHANGED_FILES"

# 2. Read contend
CODE_CONTEXT=$(git diff master)

# 3. Call Gatekeeper Agent (openai/gpt-5.4-mini) to review (SonarQube & Security Scan)
REVIEW_RESULT=$(openclaw agent \
  --agent gatekeeper \
  --session-id "review-$(date +%s)" \
  -m "You are a Senior Security Architect and SonarQube Specialist.
  Review the following code changes against branch 'master':

  $CODE_CONTEXT

  CHECKLIST:
  1. Security: Check for SQL Injection (especially in Repository calls), Hardcoded secrets, or Broken Access Control.
  2. SonarQube: Check for Code Smells, Cognitive Complexity, and naming conventions.
  3. Logic: Ensure the 'cancelBooking' logic is robust.

  OUTPUT: If safe, start your reply with 'APPROVED'. If there are issues, list them clearly starting with 'REJECTED'.")

# 4. Decide commit or not
if [[ "$REVIEW_RESULT" == *"APPROVED"* ]]; then
    echo "✅ AI Review Passed! Proceeding to Commit & Push..."

    git add .
    git commit -m "auto: Validated booking-service logic [AI Verified]"
    git push origin master

    echo "🚀 Pipeline Completed Successfully!"
else
    echo "❌ AI Review REJECTED: Issues found!"
    echo "-----------------------------------"
    echo "$REVIEW_RESULT"
    echo "-----------------------------------"
    echo "Please fix the issues before pushing."
    exit 1
fi
