#!/bin/bash

# ==========================================
# SIA Booking - Active AI Architect Pipeline
# ==========================================

# Check input parameters
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a test class name."
    echo "Usage: ./auto-implements.sh com.sia.booking.BookingServiceTest"
    exit 1
fi

TEST_CLASS=$1
# Convert package to file path (e.g., com.sia.booking.Test -> src/test/java/com/sia/booking/Test.java)
TEST_FILE_PATH="src/test/java/${TEST_CLASS//./\/}.java"

if [ ! -f "$TEST_FILE_PATH" ]; then
    echo "❌ Error: Test file not found at $TEST_FILE_PATH"
    exit 1
fi

echo "🔍 Analyzing Test Class: $TEST_CLASS"
TEST_CONTENT=$(cat "$TEST_FILE_PATH")

# Step 1: The Analyzer (Find ALL related files)
echo "🧠 Activating [AI Agent - The Analyzer]..."
ANALYSIS_SESSION="analyzer-$(date +%s)"

# Ask AI to return JSON on a single line
REQUIREMENTS=$(openclaw agent \
  --session-id "$ANALYSIS_SESSION" \
  --agent watcher \
  -m "Read this Test Class content:
  ---
  $TEST_CONTENT
  ---
  Task:
  1. Identify ALL target Source Files (e.g., Service, Repository, Entity, DTO) that must be modified or created to fulfill the test requirements.
  2. Extract requirements from JavaDocs and missing methods.
  Output ONLY a valid JSON. DO NOT output any markdown blocks (\`\`\`json), UI characters, or newlines. The output MUST be on a SINGLE LINE EXACTLY like this:
  {\"target_files\": [\"path/to/BookingService.java\", \"path/to/BookingRepository.java\"], \"requirements\": \"...\"}")

# Data Sanitization: Extract ONLY the JSON object from the AI output using awk
# This ignores any UI spinner characters or extra invisible text before/after the JSON
CLEAN_JSON=$(echo "$REQUIREMENTS" | awk 'match($0, /\{.*\}/) {print substr($0, RSTART, RLENGTH)}')

# Use jq to parse the cleaned JSON
TARGET_FILES=$(echo "$CLEAN_JSON" | jq -r '.target_files[]' 2>/dev/null)
REQ_DETAILS=$(echo "$CLEAN_JSON" | jq -r '.requirements' 2>/dev/null)

if [ -z "$TARGET_FILES" ] || [ "$TARGET_FILES" == "null" ]; then
    echo "⚠️ Target source files not found or jq failed to parse JSON."
    echo "Raw CLEAN_JSON output:"
    echo "$CLEAN_JSON"
    exit 1
fi

echo "🔧 Target Files Identified:"
echo "$TARGET_FILES"
echo "🛠️ Activating [AI Agent - The Fixer]..."

# Aggregate content from ALL identified files
SOURCE_CONTENTS=""
for FILE in $TARGET_FILES; do
    if [ -f "$FILE" ]; then
        SOURCE_CONTENTS+="\n=== FILE: $FILE ===\n\`\`\`java\n$(cat "$FILE")\n\`\`\`\n"
    else
        echo "⚠️ Warning: File $FILE does not exist yet. It will be created."
        SOURCE_CONTENTS+="\n=== FILE: $FILE ===\n(New File - Currently Empty)\n"
    fi
done

# Step 2: The Fixer (Implement across all files)
FIXER_SESSION="fixer-$(date +%s)"

openclaw agent \
  --session-id "$FIXER_SESSION" \
  --agent fixer \
  -m "You are a Senior Java Developer at SIA.
  Your task: Implement missing methods/logic across ALL related Source Files AND strictly update the Test Class.

  TARGET SOURCE FILES:
  $SOURCE_CONTENTS

  TARGET TEST FILE:
  === FILE: $TEST_FILE_PATH ===
  \`\`\`java
  $TEST_CONTENT
  \`\`\`

  REQUIREMENTS FROM TEST (JavaDoc/Methods):
  $REQ_DETAILS

  STRICT GUARDRAILS:
  1. MANDATORY: Implement all core business logic across ALL necessary Source Files. If the Service needs a new repository method (e.g., findByPnrCode), you MUST add it to the Repository file provided.
  2. MANDATORY: You MUST modify and improve the Test File ($TEST_FILE_PATH).
  3. OUTPUT FORMAT: You must output the updated code for ALL modified files (Source Files + Test File). Precede each code block with its exact file path to help the auto-parser.
  4. JPA RULE: Use Spring Data JPA efficient methods (findByPnrCode).
  5. Clean Code: Ensure the code is production-ready for SIA standards."

echo "✅ Implementation finished. Running Maven to verify..."
mvn -B test -Dtest=$TEST_CLASS

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! All methods in $TEST_CLASS are implemented and passed."
else
    echo "❌ Test still failing. Check logs for details."
    echo "Calling auto-fix agent..."
    ./auto-fix.sh
fi
