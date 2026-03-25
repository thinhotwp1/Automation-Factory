import chromadb
import yaml
import re

# 1. Connect to the Vector Database running via Docker
client = chromadb.HttpClient(host='localhost', port=8000)

# Create or get the Collection (Similar to a Table in SQL)
# python -c "import chromadb; chromadb.HttpClient(host='localhost', port=8000).delete_collection('sia_knowledge_base')"
collection = client.get_or_create_collection(name="sia_knowledge_base")

def process_markdown_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # 2. Extract YAML Metadata and Text Content
    # Find the content block between the two --- lines
    parts = re.split(r'^---\s*$', content, flags=re.MULTILINE)

    if len(parts) >= 3:
        yaml_metadata = yaml.safe_load(parts[1])
        markdown_body = parts[2].strip()
    else:
        print("Error: Standard YAML Frontmatter not found.")
        return

    # 3. Chunking Technique (Split by ## Heading)
    # Split the article into smaller chunks for the AI to digest easily
    chunks = re.split(r'\n## ', markdown_body)

    documents = []
    metadatas = []
    ids = []

    # ChromaDB requires metadata values to be strings, numbers, or booleans. (Cast lists to strings)
    safe_metadata = {k: (",".join(v) if isinstance(v, list) else v) for k, v in yaml_metadata.items()}

    # Skip the first chunk (chunks[0]) which contains the main header / title.
    # Process only the following sections starting with '##'.
    for i, chunk in enumerate(chunks[1:], start=1):
        # Use Regex to extract the SIA-xxxxxx code from the first line of the chunk.
        # Example: "SIA-001002: Invariant Validation..." -> matches "SIA-001002".
        match = re.search(r'^(SIA-\d+)', chunk)

        if match:
            chunk_id = match.group(1) # Use SIA-001002 as the hard ID
        else:
            # Fallback if the chunk doesn't follow the standard format
            chunk_id = f"{yaml_metadata['id']}_unknown_{i}"

        # Create specific metadata for each chunk, inheriting from the main YAML
        chunk_metadata = safe_metadata.copy()
        chunk_metadata["sub_id"] = chunk_id  # Save sub_id for filtering purposes

        documents.append(f"## {chunk}".strip())
        metadatas.append(chunk_metadata)
        ids.append(chunk_id) # The ChromaDB ID is now SIA-xxxxxx

    if not documents:
        print(f"Warning: No valid sections found in {file_path} to insert.")
        return

    # 4. Ingestion (Use UPSERT instead of ADD)
    # Upsert will automatically overwrite new data if the ID exists, and add new if it doesn't
    collection.delete
    collection.upsert(
        documents=documents,
        metadatas=metadatas,
        ids=ids
    )
    print(f"✅ Successfully UPSERTED {len(documents)} chunks from {file_path} into the Vector DB!")

if __name__ == "__main__":
    process_markdown_file("spec/cancel-booking-flow.md")
