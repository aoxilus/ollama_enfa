#!/usr/bin/env python3
"""
Ollama Cache System - Improve performance with response caching
"""

import hashlib
import json
import os
import time
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

class OllamaCache:
    def __init__(self, cache_dir: str = "cache", max_age_hours: int = 24):
        self.cache_dir = cache_dir
        self.max_age_seconds = max_age_hours * 3600
        self._ensure_cache_dir()
    
    def _ensure_cache_dir(self):
        """Ensure cache directory exists"""
        if not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir)
    
    def _generate_cache_key(self, question: str, context: str = "", model: str = "") -> str:
        """Generate unique cache key from question, context and model"""
        content = f"{question}|{context}|{model}"
        return hashlib.md5(content.encode('utf-8')).hexdigest()
    
    def _get_cache_file_path(self, cache_key: str) -> str:
        """Get full path for cache file"""
        return os.path.join(self.cache_dir, f"{cache_key}.json")
    
    def get(self, question: str, context: str = "", model: str = "") -> Optional[str]:
        """Get cached response if available and not expired"""
        cache_key = self._generate_cache_key(question, context, model)
        cache_file = self._get_cache_file_path(cache_key)
        
        if not os.path.exists(cache_file):
            return None
        
        try:
            with open(cache_file, 'r', encoding='utf-8') as f:
                cache_data = json.load(f)
            
            # Check if cache is expired
            cache_time = datetime.fromisoformat(cache_data['timestamp'])
            if datetime.now() - cache_time > timedelta(seconds=self.max_age_seconds):
                os.remove(cache_file)  # Remove expired cache
                return None
            
            return cache_data['response']
            
        except (json.JSONDecodeError, KeyError, OSError):
            # Remove corrupted cache file
            if os.path.exists(cache_file):
                os.remove(cache_file)
            return None
    
    def set(self, question: str, response: str, context: str = "", model: str = ""):
        """Cache response with metadata"""
        cache_key = self._generate_cache_key(question, context, model)
        cache_file = self._get_cache_file_path(cache_key)
        
        cache_data = {
            'question': question,
            'response': response,
            'context': context,
            'model': model,
            'timestamp': datetime.now().isoformat(),
            'cache_key': cache_key
        }
        
        try:
            with open(cache_file, 'w', encoding='utf-8') as f:
                json.dump(cache_data, f, ensure_ascii=False, indent=2)
        except OSError as e:
            print(f"⚠️ Warning: Could not cache response: {e}")
    
    def clear(self, max_age_hours: Optional[int] = None):
        """Clear expired cache entries"""
        if max_age_hours is None:
            max_age_hours = self.max_age_seconds // 3600
        
        max_age_seconds = max_age_hours * 3600
        cleared_count = 0
        
        for filename in os.listdir(self.cache_dir):
            if not filename.endswith('.json'):
                continue
            
            file_path = os.path.join(self.cache_dir, filename)
            try:
                file_time = os.path.getmtime(file_path)
                if time.time() - file_time > max_age_seconds:
                    os.remove(file_path)
                    cleared_count += 1
            except OSError:
                continue
        
        return cleared_count
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        total_files = 0
        total_size = 0
        oldest_file = None
        newest_file = None
        
        for filename in os.listdir(self.cache_dir):
            if not filename.endswith('.json'):
                continue
            
            file_path = os.path.join(self.cache_dir, filename)
            try:
                file_stat = os.stat(file_path)
                total_files += 1
                total_size += file_stat.st_size
                
                file_time = datetime.fromtimestamp(file_stat.st_mtime)
                if oldest_file is None or file_time < oldest_file:
                    oldest_file = file_time
                if newest_file is None or file_time > newest_file:
                    newest_file = file_time
            except OSError:
                continue
        
        return {
            'total_files': total_files,
            'total_size_mb': round(total_size / (1024 * 1024), 2),
            'oldest_file': oldest_file.isoformat() if oldest_file else None,
            'newest_file': newest_file.isoformat() if newest_file else None,
            'cache_dir': self.cache_dir,
            'max_age_hours': self.max_age_seconds // 3600
        }

# Global cache instance
_cache = OllamaCache()

def get_cached_response(question: str, context: str = "", model: str = "") -> Optional[str]:
    """Get cached response if available"""
    return _cache.get(question, context, model)

def cache_response(question: str, response: str, context: str = "", model: str = ""):
    """Cache response for future use"""
    _cache.set(question, response, context, model)

def clear_cache(max_age_hours: Optional[int] = None) -> int:
    """Clear expired cache entries"""
    return _cache.clear(max_age_hours)

def get_cache_stats() -> Dict[str, Any]:
    """Get cache statistics"""
    return _cache.get_stats()