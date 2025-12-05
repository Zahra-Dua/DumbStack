#!/usr/bin/env python3
"""
Test script for harassment detection
"""
import requests
import json
import time

# Test harassment detection
test_messages = [
    "Hello how are you",  # Safe message
    "You are stupid and I hate you",  # Toxic
    "I will kill you",  # Threat
    "You are harami",  # Urdu harassment
    "Madarchod",  # Urdu harassment
    "This is harassment",  # English harassment
    "You are bullying me",  # Bullying
    "This is abusive behavior",  # Abuse
    "You are an idiot",  # Toxic
    "I hate you so much",  # Toxic
    "You should die",  # Threat
    "This is a normal message",  # Safe
]

print("🧪 Testing Harassment Detection System")
print("=" * 60)

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

print("\n" + "=" * 60)
print("✅ Harassment detection test completed!")
print("\nExpected results:")
print("- Messages with 'harami', 'madarchod' should be flagged as 'Harassment'")
print("- Messages with 'kill', 'hate', 'stupid' should be flagged as 'Toxic'")
print("- Safe messages should not be flagged")





