#!/usr/bin/env python3
"""
Perfect code test for Ollama models with maximum performance optimization
"""

import requests
import json
import sys
import time
import asyncio
import aiohttp
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
import threading

# Cache global thread-safe
_cache = {}
_cache_lock = threading.Lock()
_cache_expiry = 3600  # 1 hora

@lru_cache(maxsize=1000)
def generate_hash(prompt, model):
    """Generate hash for cache key"""
    return hash(f"{prompt}|{model}")

def get_cached_response(prompt, model):
    """Get cached response if available and not expired"""
    with _cache_lock:
        cache_key = generate_hash(prompt, model)
        if cache_key in _cache:
            entry = _cache[cache_key]
            if time.time() < entry['expiry']:
                entry['access_count'] += 1
                return entry['response']
            else:
                del _cache[cache_key]
    return None

def set_cached_response(prompt, model, response):
    """Set cached response with expiry"""
    with _cache_lock:
        cache_key = generate_hash(prompt, model)
        _cache[cache_key] = {
            'response': response,
            'expiry': time.time() + _cache_expiry,
            'access_count': 1
        }

def cleanup_cache():
    """Clean up expired cache entries"""
    with _cache_lock:
        current_time = time.time()
        expired_keys = [k for k, v in _cache.items() if current_time >= v['expiry']]
        for key in expired_keys:
            del _cache[key]

def test_perfect(model="codellama:7b-code-q4_K_M", question="Write a Python function to calculate factorial", timeout=30):
    print(f"🚀 Perfect Code test - Model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    # Cleanup cache first
    cleanup_cache()
    
    # Check cache
    cached_response = get_cached_response(question, model)
    if cached_response:
        print("⚡ Respuesta desde cache:")
        print("```python")
        print(cached_response)
        print("```")
        print()
        print("⏱️  Cache hit - tiempo instantáneo")
        return cached_response
    
    url = "http://localhost:11434/api/generate"
    
    # Optimized prompt for maximum performance
    prompt = f"""Write code for: {question}

```python
"""
    
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.5,  # Optimal temperature
            "num_predict": 250,  # Optimal tokens
            "top_k": 25,
            "top_p": 0.85,
            "repeat_penalty": 1.1
        }
    }
    
    try:
        start_time = time.time()
        
        # Use session with connection pooling for maximum performance
        with requests.Session() as session:
            session.headers.update({
                'Content-Type': 'application/json',
                'Connection': 'keep-alive'
            })
            session.mount('http://', requests.adapters.HTTPAdapter(
                pool_connections=10,
                pool_maxsize=20
            ))
            
            response = session.post(url, json=data, timeout=timeout)
        
        end_time = time.time()
        
        if response.status_code == 200:
            result = response.json()
            response_text = result['response'].strip()
            
            # Cache the response
            set_cached_response(question, model, response_text)
            
            print("✅ Response received:")
            print("```python")
            print(response_text)
            print("```")
            print()
            print(f"📊 Model: {result.get('model', 'Unknown')}")
            print(f"⏱️  Duration: {result.get('total_duration', 0)}ms")
            print(f"🕐 Real time: {(end_time - start_time)*1000:.0f}ms")
            
            # Enhanced validation with more keywords
            code_keywords = ['def ', 'import ', 'class ', 'function ', 'const ', 'let ', 'var ', 'public ', 'private ', 'protected ']
            if any(keyword in response_text.lower() for keyword in code_keywords):
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

async def test_perfect_async(model="codellama:7b-code-q4_K_M", question="Write a Python function to calculate factorial", timeout=30):
    print(f"🔄 Perfect Async Code test - Model: {model}")
    print(f"⏱️  Timeout: {timeout} seconds")
    print(f"📝 Question: {question}")
    print()
    
    # Cleanup cache first
    cleanup_cache()
    
    # Check cache
    cached_response = get_cached_response(question, model)
    if cached_response:
        print("⚡ Respuesta desde cache:")
        print("```python")
        print(cached_response)
        print("```")
        print()
        print("⏱️  Cache hit - tiempo instantáneo")
        return cached_response
    
    url = "http://localhost:11434/api/generate"
    
    prompt = f"""Write code for: {question}

```python
"""
    
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.5,
            "num_predict": 250,
            "top_k": 25,
            "top_p": 0.85,
            "repeat_penalty": 1.1
        }
    }
    
    try:
        start_time = time.time()
        
        # Optimized async session
        timeout_obj = aiohttp.ClientTimeout(total=timeout)
        connector = aiohttp.TCPConnector(
            limit=20,
            limit_per_host=10,
            keepalive_timeout=30,
            enable_cleanup_closed=True
        )
        
        async with aiohttp.ClientSession(
            timeout=timeout_obj,
            connector=connector,
            headers={'Content-Type': 'application/json'}
        ) as session:
            async with session.post(url, json=data) as response:
                result = await response.json()
        
        end_time = time.time()
        
        response_text = result['response'].strip()
        
        # Cache the response
        set_cached_response(question, model, response_text)
        
        print("✅ Async Response received:")
        print("```python")
        print(response_text)
        print("```")
        print()
        print(f"📊 Model: {result.get('model', 'Unknown')}")
        print(f"⏱️  Duration: {result.get('total_duration', 0)}ms")
        print(f"🕐 Real time: {(end_time - start_time)*1000:.0f}ms")
        
        # Enhanced validation
        code_keywords = ['def ', 'import ', 'class ', 'function ', 'const ', 'let ', 'var ', 'public ', 'private ', 'protected ']
        if any(keyword in response_text.lower() for keyword in code_keywords):
            print("✅ Code: VALID")
        else:
            print("⚠️  Code: MAYBE INCOMPLETE")
            
    except asyncio.TimeoutError:
        print("⏰ Async timeout reached")
    except Exception as e:
        print(f"❌ Async error: {e}")
    
    print()
    print("🏁 Async test completed")

def test_concurrent(questions, model="codellama:7b-code-q4_K_M", max_workers=3):
    """Test multiple questions concurrently"""
    print(f"🔄 Concurrent test - {len(questions)} questions")
    print(f"📊 Max workers: {max_workers}")
    print()
    
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = []
        for question in questions:
            future = executor.submit(test_perfect, model, question, 30)
            futures.append(future)
        
        # Wait for all to complete
        for future in futures:
            try:
                future.result()
            except Exception as e:
                print(f"❌ Error in concurrent test: {e}")
    
    end_time = time.time()
    total_time = (end_time - start_time) * 1000
    
    print(f"🏁 Concurrent test completed in {total_time:.0f}ms")

def show_cache_stats():
    """Show cache statistics"""
    with _cache_lock:
        total = len(_cache)
        current_time = time.time()
        valid = sum(1 for v in _cache.values() if current_time < v['expiry'])
        expired = total - valid
        total_access = sum(v['access_count'] for v in _cache.values())
        
        print("📊 Cache Statistics:")
        print(f"   Total: {total} elements")
        print(f"   Valid: {valid} elements")
        print(f"   Expired: {expired} elements")
        print(f"   Total accesses: {total_access}")
        print(f"   Cache expiry: {_cache_expiry}s")

def clear_cache():
    """Clear all cache"""
    with _cache_lock:
        _cache.clear()
        print("🗑️  Cache cleared")

if __name__ == "__main__":
    model = "codellama:7b-code-q4_K_M"
    question = sys.argv[1] if len(sys.argv) > 1 else "Write a Python function to calculate factorial"
    
    # Parse command line arguments
    if "--async" in sys.argv:
        asyncio.run(test_perfect_async(model, question))
    elif "--concurrent" in sys.argv:
        questions = [
            "Write a Python function to calculate factorial",
            "Create a Python class for a bank account",
            "Write a Python function to sort a list"
        ]
        test_concurrent(questions, model)
    elif "--cache-stats" in sys.argv:
        show_cache_stats()
    elif "--clear-cache" in sys.argv:
        clear_cache()
    else:
        test_perfect(model, question) 