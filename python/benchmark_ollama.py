#!/usr/bin/env python3
"""
Ollama Benchmark Tool
Compare performance across different models and configurations
"""

import asyncio
import aiohttp
import json
import time
import statistics
from typing import Dict, List, Tuple
from datetime import datetime

class OllamaBenchmark:
    def __init__(self, endpoint="http://localhost:11434"):
        self.endpoint = endpoint
        self.session = None
        self.results = {}
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def benchmark_query(self, model: str, prompt: str, config: Dict, iterations: int = 3) -> Dict:
        """Benchmark a single query configuration"""
        times = []
        success_count = 0
        errors = []
        
        for i in range(iterations):
            try:
                start_time = time.time()
                
                data = {
                    "model": model,
                    "prompt": prompt,
                    "stream": False,
                    "options": config
                }
                
                async with self.session.post(
                    f"{self.endpoint}/api/generate",
                    json=data,
                    timeout=aiohttp.ClientTimeout(total=60)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        duration = (time.time() - start_time) * 1000
                        times.append(duration)
                        success_count += 1
                    else:
                        errors.append(f"HTTP {response.status}")
                        
            except Exception as e:
                errors.append(str(e))
        
        if times:
            return {
                'success': True,
                'times': times,
                'avg_time': statistics.mean(times),
                'min_time': min(times),
                'max_time': max(times),
                'std_dev': statistics.stdev(times) if len(times) > 1 else 0,
                'success_rate': success_count / iterations * 100,
                'errors': errors
            }
        else:
            return {
                'success': False,
                'times': [],
                'avg_time': 0,
                'min_time': 0,
                'max_time': 0,
                'std_dev': 0,
                'success_rate': 0,
                'errors': errors
            }
    
    async def run_benchmark(self, models: List[str], test_cases: List[Dict]) -> Dict:
        """Run comprehensive benchmark"""
        print("🚀 Starting Ollama Benchmark...")
        print(f"📋 Testing {len(models)} models with {len(test_cases)} configurations")
        
        all_results = {}
        
        for model in models:
            print(f"\n🧪 Benchmarking model: {model}")
            model_results = {}
            
            for i, test_case in enumerate(test_cases):
                print(f"   Test {i+1}/{len(test_cases)}: {test_case['name']}")
                
                result = await self.benchmark_query(
                    model=model,
                    prompt=test_case['prompt'],
                    config=test_case['config'],
                    iterations=test_case.get('iterations', 3)
                )
                
                model_results[test_case['name']] = result
                
                if result['success']:
                    print(f"     ✅ Avg: {result['avg_time']:.0f}ms (±{result['std_dev']:.0f}ms)")
                else:
                    print(f"     ❌ Failed: {result['errors']}")
            
            all_results[model] = model_results
        
        return all_results
    
    def generate_report(self, results: Dict) -> str:
        """Generate benchmark report"""
        report = f"# Ollama Benchmark Report\n\n"
        report += f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        # Summary table
        report += "## Performance Summary\n\n"
        report += "| Model | Test | Avg Time (ms) | Min | Max | Std Dev | Success Rate |\n"
        report += "|-------|------|---------------|-----|-----|---------|--------------|\n"
        
        for model, model_results in results.items():
            for test_name, test_result in model_results.items():
                if test_result['success']:
                    report += f"| {model} | {test_name} | {test_result['avg_time']:.0f} | {test_result['min_time']:.0f} | {test_result['max_time']:.0f} | {test_result['std_dev']:.0f} | {test_result['success_rate']:.1f}% |\n"
                else:
                    report += f"| {model} | {test_name} | ❌ | ❌ | ❌ | ❌ | 0% |\n"
        
        # Detailed results
        report += "\n## Detailed Results\n\n"
        
        for model, model_results in results.items():
            report += f"### {model}\n\n"
            
            for test_name, test_result in model_results.items():
                report += f"#### {test_name}\n\n"
                
                if test_result['success']:
                    report += f"- **Average Time**: {test_result['avg_time']:.0f}ms\n"
                    report += f"- **Range**: {test_result['min_time']:.0f}ms - {test_result['max_time']:.0f}ms\n"
                    report += f"- **Standard Deviation**: {test_result['std_dev']:.0f}ms\n"
                    report += f"- **Success Rate**: {test_result['success_rate']:.1f}%\n"
                    report += f"- **Individual Times**: {', '.join(f'{t:.0f}ms' for t in test_result['times'])}\n\n"
                else:
                    report += f"- **Status**: Failed\n"
                    report += f"- **Errors**: {', '.join(test_result['errors'])}\n\n"
        
        return report
    
    def find_best_configurations(self, results: Dict) -> Dict:
        """Find best configurations for each use case"""
        best_configs = {}
        
        # Group by test type
        test_types = {}
        for model, model_results in results.items():
            for test_name, test_result in model_results.items():
                if test_result['success']:
                    if test_name not in test_types:
                        test_types[test_name] = []
                    test_types[test_name].append({
                        'model': model,
                        'avg_time': test_result['avg_time'],
                        'success_rate': test_result['success_rate']
                    })
        
        # Find best for each test type
        for test_name, test_results in test_types.items():
            if test_results:
                # Sort by speed (faster is better)
                test_results.sort(key=lambda x: x['avg_time'])
                best_configs[test_name] = test_results[0]
        
        return best_configs

async def main():
    """Main benchmark function"""
    print("🎯 Ollama Benchmark Tool")
    print("=" * 40)
    
    # Test configurations
    test_cases = [
        {
            'name': 'Fast Question',
            'prompt': 'What is 2+2?',
            'config': {'temperature': 0.1, 'num_predict': 20},
            'iterations': 5
        },
        {
            'name': 'Code Generation',
            'prompt': 'Write a Python function to calculate factorial',
            'config': {'temperature': 0.2, 'num_predict': 200},
            'iterations': 3
        },
        {
            'name': 'General Chat',
            'prompt': 'Explain the concept of recursion in programming',
            'config': {'temperature': 0.7, 'num_predict': 100},
            'iterations': 3
        }
    ]
    
    # Get available models
    async with OllamaBenchmark() as benchmark:
        try:
            async with benchmark.session.get(f"{benchmark.endpoint}/api/tags") as response:
                if response.status == 200:
                    data = await response.json()
                    models = [model['name'] for model in data.get('models', [])]
                else:
                    print("❌ Could not fetch models")
                    return
        except Exception as e:
            print(f"❌ Error connecting to Ollama: {e}")
            return
        
        if not models:
            print("❌ No models found")
            return
        
        print(f"📋 Available models: {', '.join(models)}")
        
        # Run benchmark
        results = await benchmark.run_benchmark(models, test_cases)
        
        # Generate report
        report = benchmark.generate_report(results)
        
        # Save report
        with open("benchmark_report.md", "w", encoding="utf-8") as f:
            f.write(report)
        
        # Find best configurations
        best_configs = benchmark.find_best_configurations(results)
        
        # Print summary
        print("\n" + "=" * 40)
        print("✅ Benchmark Complete!")
        print(f"📊 Report saved: benchmark_report.md")
        
        print("\n🏆 Best Configurations:")
        for test_name, best in best_configs.items():
            print(f"  {test_name}: {best['model']} ({best['avg_time']:.0f}ms, {best['success_rate']:.1f}%)")

if __name__ == "__main__":
    asyncio.run(main()) 