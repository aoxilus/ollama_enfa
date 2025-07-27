#!/usr/bin/env python3
"""
Ollama Simple - Query local Ollama with project context
Usage: python ollama_simple.py "your question here"
"""

import os
import sys
import json
import requests
import glob
from datetime import datetime

def check_ollama_connection():
    """Check if Ollama is running and get available models"""
    try:
        # Check if Ollama is running
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        if response.status_code != 200:
            return False, "Ollama no está ejecutándose en puerto 11434"
        
        # Get available models
        models_data = response.json()
        models = models_data.get('models', [])
        
        if not models:
            return False, "No hay modelos disponibles en Ollama"
        
        # Find the largest model (most parameters)
        best_model = None
        largest_size = 0
        
        for model in models:
            if isinstance(model, dict):
                size_bytes = model.get('size', 0)
                # Convert bytes to MB for comparison
                size_mb = size_bytes / (1024 * 1024)
                
                if size_mb > largest_size:
                    largest_size = size_mb
                    best_model = model.get('name')
        
        if not best_model:
            return False, "No se pudo determinar el mejor modelo"
        
        return True, best_model
        
    except requests.exceptions.ConnectionError:
        return False, "No se puede conectar a Ollama. Verifica que esté ejecutándose."
    except Exception as e:
        return False, f"Error verificando Ollama: {str(e)}"

def get_project_files(max_files=10):
    """Get list of project files"""
    files = []
    patterns = ["*.py", "*.js", "*.html", "*.css", "*.json", "*.md", "*.txt"]
    
    for pattern in patterns:
        found = glob.glob(pattern, recursive=True)
        for file_path in found[:max_files]:
            try:
                if os.path.getsize(file_path) < 50000:  # Skip large files
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if content.strip():
                            files.append(f"=== {file_path} ===\n{content[:2000]}...")
            except:
                continue
    
    return "\n".join(files)

def query_ollama(question, context="", model="smollm2:135m"):
    """Query Ollama API"""
    try:
        prompt = f"""Project files:
{context}

Question: {question}

Answer:"""

        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": model,
                "prompt": prompt,
                "stream": False
            },
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            return data.get('response', 'No response')
        else:
            return f"Error: HTTP {response.status_code} - {response.text}"
            
    except requests.exceptions.Timeout:
        return "Error: Timeout - El modelo tardó demasiado en responder"
    except Exception as e:
        return f"Error: {str(e)}"

def save_response(question, response):
    """Save response to file"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"""
=== {timestamp} ===
Q: {question}
A: {response}
"""
    
    try:
        # Write with proper encoding and ensure it's visible
        with open("ollama_responses.txt", "a", encoding="utf-8", newline='\n') as f:
            f.write(entry)
            f.flush()  # Force write to disk
        print(f"✅ Response saved to ollama_responses.txt")
    except Exception as e:
        print(f"❌ Error saving: {e}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python ollama_simple.py 'your question'")
        sys.exit(1)
    
    question = " ".join(sys.argv[1:])
    
    print("🔍 Verificando conexión con Ollama...")
    is_connected, result = check_ollama_connection()
    
    if not is_connected:
        print(f"❌ {result}")
        print("\n💡 Soluciones:")
        print("1. Ejecuta: ollama serve")
        print("2. Verifica que Ollama esté instalado")
        print("3. Descarga un modelo: ollama pull llama2:7b")
        sys.exit(1)
    
    print(f"✅ Ollama conectado - Usando modelo: {result}")
    
    print("🔍 Getting project context...")
    context = get_project_files()
    
    print("🤖 Querying Ollama...")
    response = query_ollama(question, context, result)
    
    print("\n" + "="*50)
    print("RESPONSE:")
    print("="*50)
    print(response)
    print("="*50)
    
    save_response(question, response)

if __name__ == "__main__":
    main() 