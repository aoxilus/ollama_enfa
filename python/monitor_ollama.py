#!/usr/bin/env python3
"""
Ollama Real-time Monitor
Monitor Ollama performance, GPU usage, and health in real-time
"""

import asyncio
import aiohttp
import json
import time
import psutil
import os
from datetime import datetime
from typing import Dict, List, Optional
import subprocess

class OllamaMonitor:
    def __init__(self, endpoint="http://localhost:11434"):
        self.endpoint = endpoint
        self.session = None
        self.monitoring = False
        self.stats = {
            'queries': 0,
            'errors': 0,
            'avg_response_time': 0,
            'total_response_time': 0,
            'start_time': time.time()
        }
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    def get_system_info(self) -> Dict:
        """Get system information"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            return {
                'cpu_percent': cpu_percent,
                'memory_percent': memory.percent,
                'memory_available_gb': memory.available / (1024**3),
                'disk_percent': disk.percent,
                'disk_free_gb': disk.free / (1024**3)
            }
        except Exception as e:
            return {'error': str(e)}
    
    def get_gpu_info(self) -> Dict:
        """Get GPU information using nvidia-smi or similar"""
        try:
            # Try nvidia-smi first
            result = subprocess.run(['nvidia-smi', '--query-gpu=utilization.gpu,memory.used,memory.total', '--format=csv,noheader,nounits'], 
                                  capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                gpu_info = []
                
                for line in lines:
                    if line.strip():
                        parts = line.split(', ')
                        if len(parts) >= 3:
                            gpu_info.append({
                                'utilization': int(parts[0]),
                                'memory_used_mb': int(parts[1]),
                                'memory_total_mb': int(parts[2]),
                                'memory_percent': (int(parts[1]) / int(parts[2])) * 100
                            })
                
                return {'gpus': gpu_info}
            else:
                # Try ollama ps as fallback
                result = subprocess.run(['ollama', 'ps'], capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    return {'ollama_ps': result.stdout.strip()}
                else:
                    return {'error': 'No GPU monitoring available'}
                    
        except Exception as e:
            return {'error': f'GPU monitoring error: {e}'}
    
    async def check_ollama_health(self) -> Dict:
        """Check Ollama service health"""
        try:
            async with self.session.get(f"{self.endpoint}/api/tags", timeout=5) as response:
                if response.status == 200:
                    data = await response.json()
                    models = data.get('models', [])
                    
                    return {
                        'status': 'healthy',
                        'models_count': len(models),
                        'models': [model['name'] for model in models],
                        'response_time': response.headers.get('X-Response-Time', 'unknown')
                    }
                else:
                    return {
                        'status': 'unhealthy',
                        'error': f"HTTP {response.status}",
                        'models_count': 0
                    }
        except Exception as e:
            return {
                'status': 'unhealthy',
                'error': str(e),
                'models_count': 0
            }
    
    async def test_query_performance(self, model: str = "codellama:7b-code-q4_K_M") -> Dict:
        """Test query performance"""
        try:
            start_time = time.time()
            
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
                    duration = (time.time() - start_time) * 1000
                    
                    # Update stats
                    self.stats['queries'] += 1
                    self.stats['total_response_time'] += duration
                    self.stats['avg_response_time'] = self.stats['total_response_time'] / self.stats['queries']
                    
                    return {
                        'success': True,
                        'duration': duration,
                        'response_length': len(result.get('response', '')),
                        'model': result.get('model', model)
                    }
                else:
                    self.stats['errors'] += 1
                    return {
                        'success': False,
                        'error': f"HTTP {response.status}",
                        'duration': 0
                    }
                    
        except Exception as e:
            self.stats['errors'] += 1
            return {
                'success': False,
                'error': str(e),
                'duration': 0
            }
    
    def format_duration(self, seconds: float) -> str:
        """Format duration in human readable format"""
        if seconds < 60:
            return f"{seconds:.0f}s"
        elif seconds < 3600:
            minutes = seconds / 60
            return f"{minutes:.1f}m"
        else:
            hours = seconds / 3600
            return f"{hours:.1f}h"
    
    def print_status(self, health: Dict, system: Dict, gpu: Dict, performance: Dict):
        """Print formatted status"""
        os.system('cls' if os.name == 'nt' else 'clear')
        
        print("🖥️  Ollama Real-time Monitor")
        print("=" * 50)
        print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Ollama Health
        print("🤖 Ollama Status:")
        print(f"   Status: {'🟢' if health['status'] == 'healthy' else '🔴'} {health['status']}")
        print(f"   Models: {health['models_count']}")
        if health['models_count'] > 0:
            print(f"   Available: {', '.join(health['models'][:3])}{'...' if len(health['models']) > 3 else ''}")
        print()
        
        # System Info
        if 'error' not in system:
            print("💻 System Resources:")
            print(f"   CPU: {system['cpu_percent']:.1f}%")
            print(f"   Memory: {system['memory_percent']:.1f}% ({system['memory_available_gb']:.1f}GB free)")
            print(f"   Disk: {system['disk_percent']:.1f}% ({system['disk_free_gb']:.1f}GB free)")
            print()
        
        # GPU Info
        if 'gpus' in gpu:
            print("🎮 GPU Status:")
            for i, gpu_info in enumerate(gpu['gpus']):
                print(f"   GPU {i}: {gpu_info['utilization']}% | Memory: {gpu_info['memory_percent']:.1f}% ({gpu_info['memory_used_mb']}MB/{gpu_info['memory_total_mb']}MB)")
        elif 'ollama_ps' in gpu:
            print("🎮 Ollama GPU:")
            print(f"   {gpu['ollama_ps']}")
        print()
        
        # Performance
        print("⚡ Performance:")
        if performance['success']:
            print(f"   Last Query: {performance['duration']:.0f}ms")
            print(f"   Response Length: {performance['response_length']} chars")
        else:
            print(f"   Last Query: ❌ {performance['error']}")
        
        print(f"   Avg Response Time: {self.stats['avg_response_time']:.0f}ms")
        print(f"   Total Queries: {self.stats['queries']}")
        print(f"   Errors: {self.stats['errors']}")
        print(f"   Uptime: {self.format_duration(time.time() - self.stats['start_time'])}")
        print()
        
        # Quick stats
        if self.stats['queries'] > 0:
            error_rate = (self.stats['errors'] / self.stats['queries']) * 100
            print(f"📊 Error Rate: {error_rate:.1f}%")
    
    async def monitor(self, interval: int = 5):
        """Start monitoring loop"""
        self.monitoring = True
        print("🚀 Starting Ollama Monitor...")
        print(f"📊 Update interval: {interval} seconds")
        print("Press Ctrl+C to stop")
        print()
        
        try:
            while self.monitoring:
                # Gather all metrics
                health = await self.check_ollama_health()
                system = self.get_system_info()
                gpu = self.get_gpu_info()
                performance = await self.test_query_performance()
                
                # Display status
                self.print_status(health, system, gpu, performance)
                
                # Wait for next update
                await asyncio.sleep(interval)
                
        except KeyboardInterrupt:
            print("\n🛑 Monitoring stopped by user")
        except Exception as e:
            print(f"\n❌ Monitoring error: {e}")
        finally:
            self.monitoring = False

async def main():
    """Main monitoring function"""
    print("🎯 Ollama Real-time Monitor")
    print("=" * 40)
    
    interval = 5  # Update every 5 seconds
    
    async with OllamaMonitor() as monitor:
        await monitor.monitor(interval)

if __name__ == "__main__":
    asyncio.run(main()) 