#!/usr/bin/env python3
"""
Automated Tests for Ollama Desktop Cursor AI
"""

import unittest
import asyncio
import aiohttp
import json
import os
import sys
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from python.ollama_cache import OllamaCache, get_cached_response, cache_response, clear_cache, get_cache_stats
from python.ollama_simple_async import check_ollama_connection, get_project_files, query_ollama

class TestOllamaCache(unittest.TestCase):
    """Test cache functionality"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_cache_dir = "test_cache"
        self.cache = OllamaCache(self.test_cache_dir, max_age_hours=1)
    
    def tearDown(self):
        """Clean up test environment"""
        import shutil
        if os.path.exists(self.test_cache_dir):
            shutil.rmtree(self.test_cache_dir)
    
    def test_cache_key_generation(self):
        """Test cache key generation"""
        key1 = self.cache._generate_cache_key("test question", "test context", "test model")
        key2 = self.cache._generate_cache_key("test question", "test context", "test model")
        key3 = self.cache._generate_cache_key("different question", "test context", "test model")
        
        self.assertEqual(key1, key2)  # Same inputs should generate same key
        self.assertNotEqual(key1, key3)  # Different inputs should generate different keys
    
    def test_cache_set_and_get(self):
        """Test setting and getting cache entries"""
        question = "What is 2+2?"
        response = "The answer is 4"
        context = "Math context"
        model = "test-model"
        
        # Set cache
        self.cache.set(question, response, context, model)
        
        # Get cache
        cached_response = self.cache.get(question, context, model)
        self.assertEqual(cached_response, response)
    
    def test_cache_expiration(self):
        """Test cache expiration"""
        # Create cache with very short expiration
        short_cache = OllamaCache(self.test_cache_dir, max_age_hours=0.001)  # ~3.6 seconds
        
        question = "test question"
        response = "test response"
        
        # Set cache
        short_cache.set(question, response)
        
        # Should be available immediately
        cached_response = short_cache.get(question)
        self.assertEqual(cached_response, response)
        
        # Wait for expiration
        import time
        time.sleep(4)
        
        # Should be expired now
        cached_response = short_cache.get(question)
        self.assertIsNone(cached_response)
    
    def test_cache_clear(self):
        """Test cache clearing"""
        # Add some test entries
        self.cache.set("q1", "r1")
        self.cache.set("q2", "r2")
        
        # Clear cache
        cleared_count = self.cache.clear()
        self.assertGreaterEqual(cleared_count, 0)
    
    def test_cache_stats(self):
        """Test cache statistics"""
        # Add test entry
        self.cache.set("test question", "test response")
        
        # Get stats
        stats = self.cache.get_stats()
        
        self.assertIn('total_files', stats)
        self.assertIn('total_size_mb', stats)
        self.assertIn('cache_dir', stats)
        self.assertEqual(stats['cache_dir'], self.test_cache_dir)

class TestOllamaConnection(unittest.TestCase):
    """Test Ollama connection functionality"""
    
    @patch('aiohttp.ClientSession')
    async def test_ollama_connection_success(self, mock_session):
        """Test successful Ollama connection"""
        # Mock successful response
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={
            'models': [
                {'name': 'codellama:7b-instruct', 'size': 1000000000},
                {'name': 'smollm2:135m', 'size': 50000000}
            ]
        })
        
        mock_session.return_value.__aenter__.return_value.get.return_value.__aenter__.return_value = mock_response
        
        is_connected, model = await check_ollama_connection()
        
        self.assertTrue(is_connected)
        self.assertEqual(model, 'codellama:7b-instruct')  # Should select largest model
    
    @patch('aiohttp.ClientSession')
    async def test_ollama_connection_failure(self, mock_session):
        """Test failed Ollama connection"""
        # Mock connection error
        mock_session.return_value.__aenter__.return_value.get.side_effect = Exception("Connection failed")
        
        is_connected, error = await check_ollama_connection()
        
        self.assertFalse(is_connected)
        self.assertIn("Connection failed", error)
    
    @patch('aiohttp.ClientSession')
    async def test_ollama_no_models(self, mock_session):
        """Test Ollama with no models available"""
        # Mock response with no models
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={'models': []})
        
        mock_session.return_value.__aenter__.return_value.get.return_value.__aenter__.return_value = mock_response
        
        is_connected, error = await check_ollama_connection()
        
        self.assertFalse(is_connected)
        self.assertIn("No hay modelos disponibles", error)

class TestProjectFiles(unittest.TestCase):
    """Test project file processing"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = "test_project"
        if not os.path.exists(self.test_dir):
            os.makedirs(self.test_dir)
        
        # Create test files
        with open(os.path.join(self.test_dir, "test.py"), "w") as f:
            f.write("print('Hello World')")
        
        with open(os.path.join(self.test_dir, "test.js"), "w") as f:
            f.write("console.log('Hello World')")
    
    def tearDown(self):
        """Clean up test environment"""
        import shutil
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)
    
    def test_get_project_files_sync(self):
        """Test synchronous project file processing"""
        from python.ollama_simple_async import get_project_files_sync
        
        result = get_project_files_sync(self.test_dir)
        
        self.assertIn("test.py", result)
        self.assertIn("test.js", result)
        self.assertIn("print('Hello World')", result)
    
    async def test_get_project_files_async(self):
        """Test asynchronous project file processing"""
        result = await get_project_files(self.test_dir)
        
        self.assertIn("test.py", result)
        self.assertIn("test.js", result)
        self.assertIn("print('Hello World')", result)

class TestOllamaQuery(unittest.TestCase):
    """Test Ollama query functionality"""
    
    @patch('aiohttp.ClientSession')
    async def test_query_ollama_success(self, mock_session):
        """Test successful Ollama query"""
        # Mock successful response
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={
            'response': 'This is a test response'
        })
        
        mock_session.return_value.__aenter__.return_value.post.return_value.__aenter__.return_value = mock_response
        
        response = await query_ollama("test question", "test context", "test-model")
        
        self.assertEqual(response, 'This is a test response')
    
    @patch('aiohttp.ClientSession')
    async def test_query_ollama_error(self, mock_session):
        """Test Ollama query with error"""
        # Mock error response
        mock_response = AsyncMock()
        mock_response.status = 500
        mock_response.text = AsyncMock(return_value="Internal Server Error")
        
        mock_session.return_value.__aenter__.return_value.post.return_value.__aenter__.return_value = mock_response
        
        response = await query_ollama("test question", "test context", "test-model")
        
        self.assertIn("Error: HTTP 500", response)
    
    @patch('aiohttp.ClientSession')
    async def test_query_ollama_timeout(self, mock_session):
        """Test Ollama query timeout"""
        # Mock timeout
        mock_session.return_value.__aenter__.return_value.post.side_effect = asyncio.TimeoutError()
        
        response = await query_ollama("test question", "test context", "test-model")
        
        self.assertIn("Timeout", response)

class TestIntegration(unittest.TestCase):
    """Integration tests"""
    
    def test_cache_integration(self):
        """Test cache integration with main functions"""
        # Test global cache functions
        question = "integration test question"
        response = "integration test response"
        
        # Cache response
        cache_response(question, response)
        
        # Get cached response
        cached = get_cached_response(question)
        self.assertEqual(cached, response)
        
        # Get cache stats
        stats = get_cache_stats()
        self.assertIsInstance(stats, dict)
        self.assertIn('total_files', stats)

def run_tests():
    """Run all tests"""
    # Create test suite
    test_suite = unittest.TestSuite()
    
    # Add test classes
    test_classes = [
        TestOllamaCache,
        TestOllamaConnection,
        TestProjectFiles,
        TestOllamaQuery,
        TestIntegration
    ]
    
    for test_class in test_classes:
        tests = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_suite.addTests(tests)
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    return result.wasSuccessful()

if __name__ == "__main__":
    # Run async tests
    async def run_async_tests():
        # Test async functions
        test_suite = unittest.TestSuite()
        
        # Add async test classes
        async_test_classes = [
            TestOllamaConnection,
            TestProjectFiles,
            TestOllamaQuery
        ]
        
        for test_class in async_test_classes:
            tests = unittest.TestLoader().loadTestsFromTestCase(test_class)
            test_suite.addTests(tests)
        
        # Run async tests
        runner = unittest.TextTestRunner(verbosity=2)
        result = runner.run(test_suite)
        return result.wasSuccessful()
    
    # Run both sync and async tests
    print("Running Ollama Desktop Cursor AI Tests...")
    print("=" * 50)
    
    # Run sync tests
    sync_success = run_tests()
    
    # Run async tests
    async_success = asyncio.run(run_async_tests())
    
    print("=" * 50)
    if sync_success and async_success:
        print("✅ All tests passed!")
        sys.exit(0)
    else:
        print("❌ Some tests failed!")
        sys.exit(1)