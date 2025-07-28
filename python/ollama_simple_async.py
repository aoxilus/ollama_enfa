#!/usr/bin/env python3
"""
Ollama Simple Async - Enhanced version with cache, error handling, and validation
Usage: python ollama_simple_async.py "your question" [path_to_analyze]

Configuration:
- SYNC_MODE: Set to True to enable synchronous mode (blocking)
- Set to False for asynchronous mode (non-blocking, recommended)
"""
import asyncio
import aiohttp
import json
import os
import sys
import glob
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor

# Configuration - Set to True for sync mode, False for async mode (recommended)
SYNC_MODE = False

# Import our new modules
from ollama_cache import get_cached_response, cache_response, get_cache_stats
from ollama_errors import (
    handle_error, validate_question, validate_model, validate_file_path,
    retry_operation, check_ollama_health, get_system_info, get_error_stats
)

async def check_ollama_connection():
    """Check if Ollama is running and get the best available model"""
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get("http://localhost:11434/api/tags", timeout=aiohttp.ClientTimeout(total=5)) as response:
                if response.status == 200:
                    data = await response.json()
                    models = data.get('models', [])
                    
                    if not models:
                        return False, "No hay modelos disponibles en Ollama"
                    
                    # Find the largest model (most parameters)
                    best_model = None
                    largest_size = 0
                    
                    for model in models:
                        size_bytes = model.get('size', 0)
                        size_mb = size_bytes / (1024 * 1024)
                        
                        if size_mb > largest_size:
                            largest_size = size_mb
                            best_model = model['name']
                    
                    if not best_model:
                        return False, "No se pudo determinar el mejor modelo"
                    
                    return True, best_model
                else:
                    return False, f"Error HTTP {response.status}"
                    
    except asyncio.TimeoutError:
        return False, "No se puede conectar a Ollama. Verifica que esté ejecutándose."
    except Exception as e:
        return False, handle_error(e, {'function': 'check_ollama_connection'})

def get_project_files_sync(target_path=".", max_files=10):
    """Get list of project files from specified path (synchronous for file I/O)"""
    try:
        # Validate file path
        if target_path != ".":
            validate_file_path(target_path)
        
        files = []
        patterns = ["*.py", "*.js", "*.html", "*.css", "*.json", "*.md", "*.txt"]
        
        # If target_path is a file, analyze only that file
        if os.path.isfile(target_path):
            try:
                if os.path.getsize(target_path) < 50000:  # Skip large files
                    with open(target_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if content.strip():
                            files.append(f"=== {target_path} ===\n{content}")
            except Exception as e:
                files.append(f"Error reading file {target_path}: {handle_error(e)}")
            return "\n".join(files)
        
        # If target_path is a directory, analyze all matching files
        for pattern in patterns:
            search_pattern = os.path.join(target_path, "**", pattern)
            found = glob.glob(search_pattern, recursive=True)
            for file_path in found[:max_files]:
                try:
                    if os.path.getsize(file_path) < 50000:  # Skip large files
                        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                            content = f.read()
                            if content.strip():
                                files.append(f"=== {file_path} ===\n{content[:2000]}...")
                except Exception as e:
                    files.append(f"Error reading {file_path}: {handle_error(e)}")
                    continue
        
        return "\n".join(files)
    
    except Exception as e:
        return f"Error processing files: {handle_error(e, {'target_path': target_path})}"

async def get_project_files(target_path=".", max_files=10):
    """Get list of project files asynchronously"""
    loop = asyncio.get_event_loop()
    with ThreadPoolExecutor() as executor:
        return await loop.run_in_executor(executor, get_project_files_sync, target_path, max_files)

async def query_ollama(question, context="", model="codellama:7b-instruct"):
    """Query Ollama API asynchronously with retry mechanism"""
    
    # Validate inputs
    validate_question(question)
    validate_model(model)
    
    # Check cache first
    cached_response = get_cached_response(question, context, model)
    if cached_response:
        print("✅ Respuesta obtenida del cache")
        return cached_response
    
    async def _query():
        try:
            prompt = f"""Project files:
{context}

Question: {question}

Answer:"""

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    "http://localhost:11434/api/generate",
                    json={
                        "model": model,
                        "prompt": prompt,
                        "stream": False
                    },
                    timeout=aiohttp.ClientTimeout(total=300)
                ) as response:
                    
                    if response.status == 200:
                        data = await response.json()
                        response_text = data.get('response', 'No response')
                        
                        # Cache the response
                        cache_response(question, response_text, context, model)
                        
                        return response_text
                    else:
                        error_msg = f"Error: HTTP {response.status} - {await response.text()}"
                        raise Exception(error_msg)
                        
        except Exception as e:
            raise e
    
    # Use retry mechanism
    return await retry_operation(_query)

async def query_ollama_sync(question, context, model):
    """Query Ollama API synchronously (blocking) for SYNC_MODE"""
    try:
        import requests
        
        prompt = f"""Project files:
{context}

Question: {question}

Answer:"""

        data = {
            "model": model,
            "prompt": prompt,
            "stream": False
        }

        response = requests.post(
            "http://localhost:11434/api/generate",
            json=data,
            timeout=300
        )
        
        if response.status_code == 200:
            result = response.json()
            return result.get("response", "No response received")
        else:
            raise Exception(f"HTTP {response.status_code}: {response.text}")
    except Exception as e:
        return handle_error(e, {
            'question': question,
            'context_length': len(context),
            'model': model
        })

async def save_response_async(question, response):
    """Save response to file asynchronously"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"\n=== {timestamp} ===\nQ: {question}\nA: {response}\n"
    
    try:
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            await loop.run_in_executor(executor, save_response_sync, entry)
    except Exception as e:
        print(f"⚠️ Warning: Could not save to file: {handle_error(e)}")

def save_response_sync(entry):
    """Save response to file (synchronous)"""
    try:
        with open("logs/ollama_responses.txt", "a", encoding="utf-8", newline='\n') as f:
            f.write(entry)
            f.flush()
    except Exception as e:
        print(f"⚠️ Warning: Could not save response: {handle_error(e)}")

async def main():
    """Main async function with enhanced error handling"""
    if len(sys.argv) < 2:
        print("Usage: python ollama_simple_async.py \"your question\" [path_to_analyze]")
        print("Examples:")
        print("  python ollama_simple_async.py \"What does this code do?\"")
        print("  python ollama_simple_async.py \"Find errors\" test_project/")
        print("  python ollama_simple_async.py \"Analyze this file\" main.py")
        sys.exit(1)
    
    question = sys.argv[1]
    path_to_analyze = sys.argv[2] if len(sys.argv) > 2 else "."
    
    # Validate inputs
    if not validate_question(question):
        print("Error: Invalid question")
        sys.exit(1)
    
    if not validate_file_path(path_to_analyze):
        print(f"Error: Invalid path: {path_to_analyze}")
        sys.exit(1)
    
    print("Checking Ollama connection...")
    is_connected, model = await check_ollama_connection()
    
    if not is_connected:
        print(f"Error: {model}")
        sys.exit(1)
    
    print(f"OK: Ollama connected - Using model: {model}")
    
    print("Getting project context...")
    context = get_project_files_sync(path_to_analyze)
    
    if not context.strip():
        print(f"Warning: No files found to analyze in: {path_to_analyze}")
        context = f"No files found in {path_to_analyze}"
    
    # Check cache first
    print("Checking cache...")
    cached_response = get_cached_response(question, context)
    
    if cached_response:
        print("OK: Response found in cache!")
        print("")
        print("=" * 50)
        print("RESPONSE (CACHED):")
        print("=" * 50)
        print("")
        print(cached_response)
        print("")
        print("=" * 50)
    else:
        print("Querying Ollama...")
        
        if SYNC_MODE:
            # Synchronous mode (blocking)
            response = await query_ollama_sync(question, context, model)
        else:
            # Asynchronous mode (non-blocking, recommended)
            response = await query_ollama(question, context, model)
        
        # Cache the response
        cache_response(question, context, response)
        
        print("")
        print("=" * 50)
        print("RESPONSE:")
        print("=" * 50)
        print("")
        print(response)
        print("")
        print("=" * 50)
    
    # Save response to file
    response_to_save = response if 'response' in locals() else cached_response
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"\n=== {timestamp} ===\nQ: {question}\nA: {response_to_save}\n"
    save_response_sync(entry)
    
    # Show statistics
    print("")
    print(f"Cache Stats: {get_cache_stats()}")
    print(f"Error Stats: {get_error_stats()}")

if __name__ == "__main__":
    if SYNC_MODE:
        print("Running in SYNC mode (blocking)")
        asyncio.run(main())
    else:
        print("Running in ASYNC mode (non-blocking, recommended)")
        asyncio.run(main())