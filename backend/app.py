# D:\parental-control-main\backend\app.py

from flask import Flask, request, jsonify
from flask_cors import CORS
from toxic_checker import ToxicChecker
import logging

# -----------------------------------------------------------
# ✅ Logging Setup
# -----------------------------------------------------------
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("FlaskApp")

# -----------------------------------------------------------
# ✅ Flask App Initialization
# -----------------------------------------------------------
app = Flask(__name__)
CORS(app)  # Allow Flutter app (on same LAN) to call the API

# -----------------------------------------------------------
# ✅ Load Toxic Model Once (Global Instance)
# -----------------------------------------------------------
log.info("🚀 Initializing ToxicChecker...")
checker = ToxicChecker()
log.info("✅ ToxicChecker ready for incoming analysis requests.")

# -----------------------------------------------------------
# ✅ Health Check Endpoint
# -----------------------------------------------------------
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200

# -----------------------------------------------------------
# ✅ Analyze Endpoint
# -----------------------------------------------------------
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

        # 🔍 Analyze using our one-time loaded model
        result = checker.analyze(text)

        # Add metadata for Firestore
        result.update({
            "id": msg_id,
            "sender": sender,
            "timestamp": ts,
        })

        log.info(f"✅ Analysis Complete → {result}\n")
        return jsonify(result), 200

    except Exception as e:
        log.exception("❌ Error during /analyze request:")
        return jsonify({"error": str(e)}), 500

# -----------------------------------------------------------
# ✅ Run Flask App on LAN
# -----------------------------------------------------------
if __name__ == "__main__":
    # Use 0.0.0.0 so Flutter app on same WiFi can access it
    app.run(host="0.0.0.0", port=5000, debug=False)
