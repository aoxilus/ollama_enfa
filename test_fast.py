#!/usr/bin/env python3
"""
Fast test for Ollama models with GPU optimization
"""

import requests
import json
import sys
import time

def test_fast(model="codellama:7b-code-q4_K_M", question="What is 2+2?", timeout=30):
    print(f"🚀 Fast test - Model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    url = "http://localhost:11434/api/generate"
    
    # Minimal prompt for speed
    prompt = f"Q: {question}\nA:"
    
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.1,
            "num_predict": 20,  # Very short response
            "top_k": 10,
            "top_p": 0.9,
            "repeat_penalty": 1.1
        }
    }
    
    try:
        start_time = time.time()
        response = requests.post(url, json=data, timeout=timeout)
        end_time = time.time()
        
        if response.status_code == 200:
            result = response.json()
            response_text = result['response'].strip()
            
            print("✅ Response received:")
            print(response_text)
            print()
            print(f"📊 Model: {result.get('model', 'Unknown')}")
            print(f"⏱️  Duration: {result.get('total_duration', 0)}ms")
            print(f"🕐 Real time: {(end_time - start_time)*1000:.0f}ms")
            
            # Quick validation
            if "2+2" in question.lower():
                if "4" in response_text:
                    print("✅ Math: CORRECT")
                else:
                    print("❌ Math: WRONG")
            
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(response.text)
            
    except requests.exceptions.Timeout:
        print("⏰ Timeout reached")
    except requests.exceptions.ConnectionError:
        print("❌ Connection error")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print()
    print("🏁 Test completed")

if __name__ == "__main__":
    model = sys.argv[1] if len(sys.argv) > 1 else "codellama:7b-code-q4_K_M"
    question = sys.argv[2] if len(sys.argv) > 2 else "What is 2+2?"
    
    test_fast(model, question) 