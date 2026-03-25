#!/bin/bash

# ==========================================
# SIA Booking - Active AI Architect Pipeline
# ==========================================

# Kiểm tra tham số đầu vào
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a test class name."
    echo "Usage: ./auto-implements.sh com.sia.booking.BookingServiceTest"
    exit 1
fi

TEST_CLASS=$1
# Chuyển đổi package sang đường dẫn file (ví dụ: com.sia.booking.Test -> src/test/java/com/sia/booking/Test.java)
TEST_FILE_PATH="src/test/java/${TEST_CLASS//./\/}.java"

if [ ! -f "$TEST_FILE_PATH" ]; then
    echo "❌ Error: Test file not found at $TEST_FILE_PATH"
    exit 1
fi

echo "🔍 Analyzing Test Class: $TEST_CLASS"
TEST_CONTENT=$(cat "$TEST_FILE_PATH")

# Step 1: The Analyzer (Trích xuất yêu cầu từ JavaDoc và Method Signatures trong Test)
echo "🧠 Activating [AI Agent - The Analyzer]..."
ANALYSIS_SESSION="analyzer-$(date +%s)"

# Yêu cầu AI tìm ra file source cần sửa và các method cần implement
REQUIREMENTS=$(openclaw agent \
  --session-id "$ANALYSIS_SESSION" \
  --agent watcher \
  -m "Read this Test Class content:
  ---
  $TEST_CONTENT
  ---
  Task:
  1. Identify the target Source File (e.g., src/main/java/.../BookingService.java) being tested.
  2. Extract requirements from JavaDocs and missing methods that cause compilation/logic errors.
  Output ONLY a valid JSON: {\"target_file\": \"path/to/Source.java\", \"requirements\": \"...\"}")

TARGET_FILE=$(echo "$REQUIREMENTS" | grep -o '{"target_file".*' | jq -r '.target_file')
REQ_DETAILS=$(echo "$REQUIREMENTS" | grep -o '{"target_file".*' | jq -r '.requirements')


if [ "$TARGET_FILE" == "null" ] || [ ! -f "$TARGET_FILE" ]; then
    echo "⚠️ Target source file not found or AI failed to identify it."
    exit 1
fi

echo "🔧 Target File: $TARGET_FILE"
echo "🛠️ Activating [AI Agent - The Fixer]..."

# Step 2: The Fixer (o3-mini / gpt-4) - Thực hiện implement logic
SOURCE_CONTENT=$(cat "$TARGET_FILE")
FIXER_SESSION="fixer-$(date +%s)"

openclaw agent \
  --session-id "$FIXER_SESSION" \
  --agent fixer \
  -m "You are a Senior Java Developer at SIA.
  Your task: Implement missing methods/logic in the Source File AND strictly update the Test Class to cover new edge cases.

  TARGET SOURCE FILE: $TARGET_FILE
  SOURCE CONTENT:
  \`\`\`java
  $SOURCE_CONTENT
  \`\`\`

  TARGET TEST FILE: $TEST_FILE_PATH
  TEST CONTENT:
  \`\`\`java
  $TEST_CONTENT
  \`\`\`

  REQUIREMENTS FROM TEST (JavaDoc/Methods):
  $REQ_DETAILS

  STRICT GUARDRAILS:
  1. MANDATORY: Implement all core business logic in $TARGET_FILE.
  2. MANDATORY: You MUST modify and improve the Test File ($TEST_FILE_PATH). Do not skip this step. You must add at least 2 new test methods for edge cases (e.g., invalid PNR format, booking not found) to ensure perfect alignment with your implementation.
  3. OUTPUT: You must output the updated code for BOTH the Source File and the Test File.
  4. JPA RULE: Use Spring Data JPA efficient methods (findByPnrCode).
  5. Clean Code: Ensure the code is production-ready for SIA standards."

echo "✅ Implementation finished. Running Maven to verify..."
mvn -B test -Dtest=$TEST_CLASS

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! All methods in $TEST_CLASS are implemented and passed."
else
    echo "❌ Test still failing. Check logs for details."
    echo "Calling to auto_fixed agent"
    ./auto-fix.sh
fi
