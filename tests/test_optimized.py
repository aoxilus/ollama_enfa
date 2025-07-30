#!/usr/bin/env python3
"""
Optimized code test for Ollama models with better performance
"""

import requests
import json
import sys
import time
import asyncio
import aiohttp

def test_optimized(model="codellama:7b-code-q4_K_M", question="Write a Python function to calculate factorial", timeout=30):
    print(f"🚀 Optimized Code test - Model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    url = "http://localhost:11434/api/generate"
    
    # Optimized prompt for better performance
    prompt = f"""Write code for: {question}

```python
"""
    
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.6,  # Balanced temperature
            "num_predict": 300,  # Optimized tokens
            "top_k": 30,
            "top_p": 0.9,
            "repeat_penalty": 1.1
        }
    }
    
    try:
        start_time = time.time()
        
        # Use session for better performance
        with requests.Session() as session:
            session.headers.update({'Content-Type': 'application/json'})
            response = session.post(url, json=data, timeout=timeout)
        
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
            
            # Enhanced validation
            if any(keyword in response_text.lower() for keyword in ['def ', 'import ', 'class ', 'function ', 'const ', 'let ', 'var ']):
                print("✅ Code: VALID")
            else:
                print("⚠️  Code: MAYBE INCOMPLETE")
            
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

async def test_async(model="codellama:7b-code-q4_K_M", question="Write a Python function to calculate factorial", timeout=30):
    print(f"🔄 Async Code test - Model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    url = "http://localhost:11434/api/generate"
    
    prompt = f"""Write code for: {question}

```python
"""
    
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.6,
            "num_predict": 300,
            "top_k": 30,
            "top_p": 0.9,
            "repeat_penalty": 1.1
        }
    }
    
    try:
        start_time = time.time()
        
        timeout_obj = aiohttp.ClientTimeout(total=timeout)
        async with aiohttp.ClientSession(timeout=timeout_obj) as session:
            async with session.post(url, json=data) as response:
                result = await response.json()
        
        end_time = time.time()
        
        response_text = result['response'].strip()
        
        print("✅ Async Response received:")
        print("```python")
        print(response_text)
        print("```")
        print()
        print(f"📊 Model: {result.get('model', 'Unknown')}")
        print(f"⏱️  Duration: {result.get('total_duration', 0)}ms")
        print(f"🕐 Real time: {(end_time - start_time)*1000:.0f}ms")
        
        if any(keyword in response_text.lower() for keyword in ['def ', 'import ', 'class ', 'function ', 'const ', 'let ', 'var ']):
            print("✅ Code: VALID")
        else:
            print("⚠️  Code: MAYBE INCOMPLETE")
            
    except asyncio.TimeoutError:
        print("⏰ Async timeout reached")
    except Exception as e:
        print(f"❌ Async error: {e}")
    
    print()
    print("🏁 Async test completed")

if __name__ == "__main__":
    model = "codellama:7b-code-q4_K_M"
    question = sys.argv[1] if len(sys.argv) > 1 else "Write a Python function to calculate factorial"
    use_async = "--async" in sys.argv
    
    if use_async:
        asyncio.run(test_async(model, question))
    else:
        test_optimized(model, question) 