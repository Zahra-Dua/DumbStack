import requests
import json
import time

# Wait for server to start
time.sleep(3)

# Test harassment detection
test_messages = [
    "You are stupid and I hate you",
    "I will kill you",
    "You are an idiot",
    "Go die",
    "You are worthless",
    "Hello how are you",  # Safe message
    "You are harami",  # Urdu harassment
    "Madarchod",  # Urdu harassment
    "I hate you so much",
    "You should die"
]

print("🧪 Testing Harassment Detection System")
print("=" * 50)

for i, message in enumerate(test_messages, 1):
    try:
        response = requests.post(
            "http://localhost:5000/analyze",
            headers={"Content-Type": "application/json"},
            json={"text": message},
            timeout=5
        )
        
        if response.status_code == 200:
            result = response.json()
            flag = result.get("flag", 0)
            tox_label = result.get("tox_label", "Unknown")
            tox_score = result.get("tox_score", 0.0)
            
            status = "🚨 FLAGGED" if flag == 1 else "✅ SAFE"
            print(f"{i:2d}. {status} | {tox_label} ({tox_score:.2f}) | \"{message}\"")
        else:
            print(f"{i:2d}. ❌ ERROR | Status: {response.status_code} | \"{message}\"")
            
    except Exception as e:
        print(f"{i:2d}. ❌ CONNECTION ERROR | \"{message}\" | Error: {str(e)}")

print("\n" + "=" * 50)
print("✅ Test completed!")
