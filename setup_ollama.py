#!/usr/bin/env python3
"""
Ollama Automated Setup and Optimization
Automatically install dependencies, configure models, and optimize performance
"""

import subprocess
import sys
import os
import asyncio
import aiohttp
import json
from typing import Dict, List, Optional

class OllamaSetup:
    def __init__(self):
        self.endpoint = "http://localhost:11434"
        self.session = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    def check_python_version(self) -> bool:
        """Check if Python version is compatible"""
        version = sys.version_info
        if version.major < 3 or (version.major == 3 and version.minor < 8):
            print("❌ Python 3.8+ required")
            return False
        print(f"✅ Python {version.major}.{version.minor}.{version.micro}")
        return True
    
    def install_dependencies(self) -> bool:
        """Install Python dependencies"""
        print("📦 Installing Python dependencies...")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "-r", "python/requirements.txt"], 
                         check=True, capture_output=True)
            print("✅ Dependencies installed successfully")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to install dependencies: {e}")
            return False
    
    def check_ollama_installation(self) -> bool:
        """Check if Ollama is installed and running"""
        print("🔍 Checking Ollama installation...")
        try:
            result = subprocess.run(['ollama', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Ollama installed: {result.stdout.strip()}")
                return True
            else:
                print("❌ Ollama not found")
                return False
        except FileNotFoundError:
            print("❌ Ollama not installed")
            return False
    
    async def check_ollama_service(self) -> bool:
        """Check if Ollama service is running"""
        print("🔍 Checking Ollama service...")
        try:
            async with self.session.get(f"{self.endpoint}/api/tags", timeout=5) as response:
                if response.status == 200:
                    print("✅ Ollama service is running")
                    return True
                else:
                    print(f"❌ Ollama service error: HTTP {response.status}")
                    return False
        except Exception as e:
            print(f"❌ Ollama service not accessible: {e}")
            return False
    
    async def install_recommended_models(self) -> List[str]:
        """Install recommended models"""
        recommended_models = [
            "codellama:7b-code-q4_K_M",  # Primary model
            "llama2:7b",                 # Backup model
        ]
        
        installed_models = []
        
        print("📥 Installing recommended models...")
        for model in recommended_models:
            print(f"   Installing {model}...")
            try:
                result = subprocess.run(['ollama', 'pull', model], 
                                      capture_output=True, text=True, timeout=300)
                if result.returncode == 0:
                    print(f"   ✅ {model} installed")
                    installed_models.append(model)
                else:
                    print(f"   ❌ Failed to install {model}")
            except subprocess.TimeoutExpired:
                print(f"   ⏰ Timeout installing {model}")
            except Exception as e:
                print(f"   ❌ Error installing {model}: {e}")
        
        return installed_models
    
    async def test_model_performance(self, model: str) -> Dict:
        """Test model performance"""
        print(f"🧪 Testing {model} performance...")
        
        try:
            start_time = asyncio.get_event_loop().time()
            
            data = {
                "model": model,
                "prompt": "Q: What is 2+2?\nA:",
                "stream": False,
                "options": {
                    "temperature": 0.1,
                    "num_predict": 20
                }
            }
            
            async with self.session.post(
                f"{self.endpoint}/api/generate",
                json=data,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                
                if response.status == 200:
                    result = await response.json()
                    duration = (asyncio.get_event_loop().time() - start_time) * 1000
                    
                    return {
                        'success': True,
                        'duration': duration,
                        'response': result.get('response', '').strip()
                    }
                else:
                    return {
                        'success': False,
                        'error': f"HTTP {response.status}"
                    }
                    
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def create_optimized_config(self, best_model: str) -> str:
        """Create optimized configuration file"""
        config_content = f"""# Ollama Optimized Configuration
# Generated automatically by setup_ollama.py

# Primary Model
OLLAMA_MODEL={best_model}

# Performance Settings
TEMPERATURE_FAST=0.1
TEMPERATURE_CODE=0.2
TEMPERATURE_GENERAL=0.7
TOKENS_FAST=20
TOKENS_NORMAL=100
TOKENS_CODE=200

# GPU Settings
GPU_ACCELERATION=true

# Cache Settings
CACHE_ENABLED=true
CACHE_DURATION_HOURS=24

# Monitoring
MONITORING_ENABLED=true
MONITORING_INTERVAL=5
"""
        
        with open("ollama_config.env", "w") as f:
            f.write(config_content)
        
        return "ollama_config.env"
    
    def create_quick_start_script(self) -> str:
        """Create quick start script"""
        script_content = """#!/bin/bash
# Ollama Quick Start Script

echo "🚀 Starting Ollama Desktop Cursor AI..."

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "❌ Ollama is not running. Please start Ollama first."
    exit 1
fi

# Run quick test
echo "🧪 Running quick test..."
python test_fast.py codellama:7b-code-q4_K_M "What is 2+2?"

echo "✅ Setup complete! You can now use:"
echo "   python test_fast.py codellama:7b-code-q4_K_M \"your question\""
echo "   python test_code.py codellama:7b-code-q4_K_M \"write code for...\""
echo "   python python/monitor_ollama.py"
"""
        
        with open("quick_start.sh", "w") as f:
            f.write(script_content)
        
        # Make executable on Unix systems
        try:
            os.chmod("quick_start.sh", 0o755)
        except:
            pass
        
        return "quick_start.sh"
    
    async def run_setup(self) -> bool:
        """Run complete setup process"""
        print("🎯 Ollama Automated Setup")
        print("=" * 40)
        
        # Check Python version
        if not self.check_python_version():
            return False
        
        # Install dependencies
        if not self.install_dependencies():
            return False
        
        # Check Ollama installation
        if not self.check_ollama_installation():
            print("\n📥 Please install Ollama first:")
            print("   Visit: https://ollama.ai/download")
            return False
        
        # Check Ollama service
        if not await self.check_ollama_service():
            print("\n🚀 Please start Ollama service:")
            print("   ollama serve")
            return False
        
        # Install models
        installed_models = await self.install_recommended_models()
        
        if not installed_models:
            print("❌ No models installed")
            return False
        
        # Test performance
        print("\n🧪 Testing model performance...")
        best_model = None
        best_performance = float('inf')
        
        for model in installed_models:
            result = await self.test_model_performance(model)
            if result['success']:
                print(f"   {model}: {result['duration']:.0f}ms")
                if result['duration'] < best_performance:
                    best_performance = result['duration']
                    best_model = model
            else:
                print(f"   {model}: ❌ {result['error']}")
        
        if not best_model:
            print("❌ No working models found")
            return False
        
        # Create configuration
        config_file = self.create_optimized_config(best_model)
        script_file = self.create_quick_start_script()
        
        print("\n" + "=" * 40)
        print("✅ Setup Complete!")
        print(f"🏆 Best Model: {best_model}")
        print(f"⚡ Performance: {best_performance:.0f}ms")
        print(f"📁 Config: {config_file}")
        print(f"🚀 Quick Start: {script_file}")
        
        print("\n🎯 Next Steps:")
        print("1. python test_fast.py codellama:7b-code-q4_K_M \"test question\"")
        print("2. python python/monitor_ollama.py")
        print("3. python python/optimize_ollama.py")
        
        return True

async def main():
    """Main setup function"""
    async with OllamaSetup() as setup:
        success = await setup.run_setup()
        if not success:
            sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main()) 