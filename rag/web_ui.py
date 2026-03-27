import streamlit as st
import chromadb
import pandas as pd
import re

# 1. Page Configuration
st.set_page_config(page_title="SIA RAG Dashboard", layout="wide")
st.title("🗄️ SIA ChromaDB Admin Dashboard - Vector Database")

# 2. Connect to Vector DB
client = chromadb.HttpClient(host='localhost', port=8000)
collection = client.get_collection(name="sia_knowledge_base")

# 3. Fetch Data
data = collection.get()
total_records = len(data['ids'])

st.success(f"Connected successfully! Total knowledge chunks: {total_records}")

# Extract unique domains and categories from metadata for the filter dropdowns
domains = ["All"]
categories = ["All"]
if total_records > 0:
    unique_domains = set(meta.get('domain') for meta in data['metadatas'] if meta and 'domain' in meta)
    unique_categories = set(meta.get('category') for meta in data['metadatas'] if meta and 'category' in meta)
    domains.extend(sorted(list(unique_domains)))
    categories.extend(sorted(list(unique_categories)))

# 4. Test Search Interface
st.subheader("🔍 Test Vector & Exact Search")

# Create a 3-column layout for the search bar and filters
col1, col2, col3 = st.columns(3)
with col1:
    # Update hint text to reflect new ID format
    search_query = st.text_input("Enter a query (e.g., Happy Path) OR exact ID (e.g., SIA-FEAT-000001):")
with col2:
    selected_domain = st.selectbox("Filter by Domain:", domains)
with col3:
    selected_category = st.selectbox("Filter by Category:", categories)

# Execute search only if a text query is provided
if search_query:
    query_text = search_query.strip().upper() # Normalize to uppercase for ID matching

    # ---------------------------------------------------------
    # ROUTING LOGIC: Exact ID vs Semantic Vector Search
    # ---------------------------------------------------------
    # MỚI: Regex bắt chuẩn định dạng SIA-FEAT-000001 hoặc SIA-FEAT-000001-01, SIA-DICT-000001
    if re.match(r'^SIA-[A-Z]+-\d{6}(?:-\d{2})?$', query_text):
        # 1. EXACT ID FETCH (With Parent-Child Support)
        st.info(f"💡 Detect exact ID format. Fetching {query_text} directly from database...")
        try:
            # Lấy toàn bộ ID hiện có và lọc những ID bắt đầu bằng query_text
            # Điều này giúp gõ SIA-FEAT-000001 sẽ ra cả 01, 02, 03
            all_ids = data['ids']
            matching_ids = [doc_id for doc_id in all_ids if doc_id.startswith(query_text)]

            if matching_ids:
                results = collection.get(ids=matching_ids)
                st.success(f"Found {len(matching_ids)} chunk(s) belonging to {query_text}")

                # Sắp xếp để hiển thị theo thứ tự 01, 02, 03
                sorted_indices = sorted(range(len(results['ids'])), key=lambda k: results['ids'][k])

                for i in sorted_indices:
                    doc = results['documents'][i]
                    metadata = results['metadatas'][i]
                    chunk_id = results['ids'][i]

                    with st.expander(f"Result (Exact Match) | Chunk ID: {chunk_id}", expanded=True):
                        st.caption(f"**Domain:** {metadata.get('domain', 'N/A')} | **Category:** {metadata.get('category', 'N/A')}")
                        st.markdown(doc)
            else:
                st.warning(f"No exact match found for ID: {query_text}")
        except Exception as e:
            st.error(f"Error fetching ID: {e}")

    else:
        # 2. SEMANTIC VECTOR SEARCH
        # Construct the metadata filter (where clause) based on user selection
        where_clause = None
        conditions = []

        if selected_domain != "All":
            conditions.append({"domain": selected_domain})
        if selected_category != "All":
            conditions.append({"category": selected_category})

        if len(conditions) == 1:
            where_clause = conditions[0]
        elif len(conditions) > 1:
            where_clause = {"$and": conditions}

        query_params = {
            "query_texts": [query_text],
            "n_results": 3
        }
        if where_clause:
            query_params["where"] = where_clause

        try:
            results = collection.query(**query_params)

            if results['documents'] and results['documents'][0]:
                st.info(f"Top {len(results['documents'][0])} contexts retrieved via Vector Search:")

                for i in range(len(results['documents'][0])):
                    doc = results['documents'][0][i]
                    distance = results['distances'][0][i]
                    metadata = results['metadatas'][0][i]
                    chunk_id = results['ids'][0][i]

                    with st.expander(f"Result #{i+1} | ID: {chunk_id} | Distance Score: {distance:.4f}", expanded=True):
                        st.caption(f"**Domain:** {metadata.get('domain', 'N/A')} | **Category:** {metadata.get('category', 'N/A')}")
                        st.markdown(doc)
            else:
                st.warning("No results matched your search query and filters.")
        except Exception as e:
            st.error(f"Search failed. Error details: {e}")

# 5. Database Explorer Interface
st.subheader("📦 Database Explorer")
if total_records > 0:
    # CẬP NHẬT: Thay đổi các cột hiển thị để phù hợp với metadata mới (dictionary_dependencies, bean_dependencies)
    df = pd.DataFrame({
        "Chunk ID": data['ids'],
        "Domain": [meta.get('domain', 'N/A') for meta in data['metadatas']],
        "Category": [meta.get('category', 'N/A') for meta in data['metadatas']],
        "Dict Deps": [meta.get('dictionary_dependencies', '') for meta in data['metadatas']],
        "Bean Deps": [meta.get('bean_dependencies', '') for meta in data['metadatas']],
        "Content": [doc[:150] + "..." if len(doc) > 150 else doc for doc in data['documents']] # Cắt ngắn nội dung cho gọn bảng
    })

    # Sắp xếp bảng theo Chunk ID cho dễ nhìn
    df = df.sort_values(by="Chunk ID").reset_index(drop=True)
    st.dataframe(df, use_container_width=True)
else:
    st.warning("Database is currently empty!")
