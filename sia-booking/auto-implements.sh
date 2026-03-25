#!/bin/bash

# ==========================================
# SIA Booking - Active AI Architect Pipeline (with RAG)
# ==========================================

# Check input parameters
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a test class name."
    echo "Usage: ./auto-implements.sh com.sia.booking.BookingServiceTest"
    exit 1
fi

TEST_CLASS=$1
# Convert package to file path
TEST_FILE_PATH="src/test/java/${TEST_CLASS//./\/}.java"

if [ ! -f "$TEST_FILE_PATH" ]; then
    echo "❌ Error: Test file not found at $TEST_FILE_PATH"
    exit 1
fi

echo "🔎 Scanning $TEST_CLASS for unimplemented methods..."

# 1. Tìm xem có hàm nào trống không
HAS_UNIMPLEMENTED=$(perl -0777 -ne 'print "1" if /@Test[\s\n]*(?:@[A-Za-z0-9_]+[\s\n]*)*void\s+[A-Za-z0-9_]+\s*\([^)]*\)\s*\{\s*(?:\/\/.*?\s*|\/\*[\s\S]*?\*\/\s*)*\}/' "$TEST_FILE_PATH")

if [ "$HAS_UNIMPLEMENTED" != "1" ]; then
    echo "✅ No unimplemented test methods found in $TEST_CLASS. All tests seem complete."
    echo "⏭️ Skipping AI Analysis to save tokens."
    exit 0
fi

echo "💡 Found unimplemented test methods! Proceeding to AI Agent Analysis..."

# 2. RAG RETRIEVAL (MỚI) - Móc tên hàm và gọi Vector DB
echo "📚 Activating [The Retriever] to fetch Domain Knowledge from Vector DB..."
RAG_CONTEXT=""

# Dùng Perl trích xuất chính xác tên các hàm đang trống
UNIMPLEMENTED_METHODS=$(perl -0777 -ne 'while (/@Test[\s\n]*(?:@[A-Za-z0-9_]+[\s\n]*)*void\s+([A-Za-z0-9_]+)\s*\([^)]*\)\s*\{\s*(?:\/\/.*?\s*|\/\*[\s\S]*?\*\/\s*)*\}/g) { print "$1\n" }' "$TEST_FILE_PATH")

for METHOD in $UNIMPLEMENTED_METHODS; do
    echo "   -> 🔍 Searching knowledge for method: $METHOD"

    # Gọi sang thư mục /rag để lấy data. Bỏ qua các lỗi log rác bằng 2>/dev/null
    KNOWLEDGE=$(../rag/venv/bin/python ../rag/rag_search.py "$METHOD" 2>/dev/null)

    if [ ! -z "$KNOWLEDGE" ]; then
            echo "   -> ✅ Found business rules for $METHOD!"
            echo "   --------------------------------------------------"
            echo "$KNOWLEDGE"
            echo "   --------------------------------------------------"

            RAG_CONTEXT+="\n[Domain Knowledge for $METHOD]:\n$KNOWLEDGE\n"
#            exit 1
        else
            echo "   -> ⚠️ No specific rules found for $METHOD."
        fi
done

if [ -z "$RAG_CONTEXT" ]; then
    RAG_CONTEXT="No specific business rules retrieved from local database. Rely on general best practices."
fi

# 3. Phân tích file (The Analyzer)
echo "🔍 Analyzing Test Class: $TEST_CLASS"
TEST_CONTENT=$(cat "$TEST_FILE_PATH")
INSTRUCTION_FILE="AI_INSTRUCTION.md"

if [ -f "$INSTRUCTION_FILE" ]; then
    echo "🗺️ Loading Architecture Map from $INSTRUCTION_FILE..."
    INSTRUCTION_CONTENT=$(cat "$INSTRUCTION_FILE")
else
    echo "❌ Error: $INSTRUCTION_FILE not found."
    exit 1
fi

echo "🧠 Activating [AI Agent - The Analyzer]..."
ANALYSIS_SESSION="analyzer-$(date +%s)"

REQUIREMENTS=$(openclaw agent \
  --session-id "$ANALYSIS_SESSION" \
  --agent watcher \
  -m "You are a Senior System Analyst for SIA.
  Read the Architecture Map and the Test Class content below.

  === ARCHITECTURE MAP & GUIDELINES ===
  $INSTRUCTION_CONTENT

  === TEST CLASS CONTENT ===
  $TEST_CONTENT

  Task:
  1. Identify ALL target Source Files (Service, Repository, Entity, DTO) that must be modified or created to fulfill the test requirements.
  2. PATH RESOLUTION: You MUST strictly use the directory structure defined in the ARCHITECTURE MAP to construct the exact file paths.
  3. Extract requirements from JavaDocs and missing methods.

  Output ONLY a valid JSON. DO NOT output any markdown blocks (\`\`\`json), UI characters, or newlines. The output MUST be on a SINGLE LINE EXACTLY like this:
  {\"target_files\": [\"src/main/java/com/sia/booking/service/BookingService.java\"], \"requirements\": \"...\"}")

CLEAN_JSON=$(echo "$REQUIREMENTS" | awk 'match($0, /\{.*\}/) {print substr($0, RSTART, RLENGTH)}')
TARGET_FILES=$(echo "$CLEAN_JSON" | jq -r '.target_files[]' 2>/dev/null)
REQ_DETAILS=$(echo "$CLEAN_JSON" | jq -r '.requirements' 2>/dev/null)

if [ -z "$TARGET_FILES" ] || [ "$TARGET_FILES" == "null" ]; then
    echo "⚠️ Target source files not found or jq failed to parse JSON."
    exit 1
fi

echo "🔧 Target Files Identified:"
echo "$TARGET_FILES"

SOURCE_CONTENTS=""
for FILE in $TARGET_FILES; do
    if [ -f "$FILE" ]; then
        SOURCE_CONTENTS+="\n=== FILE: $FILE ===\n\`\`\`java\n$(cat "$FILE")\n\`\`\`\n"
    else
        echo "⚠️ Warning: File $FILE does not exist yet. It will be created."
        SOURCE_CONTENTS+="\n=== FILE: $FILE ===\n(New File - Currently Empty)\n"
    fi
done

# 4. Viết Code với RAG Context (The Builder)
echo "🛠️ Activating [AI Agent - The Builder] with RAG Context..."
BUILDER_SESSION="builder-$(date +%s)"

openclaw agent \
  --session-id "$BUILDER_SESSION" \
  --agent fixer \
  -m "You are a Senior Java Developer at SIA.
  Your task: Implement missing methods/logic across ALL related Source Files AND strictly update the Test Class.

  === RETRIEVED BUSINESS KNOWLEDGE (RAG) ===
  YOU MUST STRICTLY FOLLOW THESE RULES:
  $RAG_CONTEXT
  ==========================================

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
  1. MANDATORY: Implement all core business logic complying with the RETRIEVED BUSINESS KNOWLEDGE above.
  2. MANDATORY: You MUST modify and improve the Test File ($TEST_FILE_PATH). Don't create new test method if not required.
  3. OUTPUT FORMAT: You must output the updated code for ALL modified files. Precede each block with its exact file path.
  4. JPA RULE: Use Spring Data JPA efficient methods.
  5. Clean Code: Ensure the code is production-ready for SIA standards."

echo "✅ Implementation finished. Running Maven to verify the entire project..."
mvn -B test

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! All tests in the project passed. The new implementation for $TEST_CLASS is safe and integrated well."
else
    echo "❌ Tests failed. Checking logs and triggering Auto-Fix..."
    ./auto-fix.sh
fi
