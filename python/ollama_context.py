#!/usr/bin/env python3
"""
Ollama Context - Query local Ollama with project context
Usage: python ollama_context.py "your question here"
"""

import os
import sys
import json
import requests
import glob
from pathlib import Path
import time
from datetime import datetime

class OllamaContext:
    def __init__(self, endpoint="http://localhost:11434", model="smollm2:135m", buffer_size=10):
        self.endpoint = endpoint
        self.model = model
        self.buffer_size = buffer_size
        self.response_buffer = []
        self.buffer_file = "ollama_responses.txt"
        
    def get_project_context(self, max_files=20, max_size=50000):
        """Get context from project files"""
        context = []
        project_root = Path.cwd()
        
        # File patterns to include
        patterns = [
            "*.py", "*.js", "*.ts", "*.html", "*.css", "*.php", "*.java", "*.cpp", "*.c",
            "*.json", "*.xml", "*.yaml", "*.yml", "*.md", "*.txt", "*.sh", "*.bat",
            "Dockerfile", "Makefile", "requirements.txt", "package.json"
        ]
        
        total_size = 0
        file_count = 0
        
        for pattern in patterns:
            if file_count >= max_files or total_size >= max_size:
                break
                
            files = glob.glob(pattern, recursive=True)
            for file_path in files:
                if file_count >= max_files or total_size >= max_size:
                    break
                    
                try:
                    file_size = os.path.getsize(file_path)
                    if file_size > 100000:  # Skip files > 100KB
                        continue
                        
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if len(content.strip()) > 0:
                            context.append(f"=== {file_path} ===\n{content}\n")
                            total_size += len(content)
                            file_count += 1
                            
                except Exception as e:
                    continue
        
        return "\n".join(context)
    
    def query_ollama(self, question, context=""):
        """Query Ollama with question and context"""
        try:
            prompt = f"""Context from project files:
{context}

Question: {question}

Please provide a helpful response based on the project context:"""

            response = requests.post(
                f"{self.endpoint}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=60
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get('response', 'No response received')
            else:
                return f"Error: HTTP {response.status_code}"
                
        except Exception as e:
            return f"Error querying Ollama: {str(e)}"
    
    def add_to_buffer(self, question, response):
        """Add response to buffer"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = f"""
=== {timestamp} ===
Q: {question}
A: {response}
"""
        self.response_buffer.append(entry)
        
        # Keep only last buffer_size entries
        if len(self.response_buffer) > self.buffer_size:
            self.response_buffer.pop(0)
    
    def save_buffer(self):
        """Save buffer to file"""
        try:
            with open(self.buffer_file, 'w', encoding='utf-8') as f:
                f.write("".join(self.response_buffer))
            print(f"Buffer saved to {self.buffer_file}")
        except Exception as e:
            print(f"Error saving buffer: {e}")
    
    def run(self, question):
        """Main execution"""
        print("🔍 Analyzing project context...")
        context = self.get_project_context()
        
        print(f"📁 Found context from {len(context.split('==='))-1} files")
        print(f"🤖 Querying Ollama ({self.model})...")
        
        response = self.query_ollama(question, context)
        
        print("\n" + "="*50)
        print("RESPONSE:")
        print("="*50)
        print(response)
        print("="*50)
        
        # Add to buffer
        self.add_to_buffer(question, response)
        self.save_buffer()
        
        return response

def main():
    if len(sys.argv) < 2:
        print("Usage: python ollama_context.py 'your question here'")
        print("Example: python ollama_context.py 'How does the authentication work?'")
        sys.exit(1)
    
    question = " ".join(sys.argv[1:])
    
    # Check if Ollama is running
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        if response.status_code != 200:
            print("❌ Ollama not running. Start it with: ollama serve")
            sys.exit(1)
    except:
        print("❌ Cannot connect to Ollama. Make sure it's running on http://localhost:11434")
        sys.exit(1)
    
    # Run query
    ollama = OllamaContext()
    ollama.run(question)

if __name__ == "__main__":
    main() 