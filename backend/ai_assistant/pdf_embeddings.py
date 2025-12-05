import os
import json
from dotenv import load_dotenv
from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings

# Load environment variables
load_dotenv()

# --- SETTINGS ---
PDF_FOLDER_PATH = "D:\\callRecord\\call_record\\backend\\ai_assistant\\pdfs"
   # apna pdf folder ka path
OUTPUT_FILE = "embeddingschild.json"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
CHUNK_SIZE = 500
CHUNK_OVERLAP = 50

def read_pdfs(directory):
    if not os.path.isdir(directory):
        raise FileNotFoundError(f"Directory not found: {directory}")

    loader = PyPDFDirectoryLoader(directory)
    documents = loader.load()
    return documents

def split_documents(documents, chunk_size=500, overlap=50):
    splitter = RecursiveCharacterTextSplitter(chunk_size=chunk_size, chunk_overlap=overlap)
    return splitter.split_documents(documents)

def create_embeddings(texts, model_name):
    embedder = HuggingFaceEmbeddings(model_name=model_name)
    return embedder.embed_documents(texts)

def main():
    print("Reading documents...")
    documents = read_pdfs(PDF_FOLDER_PATH)
    print(f"Loaded {len(documents)} documents.")

    print("Splitting documents...")
    chunks = split_documents(documents, chunk_size=CHUNK_SIZE, overlap=CHUNK_OVERLAP)
    print(f"Split into {len(chunks)} chunks.")

    texts = [doc.page_content for doc in chunks]

    print("Creating embeddings...")
    embeddings = create_embeddings(texts, model_name=EMBEDDING_MODEL)
    print(f"Generated {len(embeddings)} embeddings.")

    data_to_save = {
        "documents": texts,
        "embeddingschild": [list(e) for e in embeddings]
    }
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data_to_save, f, indent=4)

    print("✅ Embeddings saved successfully!")

if __name__ == "__main__":
    main()
