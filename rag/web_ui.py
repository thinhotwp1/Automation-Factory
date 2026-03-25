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
    search_query = st.text_input("Enter a query (e.g., Happy Path) OR exact ID (e.g., SIA-001001):")
with col2:
    selected_domain = st.selectbox("Filter by Domain:", domains)
with col3:
    selected_category = st.selectbox("Filter by Category:", categories)

# Execute search only if a text query is provided
if search_query:
    query_text = search_query.strip()

    # ---------------------------------------------------------
    # ROUTING LOGIC: Exact ID vs Semantic Vector Search
    # ---------------------------------------------------------
    if re.match(r'^SIA-\d+$', query_text, re.IGNORECASE):
        # 1. EXACT ID FETCH
        st.info("💡 Detect exact ID format. Using Database Fetch instead of Vector Search...")
        try:
            #  collection.get() to get exactly
            results = collection.get(ids=[query_text])

            if results and results['documents'] and len(results['documents']) > 0:
                doc = results['documents'][0]
                metadata = results['metadatas'][0]

                with st.expander(f"Result (Exact Match) | Chunk ID: {query_text}", expanded=True):
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

                    with st.expander(f"Result #{i+1} | Distance Score: {distance:.4f} (Smaller is better)", expanded=True):
                        st.caption(f"**Domain:** {metadata.get('domain', 'N/A')} | **Category:** {metadata.get('category', 'N/A')}")
                        st.markdown(doc)
            else:
                st.warning("No results matched your search query and filters.")
        except Exception as e:
            st.error(f"Search failed. Error details: {e}")

# 5. Database Explorer Interface
st.subheader("📦 Database Explorer")
if total_records > 0:
    # Convert JSON data to a beautiful DataFrame (Table)
    df = pd.DataFrame({
        "Chunk ID": data['ids'],
        "Domain": [meta.get('domain', 'N/A') for meta in data['metadatas']],
        "Category": [meta.get('category', 'N/A') for meta in data['metadatas']],
        "Tags": [meta.get('tags', '') for meta in data['metadatas']],
        "Content": data['documents']
    })
    st.dataframe(df, use_container_width=True)
else:
    st.warning("Database is currently empty!")
