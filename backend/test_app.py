from flask import Flask, request, jsonify
from flask_cors import CORS
import logging

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("TestApp")

app = Flask(__name__)
CORS(app)

@app.route("/health", methods=["GET"])
def health():
    return "ok", 200

@app.route("/analyze", methods=["POST"])
def analyze():
    data = request.get_json(force=True, silent=True)
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    text = data.get("text") or data.get("message") or ""
    if not text:
        return jsonify({"error": "text (message) is required"}), 400

    # Simple test logic - flag messages with certain keywords
    flag = 0
    tox_label = "Safe"
    tox_score = 0.0
    
    # Flag messages containing threatening or offensive words
    offensive_words = ["kill", "hurt", "die", "stupid", "idiot", "hate", "threat", "violence"]
    text_lower = text.lower()
    
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
        "id": data.get("id"),
        "sender": data.get("sender"),
        "timestamp": data.get("timestamp")
    }
    
    log.info(f"Analyzed: '{text}' -> flag={flag}")
    return jsonify(result), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
