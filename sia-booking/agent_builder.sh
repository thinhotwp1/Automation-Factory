#!/bin/bash

# ==========================================
# SIA Booking - Spec-Driven AI Architect Pipeline (V3 - Enterprise Context)
# ==========================================

if [ -z "$1" ]; then
    echo "❌ Error: Please provide a Specification ID."
    echo "Usage: ./agent_builder.sh SIA-FEAT-000001 (Full Feature) OR SIA-FEAT-000001-01 (Specific Rule)"
    exit 1
fi

SPEC_ID=$1

# --- 1. LOGIC PHÂN LOẠI MỤC TIÊU (TARGETING LOGIC) ---
# Kiểm tra xem ID truyền vào có đuôi -XX (ví dụ: -01, -02) hay không
if [[ "$SPEC_ID" =~ -[0-9]{2}$ ]]; then
    BASE_ID=${SPEC_ID%-*} # Lấy phần đầu. VD: SIA-FEAT-000001
    TARGET_RULE=$SPEC_ID  # Chỉ đích danh SIA-FEAT-000001-01

    EXECUTION_SCOPE="FOCUS MODE: You are updating a SPECIFIC rule: ${TARGET_RULE}. Read the full specification for domain context, but you MUST ONLY generate or update the Java method annotated with @BusinessRule(\"${TARGET_RULE}\"). DO NOT modify other methods."
    echo "🎯 TARGET MODE: Updating specific rule [${TARGET_RULE}] within feature [${BASE_ID}]..."
else
    BASE_ID=$SPEC_ID      # VD: SIA-FEAT-000001
    TARGET_RULE=$SPEC_ID

    EXECUTION_SCOPE="FULL FEATURE MODE: Implement ALL business rules defined in the specification ${BASE_ID}. Create or update methods for every single rule mentioned."
    echo "🌐 FULL MODE: Implementing entire feature [${BASE_ID}]..."
fi


# --- 2. Activate [The Retriever] ---
echo "📚 Activating [The Retriever] to fetch Spec, Dictionaries, and Pruned Code..."

export CHROMA_TELEMETRY__ANONYMIZED=False
export ANONYMIZED_TELEMETRY=False

RAG_DATA=$(../rag/venv/bin/python -c "
import sys, json, os, chromadb
import re

os.environ['CHROMA_TELEMETRY__ANONYMIZED'] = 'False'

def extract_java_blocks(filepath, target_rule, base_id):
    if not os.path.exists(filepath):
        return f'// FILE NOT FOUND: {filepath}\\n// AI PLEASE GENERATE THIS FILE'

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if ' interface ' in content:
        return content

    # LOGIC CHA-CON MỚI
    if target_rule == base_id:
        # Full Mode: Tìm tất cả các hàm có dạng @BusinessRule(\"SIA-FEAT-000001-XX\")
        pattern = rf'@BusinessRule\(\"{base_id}-\d{{2}}\"\)'
    else:
        # Focus Mode: Tìm chính xác @BusinessRule(\"SIA-FEAT-000001-01\")
        pattern = rf'@BusinessRule\(\"{target_rule}\"\)'

    matches = list(re.finditer(pattern, content))

    if not matches:
        skeleton = re.sub(r'\{[^{}]*\}', '{}', content)
        return f'// SKELETON ONLY (No matching rules found for {target_rule})\\n{skeleton}'

    extracted_blocks = []
    class_sig_match = re.search(r'(public class .*?\{)', content)
    class_sig = class_sig_match.group(1) if class_sig_match else ''
    extracted_blocks.append(class_sig)

    for match in matches:
        idx = match.start()
        start_idx = content.find('{', idx)
        if start_idx == -1: continue

        brace_count = 0
        end_idx = start_idx
        for i in range(start_idx, len(content)):
            if content[i] == '{': brace_count += 1
            elif content[i] == '}': brace_count -= 1

            if brace_count == 0:
                end_idx = i + 1
                break

        extracted_blocks.append('    // ...')
        extracted_blocks.append('    ' + content[idx:end_idx])

    extracted_blocks.append('}')
    return '\\n'.join(extracted_blocks)

# --- MAIN LOGIC ---
try:
    client = chromadb.HttpClient(host='localhost', port=8000)
    collection = client.get_collection(name='sia_knowledge_base')
    base_id = '$BASE_ID'
    target_rule = '$TARGET_RULE'

    # 1. Fetch Main Spec (Lấy TẤT CẢ các chunk thuộc về base_id để AI có ngữ cảnh toàn cục)
    all_data = collection.get()
    matching_ids = [doc_id for doc_id in all_data['ids'] if doc_id.startswith(base_id)]

    if not matching_ids:
        print(json.dumps({'error': f'Specification {base_id} not found in Vector DB'}))
        sys.exit(0)

    results = collection.get(ids=matching_ids)

    # Sắp xếp các chunk theo thứ tự -01, -02, -03
    sorted_indices = sorted(range(len(results['ids'])), key=lambda k: results['ids'][k])
    main_docs = '\n\n'.join([results['documents'][i] for i in sorted_indices])

    # Lấy metadata từ chunk đầu tiên
    meta = results['metadatas'][sorted_indices[0]]

    # 2. Fetch Dictionaries (Từ field dictionary_dependencies mới)
    spec_deps_str = meta.get('dictionary_dependencies', '')
    spec_deps = [d.strip() for d in spec_deps_str.split(',')] if spec_deps_str else []

    dependent_docs = ''
    if spec_deps:
        dep_results = collection.get(ids=spec_deps)
        if dep_results and dep_results['documents']:
            dependent_docs = '\n\n--- REFERENCED DICTIONARIES ---\n' + '\n\n'.join(dep_results['documents'])

    # 3. Process Code Dependencies (Từ field bean_dependencies mới)
    code_deps_str = meta.get('bean_dependencies', '')
    code_deps = [d.strip() for d in code_deps_str.split(',')] if code_deps_str else []

    live_code_context = ''
    md_ticks = chr(96) * 3

    for dep in code_deps:
        if dep.startswith('SIA-'): continue
        file_path = 'src/main/java/' + dep.replace('.', '/') + '.java'
        pruned_code = extract_java_blocks(file_path, target_rule, base_id)
        live_code_context += f'\n=== FILE: {file_path} ===\n{md_ticks}java\n{pruned_code}\n{md_ticks}\n'

    # 4. Target Test File
    test_file = meta.get('target_test_file', '')
    if test_file and os.path.exists(test_file):
        with open(test_file, 'r') as f:
            live_code_context += f'\n=== TARGET TEST FILE: {test_file} ===\n{md_ticks}java\n{f.read()}\n{md_ticks}\n'
    elif test_file:
        live_code_context += f'\n=== TARGET TEST FILE: {test_file} ===\n// NEW FILE\n{md_ticks}java\n{md_ticks}\n'

    print(json.dumps({
        'spec_context': main_docs + '\n' + dependent_docs,
        'live_code_context': live_code_context,
        'test_file': test_file
    }))

except Exception as e:
    print(json.dumps({'error': str(e)}))
")

HAS_ERROR=$(echo "$RAG_DATA" | jq -r '.error // empty')
if [ ! -z "$HAS_ERROR" ]; then
    echo "❌ Database Error: $HAS_ERROR"
    exit 1
fi

SPEC_CONTEXT=$(echo "$RAG_DATA" | jq -r '.spec_context')
echo "SPEC_CONTEXT:\n $SPEC_CONTEXT"
LIVE_CODE_CONTEXT=$(echo "$RAG_DATA" | jq -r '.live_code_context')
echo "LIVE_CODE_CONTEXT:\n $LIVE_CODE_CONTEXT"

echo "   -> ✅ Context Assembled Successfully!"

# --- 3. Activate AI Builder Agent ---
INSTRUCTION_FILE="AI_INSTRUCTION.md"
INSTRUCTION_CONTENT=$(cat "$INSTRUCTION_FILE" 2>/dev/null || echo "Maintain Clean Architecture.")

echo "🛠️ Activating [AI Agent - The Builder]..."
BUILDER_SESSION="builder-$(date +%s)"

PROMP_CONTEXT= "ROLE: Java Architect.
                 TASK: Implement SPEC in LIVE_CODE adhering to RULES.

                 [EXECUTION SCOPE]
                 $EXECUTION_SCOPE

                 [RULES]
                 $INSTRUCTION_CONTENT

                 [SPEC & DEFINITIONS]
                 $SPEC_CONTEXT

                 [PRUNED LIVE CODE]
                 $LIVE_CODE_CONTEXT

                 [ZERO-TOLERANCE CONSTRAINTS]
                 1. MANDATORY ANNOTATION: The CI/CD pipeline will IMMEDIATELY FAIL if any method lacks the @BusinessRule annotation. You are FORBIDDEN from writing bare methods.
                 2. NO EXCUSES: Do NOT say 'the tests already cover this' or 'stay as-is'. You MUST output the complete Java code block including the annotations.
                 3. FORMAT TEMPLATE: Your output MUST strictly follow this exact visual structure:
                 // CORRECT EXAMPLE:
                 @BusinessRule({\"SIA-FEAT-000001-01\", \"SIA-FEAT-000001-02\"})
                 public boolean method(Param param) {
                     // business logic here...
                 }
                 4. OUTPUT ONLY CODE: Provide the exact file path header + FULL markdown java code block of the changes. No yapping. No conversational filler."
echo "$PROMP_CONTEXT"
openclaw agent \
  --session-id "$BUILDER_SESSION" \
  --agent fixer \
  -m "$PROMP_CONTEXT"

echo "✅ AI Implementation finished. Verifying with Maven..."
mvn -B test

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! All tests passed."
else
    echo "❌ Tests failed. Triggering Auto-Fix pipeline..."
    # ./agent-fixer.sh
fi
