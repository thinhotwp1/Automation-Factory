#!/bin/bash

# ==========================================
# SIA Booking Service - Auto Healing Pipeline
# ==========================================

echo "🚀 Starting Maven Build..."

# Run Maven test and capture the full output to a temporary file
mvn -B clean test > full_build.log 2>&1
BUILD_STATUS=$?

# If build succeeds, exit cleanly
if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ BUILD SUCCESS! No AI intervention needed."
    rm full_build.log
    exit 0
fi

echo "❌ BUILD FAILED! Extracting errors and activating [AI Agent - The Watcher]..."

# Extract only the ERROR lines and a few context lines to save LLM tokens
grep -A 30 "\[ERROR\]" full_build.log > error_log.txt

# Create a unique Session ID to guarantee zero context leakage (Token FinOps)
WATCHER_SESSION="watcher-$(date +%s)"

# Step 1: The Watcher analyzes the pruned error log
ERROR_SUMMARY=$(openclaw agent \
  --session-id "$WATCHER_SESSION" \
  -m "Read error_log.txt. Find the compilation or test error. Output ONLY a valid JSON string like this: {\"file\": \"src/.../BookingService.java\", \"error\": \"cannot find symbol method...\"}. Do NOT output any markdown blocks or explanations.")

# Parse the JSON string safely
FILE_TO_FIX=$(echo "$ERROR_SUMMARY" | grep -o '{"file".*' | jq -r '.file')
ERROR_MSG=$(echo "$ERROR_SUMMARY" | grep -o '{"file".*' | jq -r '.error')

if [ "$FILE_TO_FIX" == "null" ] || [ -z "$FILE_TO_FIX" ]; then
    echo "⚠️ Watcher failed to parse JSON. Raw AI Output: $ERROR_SUMMARY"
    echo "Manual inspection required."
    exit 1
fi

echo "🔍 Error detected in file: $FILE_TO_FIX"
echo "🔧 Activating [AI Agent - The Fixer] to patch the code..."

# Step 2: The Fixer implements the solution with Strict Guardrails
FIXER_SESSION="fixer-$(date +%s)"

openclaw agent \
  --session-id "$FIXER_SESSION" \
  -m "You are a Senior Java Developer fixing a compilation/test error.
  Target File indicated by Watcher: $FILE_TO_FIX
  Error: $ERROR_MSG

  CRITICAL RULES (GUARDRAILS):
  1. Your goal is to implement the missing logic to make the test pass.
  2. FORBIDDEN: You MUST NOT modify any files in the 'src/test/' directory.
  3. MANDATORY: You MUST modify the corresponding source code in 'src/main/java/...' to resolve the error.
  4. Ensure the syntax is completely correct. Do not touch any other files."

echo "♻️ Fix applied! Restarting validation loop (Recursion)..."
./auto-work.sh
