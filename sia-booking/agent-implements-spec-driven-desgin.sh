#!/bin/bash

# ==========================================
# SIA Booking - Spec-Driven AI Architect Pipeline
# ==========================================

# 1. Check input parameters
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a Specification ID."
    echo "Usage: ./auto-implements.sh SIA-001000 (Full Feature) OR SIA-001001 (Specific Rule)"
    exit 1
fi

SPEC_ID=$1
echo "🔎 Initiating Spec-Driven Generation for ID: $SPEC_ID..."

# 2. Fetch Domain Knowledge & Metadata from Vector DB
echo "📚 Activating [The Retriever] to fetch Specification and Metadata..."

# We use an inline Python script to query ChromaDB safely and output a clean JSON
RAG_DATA=$(../rag/venv/bin/python -c "
import sys, json, chromadb
try:
    client = chromadb.HttpClient(host='localhost', port=8000)
    collection = client.get_collection(name='sia_knowledge_base')
    spec_id = '$SPEC_ID'

    # Logic: If ID ends with '000', it's a Parent ID -> Fetch all child chunks
    # Otherwise, it's a specific Child ID -> Fetch exact chunk ID
    if spec_id.endswith('000'):
        results = collection.get(where={'id': spec_id})
    else:
        results = collection.get(ids=[spec_id])

    if not results or not results['documents']:
        print(json.dumps({'error': 'Specification ID not found in Vector DB'}))
        sys.exit(0)

    # Combine text if there are multiple chunks (e.g., SIA-001000)
    docs = '\n\n'.join(results['documents'])

    # Extract metadata from the first chunk (all chunks share the same root metadata)
    meta = results['metadatas'][0]

    # Process comma-separated dependencies into a list
    deps = meta.get('dependencies', '')
    if isinstance(deps, str):
        deps = [d.strip() for d in deps.split(',') if d.strip()]

    # Output structured JSON
    print(json.dumps({
        'context': docs,
        'test_file': meta.get('target_test_file', ''),
        'dependencies': deps
    }))
except Exception as e:
    print(json.dumps({'error': str(e)}))
")

# Check if Python script returned an error
HAS_ERROR=$(echo "$RAG_DATA" | jq -r '.error // empty')
if [ ! -z "$HAS_ERROR" ]; then
    echo "❌ Database Error: $HAS_ERROR"
    exit 1
fi

# Parse JSON data using jq
RAG_CONTEXT=$(echo "$RAG_DATA" | jq -r '.context')
TEST_FILE_PATH=$(echo "$RAG_DATA" | jq -r '.test_file')
# Parse JSON array into bash array/list
DEPS_LIST=$(echo "$RAG_DATA" | jq -r '.dependencies[]')

echo "   -> ✅ Knowledge retrieved successfully!"
echo "   --------------------------------------------------"
echo "$RAG_CONTEXT"
echo "   --------------------------------------------------"

# 3. Assemble Live Code Context (Read physical files based on metadata)
echo "📂 Assembling Live Code Context..."
LIVE_CODE_CONTEXT=""

# 3.1 Attach Target Test File
if [ -f "$TEST_FILE_PATH" ]; then
    echo "   -> 📎 Attached Existing Test File: $TEST_FILE_PATH"
    CLEAN_TEST=$(grep -v '^\s*//' "$TEST_FILE_PATH" | grep -v '^\s*$')
    LIVE_CODE_CONTEXT+="\n=== FILE: $TEST_FILE_PATH ===\n\`\`\`java\n$CLEAN_TEST\n\`\`\`\n"
else
    echo "   -> ⚠️ Test File not found. AI will generate it at: $TEST_FILE_PATH"
    LIVE_CODE_CONTEXT+="\n=== FILE: $TEST_FILE_PATH ===\n// NEW FILE - PLEASE IMPLEMENT TEST CASES HERE\n\`\`\`java\n\`\`\`\n"
fi

# 3.2 Attach Source Dependencies
for DEP in $DEPS_LIST; do
    FILE_PATH="src/main/java/${DEP//./\/}.java"
    if [ -f "$FILE_PATH" ]; then
        echo "   -> 📎 Attached Source File: $FILE_PATH"
        CLEAN_CODE=$(grep -v '^\s*//' "$FILE_PATH" | grep -v '^\s*$')
        LIVE_CODE_CONTEXT+="\n=== FILE: $FILE_PATH ===\n\`\`\`java\n$CLEAN_CODE\n\`\`\`\n"
    else
        echo "   -> ⚠️ Source File not found. AI will generate it at: $FILE_PATH"
        LIVE_CODE_CONTEXT+="\n=== FILE: $FILE_PATH ===\n// NEW FILE - PLEASE IMPLEMENT LOGIC HERE\n\`\`\`java\n\`\`\`\n"
    fi
done

# 4. Load Global Architecture Rules
INSTRUCTION_FILE="AI_INSTRUCTION.md"
if [ -f "$INSTRUCTION_FILE" ]; then
    echo "🗺️ Loading Architecture Constitution from $INSTRUCTION_FILE..."
    INSTRUCTION_CONTENT=$(cat "$INSTRUCTION_FILE")
else
    echo "❌ Error: $INSTRUCTION_FILE not found."
    exit 1
fi

# 5. Activate AI Builder Agent
echo "🛠️ Activating [AI Agent - The Builder]..."
BUILDER_SESSION="builder-$(date +%s)"

openclaw agent \
  --session-id "$BUILDER_SESSION" \
  --agent fixer \
  -m "ROLE: SIA Java Architect.
TASK: Implement SPEC in LIVE_CODE adhering to RULES.

[RULES]
$INSTRUCTION_CONTENT

[SPEC]
$RAG_CONTEXT

[LIVE_CODE]
$LIVE_CODE_CONTEXT

[CONSTRAINTS]
1. TRACEABILITY (CRITICAL): You MUST map the SPEC rules to the Java test methods using the @BusinessRule(\"SIA-XXXXXX\") annotation.
   - UPDATE MODE: If you see an existing method in LIVE_CODE annotated with @BusinessRule matching the specific SPEC ID, you MUST modify that existing method. DO NOT create duplicate methods.
   - CREATE MODE: If the SPEC ID does not exist in the file, create a new method and annotate it.
2. Keep exact file paths from LIVE_CODE. No inventing.
3. OUTPUT: Exact file path header + FULL markdown java code block.
4. Minimal intrusion: Append or modify only the requested features. Do not rewrite unrelated methods."

echo "✅ AI Implementation finished. Running Maven to verify the entire project..."
mvn -B test

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! All tests passed. The specification has been successfully integrated."
else
    echo "❌ Tests failed. Triggering Auto-Fix pipeline..."
    ./auto-fix.sh
fi
