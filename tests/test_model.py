#!/usr/bin/env python3
"""
Test Ollama model with timeout
"""

import requests
import json
import sys
import time

def test_model(model="codellama:7b-code-q4_K_M", question="What is 2+2?", timeout=30):
    print(f"🤖 Testing model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    url = "http://localhost:11434/api/generate"
    data = {
        "model": model,
        "prompt": question,
        "stream": False
    }
    
    try:
        start_time = time.time()
        response = requests.post(url, json=data, timeout=timeout)
        end_time = time.time()
        
        if response.status_code == 200:
            result = response.json()
            clean_response = result['response'].encode('ascii', 'ignore').decode('ascii').strip()
            
            print("✅ Response received:")
            print(clean_response)
            print()
            print(f"📊 Model: {result.get('model', 'Unknown')}")
            print(f"⏱️  Duration: {result.get('total_duration', 0)}ms")
            print(f"🕐 Real time: {(end_time - start_time)*1000:.0f}ms")
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(response.text)
            
    except requests.exceptions.Timeout:
        print("⏰ Timeout reached")
    except requests.exceptions.ConnectionError:
        print("❌ Connection error - Is Ollama running?")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print()
    print("🏁 Test completed")

if __name__ == "__main__":
    model = sys.argv[1] if len(sys.argv) > 1 else "codellama:7b-code-q4_K_M"
    question = sys.argv[2] if len(sys.argv) > 2 else "Write a simple Python function to calculate factorial"
    
    test_model(model, question) 