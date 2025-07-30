#!/usr/bin/env python3
"""
Clean test for Ollama models
"""

import requests
import json
import sys
import time

def test_clean(model="codellama:7b-code-q4_K_M", question="What is 2+2?", timeout=60):
    print(f"🤖 Testing model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    # Clear context first
    url = "http://localhost:11434/api/generate"
    
    # Enhanced prompt
    enhanced_prompt = f"""You are a helpful AI assistant. Answer this question clearly and accurately:

Question: {question}

Instructions:
- Provide a clear, direct answer
- If it's a math question, give the correct numerical result
- Be concise and helpful

Answer:"""
    
    data = {
        "model": model,
        "prompt": enhanced_prompt,
        "stream": False,
        "options": {
            "temperature": 0.3,
            "num_predict": 100
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
            
            # Validate response
            if "2+2" in question.lower() and "4" in response_text:
                print("✅ Math validation: PASSED")
            elif "2+2" in question.lower() and "4" not in response_text:
                print("❌ Math validation: FAILED")
            
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
    question = sys.argv[2] if len(sys.argv) > 2 else "What is 2+2?"
    
    test_clean(model, question) 