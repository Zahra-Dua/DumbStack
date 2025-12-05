# Simple test server for message analysis
from flask import Flask, request, jsonify
from flask_cors import CORS
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("SimpleTestServer")

# Initialize Flask app
app = Flask(__name__)
CORS(app)

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "message": "Simple test server running"}), 200

@app.route("/analyze", methods=["POST"])
def analyze():
    try:
        data = request.get_json(force=True, silent=True)
        if not data:
            return jsonify({"error": "JSON body required"}), 400

        text = data.get("text") or data.get("message") or ""
        if not text:
            return jsonify({"error": "Missing 'text' field"}), 400

        sender = data.get("sender", "unknown")
        ts = data.get("timestamp")
        msg_id = data.get("id")

        log.info(f"📩 Received message → '{text}' from {sender}")

        # Simple test logic - flag messages with certain keywords
        flag = 0
        tox_label = "Safe"
        tox_score = 0.0
        
        # Flag messages containing threatening or offensive words
        offensive_words = ["kill", "hurt", "die", "stupid", "idiot", "hate", "threat", "violence", "bad", "dangerous"]
        harassment_words = ["harassment", "harass", "bully", "bullying", "abuse", "abusive", "harami", "madarchod", "behenchod", "chutiya", "gandu", "bhenchod"]
        text_lower = text.lower()
        
        # Check for harassment words first
        for word in harassment_words:
            if word in text_lower:
                flag = 1
                tox_label = "Harassment"
                tox_score = 0.95
                break
        
        # If no harassment found, check for general offensive words
        if flag == 0:
            for word in offensive_words:
                if word in text_lower:
                    flag = 1
                    tox_label = "Toxic"
                    tox_score = 0.9
                    break

        result = {
            "flag": flag,
            "tox_label": tox_label,
            "tox_score": tox_score,
            "similarity_score": 0.0,
            "id": msg_id,
            "sender": sender,
            "timestamp": ts
        }

        log.info(f"✅ Analysis Complete → {result}\n")
        return jsonify(result), 200

    except Exception as e:
        log.exception("❌ Error during /analyze request:")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print("🚀 Starting Simple Test Server...")
    print("📡 Server will run on http://0.0.0.0:5000")
    print("🔍 Health check: http://127.0.0.1:5000/health")
    print("🧠 Analysis endpoint: http://127.0.0.1:5000/analyze")
    app.run(host="0.0.0.0", port=5000, debug=True)

