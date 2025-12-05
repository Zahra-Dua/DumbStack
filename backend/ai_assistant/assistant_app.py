from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from langchain_community.embeddings import SentenceTransformerEmbeddings
# NEW: use the google-genai client
from google import genai
from google.genai import types
from dotenv import load_dotenv
import os
import traceback

# -----------------------------
# Load environment variables
# -----------------------------
load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    raise ValueError("GEMINI_API_KEY not found in environment variables!")

# -----------------------------
# Configure Google Gen AI client
# -----------------------------
client = genai.Client(api_key=API_KEY, http_options=types.HttpOptions(api_version="v1"))

# -----------------------------
# Load saved embeddings
# -----------------------------
with open("embeddingschild.json", "r", encoding="utf-8") as f:
    saved_data = json.load(f)

documents = saved_data.get("documents", [])
embeddings = np.array(saved_data.get("embeddingschild", []), dtype=np.float32)

if len(documents) == 0 or embeddings.size == 0:
    raise ValueError("Documents or embeddings are empty!")

# -----------------------------
# Embedding model
# -----------------------------
embedding_model = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-v2")

# -----------------------------
# Flask app
# -----------------------------
app = Flask(__name__)
CORS(app)

@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok"}, 200

# -----------------------------
# AI Query Route (robust with traceback)
# -----------------------------
@app.route("/ai/query", methods=["POST"])
def ai_query():
    try:
        data = request.get_json(force=True)
        query = data.get("query", "").strip()
        if not query:
            return jsonify({"error": "Query text required"}), 400

        # Create query embedding
        query_embedding = np.array(embedding_model.embed_query(query), dtype=np.float32)

        # Compute cosine similarities
        sims = cosine_similarity([query_embedding], embeddings)[0]
        best_idx = int(np.argmax(sims))
        context = documents[best_idx]

        # Prepare prompt
        prompt = (
            f"User query: {query}\n\n"
            f"Matched context: {context}\n\n"
            "You are an assistant helping a parent."
        )

        # ✅ Use gemini-2.5-flash instead of gemini-pro
        response = client.models.generate_content(
            model="models/gemini-2.5-flash",
            contents=prompt
        )

        print("Gemini raw response object:", response)

        ai_text = getattr(response, "text", None)
        if ai_text is None:
            ai_text = str(response)

        return jsonify({"query": query, "context": context, "response": ai_text}), 200

    except Exception as e:
        print("🔥 FULL ERROR TRACEBACK:")
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# -----------------------------
# Run Flask app
# -----------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=6000, debug=True)
