#!/usr/bin/env python3
"""
Ollama Performance Optimizer
Automatically optimizes Ollama configuration for best performance
"""

import asyncio
import aiohttp
import json
import os
import sys
import time
from typing import Dict, List, Optional, Tuple

class OllamaOptimizer:
    def __init__(self, endpoint="http://localhost:11434"):
        self.endpoint = endpoint
        self.session = None
        self.available_models = []
        self.best_model = None
        self.optimization_results = {}
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def discover_models(self) -> List[Dict]:
        """Discover available models and their capabilities"""
        try:
            async with self.session.get(f"{self.endpoint}/api/tags") as response:
                if response.status == 200:
                    data = await response.json()
                    self.available_models = data.get('models', [])
                    return self.available_models
        except Exception as e:
            print(f"❌ Error discovering models: {e}")
            return []
    
    async def test_model_performance(self, model_name: str, test_prompts: List[str]) -> Dict:
        """Test model performance with different configurations"""
        results = {
            'model': model_name,
            'tests': [],
            'average_time': 0,
            'success_rate': 0
        }
        
        # Test configurations
        configs = [
            {'temperature': 0.1, 'num_predict': 20, 'name': 'fast'},
            {'temperature': 0.2, 'num_predict': 100, 'name': 'normal'},
            {'temperature': 0.2, 'num_predict': 200, 'name': 'code'}
        ]
        
        for config in configs:
            config_results = []
            
            for prompt in test_prompts:
                try:
                    start_time = time.time()
                    
                    data = {
                        "model": model_name,
                        "prompt": f"Q: {prompt}\nA:",
                        "stream": False,
                        "options": config
                    }
                    
                    async with self.session.post(
                        f"{self.endpoint}/api/generate",
                        json=data,
                        timeout=aiohttp.ClientTimeout(total=30)
                    ) as response:
                        
                        if response.status == 200:
                            result = await response.json()
                            duration = (time.time() - start_time) * 1000
                            
                            config_results.append({
                                'prompt': prompt,
                                'duration': duration,
                                'success': True,
                                'response_length': len(result.get('response', ''))
                            })
                        else:
                            config_results.append({
                                'prompt': prompt,
                                'duration': 0,
                                'success': False,
                                'error': f"HTTP {response.status}"
                            })
                            
                except Exception as e:
                    config_results.append({
                        'prompt': prompt,
                        'duration': 0,
                        'success': False,
                        'error': str(e)
                    })
            
            # Calculate averages for this config
            successful_tests = [r for r in config_results if r['success']]
            if successful_tests:
                avg_time = sum(r['duration'] for r in successful_tests) / len(successful_tests)
                success_rate = len(successful_tests) / len(config_results) * 100
            else:
                avg_time = 0
                success_rate = 0
            
            results['tests'].append({
                'config': config,
                'results': config_results,
                'average_time': avg_time,
                'success_rate': success_rate
            })
        
        # Overall averages
        all_successful = [r for test in results['tests'] for r in test['results'] if r['success']]
        if all_successful:
            results['average_time'] = sum(r['duration'] for r in all_successful) / len(all_successful)
            results['success_rate'] = len(all_successful) / (len(results['tests']) * len(test_prompts)) * 100
        
        return results
    
    def select_best_model(self, performance_results: List[Dict]) -> Optional[str]:
        """Select the best model based on performance results"""
        if not performance_results:
            return None
        
        # Score each model based on speed and success rate
        scored_models = []
        
        for result in performance_results:
            # Prefer faster models with high success rate
            speed_score = 1000 / (result['average_time'] + 1)  # Avoid division by zero
            success_score = result['success_rate']
            total_score = speed_score * success_score / 100
            
            scored_models.append({
                'model': result['model'],
                'score': total_score,
                'avg_time': result['average_time'],
                'success_rate': result['success_rate']
            })
        
        # Sort by score (highest first)
        scored_models.sort(key=lambda x: x['score'], reverse=True)
        
        if scored_models:
            best = scored_models[0]
            print(f"🏆 Best model: {best['model']}")
            print(f"   Score: {best['score']:.2f}")
            print(f"   Avg time: {best['avg_time']:.0f}ms")
            print(f"   Success rate: {best['success_rate']:.1f}%")
            return best['model']
        
        return None
    
    def generate_optimization_report(self, performance_results: List[Dict]) -> str:
        """Generate optimization report"""
        report = "# Ollama Performance Optimization Report\n\n"
        
        for result in performance_results:
            report += f"## Model: {result['model']}\n\n"
            report += f"- **Average Time**: {result['average_time']:.0f}ms\n"
            report += f"- **Success Rate**: {result['success_rate']:.1f}%\n\n"
            
            for test in result['tests']:
                config = test['config']
                report += f"### {config['name'].title()} Config\n"
                report += f"- Temperature: {config['temperature']}\n"
                report += f"- Tokens: {config['num_predict']}\n"
                report += f"- Avg Time: {test['average_time']:.0f}ms\n"
                report += f"- Success Rate: {test['success_rate']:.1f}%\n\n"
        
        return report
    
    async def optimize(self) -> Dict:
        """Main optimization process"""
        print("🚀 Starting Ollama Performance Optimization...")
        
        # Discover models
        print("📋 Discovering available models...")
        models = await self.discover_models()
        
        if not models:
            return {"error": "No models found"}
        
        print(f"✅ Found {len(models)} models")
        
        # Test prompts
        test_prompts = [
            "What is 2+2?",
            "Write a simple Python function",
            "Explain recursion briefly"
        ]
        
        # Test each model
        performance_results = []
        for model_info in models:
            model_name = model_info['name']
            print(f"🧪 Testing model: {model_name}")
            
            result = await self.test_model_performance(model_name, test_prompts)
            performance_results.append(result)
            
            print(f"   ✅ Completed - Avg: {result['average_time']:.0f}ms, Success: {result['success_rate']:.1f}%")
        
        # Select best model
        self.best_model = self.select_best_model(performance_results)
        
        # Generate report
        report = self.generate_optimization_report(performance_results)
        
        # Save report
        with open("optimization_report.md", "w", encoding="utf-8") as f:
            f.write(report)
        
        # Generate optimized configuration
        optimized_config = self.generate_optimized_config(performance_results)
        
        return {
            'best_model': self.best_model,
            'performance_results': performance_results,
            'report': report,
            'optimized_config': optimized_config
        }
    
    def generate_optimized_config(self, performance_results: List[Dict]) -> Dict:
        """Generate optimized configuration based on test results"""
        if not self.best_model:
            return {}
        
        # Find the best model's results
        best_result = next((r for r in performance_results if r['model'] == self.best_model), None)
        if not best_result:
            return {}
        
        # Find best config for each use case
        fast_config = None
        normal_config = None
        code_config = None
        
        for test in best_result['tests']:
            config_name = test['config']['name']
            if config_name == 'fast' and test['success_rate'] > 80:
                fast_config = test['config']
            elif config_name == 'normal' and test['success_rate'] > 80:
                normal_config = test['config']
            elif config_name == 'code' and test['success_rate'] > 80:
                code_config = test['config']
        
        return {
            'model': self.best_model,
            'fast': fast_config or {'temperature': 0.1, 'num_predict': 20},
            'normal': normal_config or {'temperature': 0.2, 'num_predict': 100},
            'code': code_config or {'temperature': 0.2, 'num_predict': 200}
        }

async def main():
    """Main optimization function"""
    print("🎯 Ollama Performance Optimizer")
    print("=" * 40)
    
    async with OllamaOptimizer() as optimizer:
        results = await optimizer.optimize()
        
        if 'error' in results:
            print(f"❌ Error: {results['error']}")
            return
        
        print("\n" + "=" * 40)
        print("✅ Optimization Complete!")
        print(f"🏆 Best Model: {results['best_model']}")
        print(f"📊 Report saved: optimization_report.md")
        
        # Show optimized config
        config = results['optimized_config']
        if config:
            print("\n🎛️ Optimized Configuration:")
            print(f"Model: {config['model']}")
            print(f"Fast: temp={config['fast']['temperature']}, tokens={config['fast']['num_predict']}")
            print(f"Normal: temp={config['normal']['temperature']}, tokens={config['normal']['num_predict']}")
            print(f"Code: temp={config['code']['temperature']}, tokens={config['code']['num_predict']}")

if __name__ == "__main__":
    asyncio.run(main()) 