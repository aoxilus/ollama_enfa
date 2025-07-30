#!/usr/bin/env python3
"""
Code test for Ollama models
"""

import requests
import json
import sys
import time

def test_code(model="codellama:7b-code-q4_K_M", question="Write a Python function to calculate factorial", timeout=60):
    print(f"💻 Code test - Model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    url = "http://localhost:11434/api/generate"
    
    # Code-specific prompt
    prompt = f"""Write code for: {question}

```python
"""
    
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.2,
            "num_predict": 200,  # More tokens for code
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
            print("```python")
            print(response_text)
            print("```")
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
        print("❌ Connection error")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print()
    print("🏁 Test completed")

if __name__ == "__main__":
    model = sys.argv[1] if len(sys.argv) > 1 else "codellama:7b-code-q4_K_M"
    question = sys.argv[2] if len(sys.argv) > 2 else "Write a Python function to calculate factorial"
    
    test_code(model, question) 