import chromadb
import yaml
import re
import os

# 1. Connect to the Vector Database running via Docker
client = chromadb.HttpClient(host='localhost', port=8000)

# Create or get the Collection
collection = client.get_or_create_collection(name="sia_knowledge_base")

def process_markdown_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # 2. Extract YAML Metadata and Text Content
    parts = re.split(r'^---\s*$', content, flags=re.MULTILINE)

    if len(parts) >= 3:
        yaml_metadata = yaml.safe_load(parts[1])
        markdown_body = parts[2].strip()
    else:
        print(f"⚠️ Error: Standard YAML Frontmatter not found in {file_path}")
        return

    # 3. Chunking Technique (Split by ## Heading)
    # Using (?m)^## to match ## at the start of a line, handling multi-line strings better
    chunks = re.split(r'(?m)^## ', markdown_body)

    documents = []
    metadatas = []
    ids = []

    # ChromaDB requires metadata values to be strings, numbers, or booleans.
    safe_metadata = {}
    for k, v in yaml_metadata.items():
        if isinstance(v, list):
            safe_metadata[k] = ",".join(v)
        elif v is None:
            safe_metadata[k] = ""
        else:
            safe_metadata[k] = v

    # Iterate through chunks
    for i, chunk in enumerate(chunks):
        chunk = chunk.strip()
        if not chunk:
            continue

        # Regex update: Capture formats like "SIA-FEAT-000001-01" or "SIA-DICT-000001"
        match = re.search(r'^(SIA-[A-Z]+-\d{6}(?:-\d{2})?)', chunk)

        if match:
            chunk_id = match.group(1) # Uses exact ID from the header
        else:
            # Skip chunks that don't start with a proper ID (like the main # Title chunk)
            continue

        chunk_metadata = safe_metadata.copy()
        chunk_metadata["sub_id"] = chunk_id

        # Re-add the ## that was removed during the split
        documents.append(f"## {chunk}")
        metadatas.append(chunk_metadata)
        ids.append(chunk_id)

    if not documents:
        print(f"⚠️ Warning: No valid ID sections found in {file_path}. Skipping.")
        return

    # 4. Ingestion (Use UPSERT instead of ADD)
    collection.upsert(
        documents=documents,
        metadatas=metadatas,
        ids=ids
    )
    print(f"✅ Successfully UPSERTED {len(documents)} chunks from {os.path.basename(file_path)}!")

def process_all_markdowns(directory):
    print(f"🔍 Scanning directory: {directory} for Markdown files...")
    file_count = 0
    # os.walk will recursively search through all folders and subfolders
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                process_markdown_file(file_path)
                file_count += 1
    print(f"🎉 Ingestion Complete! Processed {file_count} files.")

if __name__ == "__main__":
    # Ensure you have a 'docs' folder in the same directory, or provide the correct path
    process_all_markdowns("docs")
