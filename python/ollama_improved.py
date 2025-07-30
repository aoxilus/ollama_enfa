#!/usr/bin/env python3
"""
Ollama Improved - Enhanced version with better model selection and prompt engineering
"""

import asyncio
import aiohttp
import json
import os
import sys
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple

# Model configuration
MODELS = {
    "llama2:7b": {"priority": 1, "max_tokens": 2048, "temperature": 0.7},
    "llama2:13b": {"priority": 2, "max_tokens": 2048, "temperature": 0.7},
    "codellama:7b-instruct": {"priority": 3, "max_tokens": 2048, "temperature": 0.3},
    "mistral:7b": {"priority": 4, "max_tokens": 2048, "temperature": 0.7},
    "smollm2:135m": {"priority": 999, "max_tokens": 512, "temperature": 0.1}  # Last resort
}

class OllamaImproved:
    def __init__(self, endpoint="http://localhost:11434"):
        self.endpoint = endpoint
        self.session = None
        self.available_models = []
        self.best_model = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        await self.discover_models()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def discover_models(self):
        """Discover available models and select the best one"""
        try:
            async with self.session.get(f"{self.endpoint}/api/tags") as response:
                if response.status == 200:
                    data = await response.json()
                    self.available_models = data.get('models', [])
                    
                    # Find best model based on priority
                    best_priority = float('inf')
                    for model_info in self.available_models:
                        model_name = model_info['name']
                        if model_name in MODELS:
                            priority = MODELS[model_name]['priority']
                            if priority < best_priority:
                                best_priority = priority
                                self.best_model = model_name
                    
                    if not self.best_model:
                        print("⚠️ No recommended models found, using first available")
                        self.best_model = self.available_models[0]['name'] if self.available_models else None
                    
                    print(f"✅ Best model: {self.best_model}")
                    return True
        except Exception as e:
            print(f"❌ Error discovering models: {e}")
            return False
    
    def create_enhanced_prompt(self, question: str, context: str = "") -> str:
        """Create enhanced prompt with better structure"""
        if context:
            prompt = f"""You are a helpful AI assistant. Answer the question based on the provided context.

Context:
{context}

Question: {question}

Instructions:
- Provide clear, accurate, and concise answers
- If the question is mathematical, give the correct numerical result
- If the question is about code, provide working code examples
- Be helpful and professional

Answer:"""
        else:
            prompt = f"""You are a helpful AI assistant. Answer the following question clearly and accurately.

Question: {question}

Instructions:
- Provide clear, accurate, and concise answers
- If the question is mathematical, give the correct numerical result
- If the question is about code, provide working code examples
- Be helpful and professional

Answer:"""
        
        return prompt
    
    def validate_response(self, response: str) -> Tuple[bool, str]:
        """Validate response quality"""
        if not response or len(response.strip()) < 10:
            return False, "Response too short"
        
        # Check for obvious errors in math
        if "2+2" in response.lower() and "4" not in response:
            return False, "Mathematical error detected"
        
        # Check for repetitive text
        words = response.split()
        if len(words) > 20:
            word_freq = {}
            for word in words:
                word_freq[word] = word_freq.get(word, 0) + 1
                if word_freq[word] > len(words) * 0.3:  # More than 30% repetition
                    return False, "Repetitive response detected"
        
        return True, "Response looks good"
    
    async def query_with_retry(self, question: str, context: str = "", max_retries: int = 3) -> str:
        """Query with retry and model fallback"""
        if not self.best_model:
            return "❌ No models available"
        
        model_config = MODELS.get(self.best_model, {})
        prompt = self.create_enhanced_prompt(question, context)
        
        for attempt in range(max_retries):
            try:
                print(f"🔄 Attempt {attempt + 1} with model: {self.best_model}")
                
                data = {
                    "model": self.best_model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": model_config.get("temperature", 0.7),
                        "num_predict": model_config.get("max_tokens", 2048)
                    }
                }
                
                start_time = time.time()
                async with self.session.post(
                    f"{self.endpoint}/api/generate",
                    json=data,
                    timeout=aiohttp.ClientTimeout(total=60)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        response_text = result.get('response', '').strip()
                        
                        # Validate response
                        is_valid, validation_msg = self.validate_response(response_text)
                        if is_valid:
                            duration = (time.time() - start_time) * 1000
                            print(f"✅ Valid response in {duration:.0f}ms")
                            return response_text
                        else:
                            print(f"⚠️ Invalid response: {validation_msg}")
                            if attempt < max_retries - 1:
                                await asyncio.sleep(1)
                                continue
                            else:
                                return f"❌ Failed to get valid response after {max_retries} attempts"
                    else:
                        error_text = await response.text()
                        print(f"❌ HTTP {response.status}: {error_text}")
                        
            except asyncio.TimeoutError:
                print(f"⏰ Timeout on attempt {attempt + 1}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(2)
                    continue
                else:
                    return "❌ All attempts timed out"
            except Exception as e:
                print(f"❌ Error on attempt {attempt + 1}: {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(1)
                    continue
                else:
                    return f"❌ Failed after {max_retries} attempts: {e}"
        
        return "❌ All retries failed"

async def main():
    if len(sys.argv) < 2:
        print("Usage: python ollama_improved.py \"your question\" [context_path]")
        sys.exit(1)
    
    question = sys.argv[1]
    context_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    print("🚀 Starting improved Ollama client...")
    
    async with OllamaImproved() as client:
        context = ""
        if context_path and os.path.exists(context_path):
            try:
                with open(context_path, 'r', encoding='utf-8') as f:
                    context = f.read()[:2000]  # Limit context size
                print(f"📁 Loaded context from: {context_path}")
            except Exception as e:
                print(f"⚠️ Could not load context: {e}")
        
        print(f"🤖 Querying: {question}")
        response = await client.query_with_retry(question, context)
        
        print("\n" + "="*50)
        print("RESPONSE:")
        print("="*50)
        print(response)
        print("="*50)

if __name__ == "__main__":
    asyncio.run(main()) 