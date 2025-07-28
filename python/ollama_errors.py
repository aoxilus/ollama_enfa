#!/usr/bin/env python3
"""
Ollama Error Handling System - Improve robustness with comprehensive error handling
"""

import asyncio
import aiohttp
import json
import os
import sys
import traceback
from datetime import datetime
from typing import Optional, Dict, Any, Union
from enum import Enum

class ErrorType(Enum):
    """Error types for categorization"""
    CONNECTION = "connection"
    TIMEOUT = "timeout"
    AUTHENTICATION = "authentication"
    VALIDATION = "validation"
    RATE_LIMIT = "rate_limit"
    MODEL_NOT_FOUND = "model_not_found"
    INVALID_RESPONSE = "invalid_response"
    FILE_SYSTEM = "file_system"
    NETWORK = "network"
    UNKNOWN = "unknown"

class OllamaError(Exception):
    """Base exception for Ollama-related errors"""
    
    def __init__(self, message: str, error_type: ErrorType, details: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.error_type = error_type
        self.details = details or {}
        self.timestamp = datetime.now()
    
    def __str__(self):
        return f"[{self.error_type.value.upper()}] {super().__str__()}"
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert error to dictionary for logging"""
        return {
            'error_type': self.error_type.value,
            'message': str(self),
            'details': self.details,
            'timestamp': self.timestamp.isoformat()
        }

class ConnectionError(OllamaError):
    """Connection-related errors"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, ErrorType.CONNECTION, details)

class TimeoutError(OllamaError):
    """Timeout-related errors"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, ErrorType.TIMEOUT, details)

class ValidationError(OllamaError):
    """Validation-related errors"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, ErrorType.VALIDATION, details)

class ModelNotFoundError(OllamaError):
    """Model not found errors"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, ErrorType.MODEL_NOT_FOUND, details)

class RateLimitError(OllamaError):
    """Rate limiting errors"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, ErrorType.RATE_LIMIT, details)

class ErrorHandler:
    """Centralized error handling system"""
    
    def __init__(self, log_file: str = "logs/errors.log"):
        self.log_file = log_file
        self.error_count = 0
        self.error_stats = {error_type.value: 0 for error_type in ErrorType}
        self._ensure_log_dir()
    
    def _ensure_log_dir(self):
        """Ensure log directory exists"""
        log_dir = os.path.dirname(self.log_file)
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir)
    
    def handle_error(self, error: Exception, context: Optional[Dict[str, Any]] = None) -> str:
        """Handle and log error, return user-friendly message"""
        self.error_count += 1
        
        # Convert to OllamaError if needed
        if not isinstance(error, OllamaError):
            error = self._classify_error(error)
        
        # Update stats
        self.error_stats[error.error_type.value] += 1
        
        # Log error
        self._log_error(error, context)
        
        # Return user-friendly message
        return self._get_user_message(error)
    
    def _classify_error(self, error: Exception) -> OllamaError:
        """Classify generic exceptions into specific OllamaError types"""
        error_str = str(error).lower()
        
        if isinstance(error, asyncio.TimeoutError):
            return TimeoutError("La operación tardó demasiado en completarse", {
                'original_error': str(error),
                'error_type': type(error).__name__
            })
        
        if isinstance(error, aiohttp.ClientError):
            if "timeout" in error_str:
                return TimeoutError("Timeout de conexión con Ollama", {
                    'original_error': str(error),
                    'error_type': type(error).__name__
                })
            elif "connection" in error_str:
                return ConnectionError("No se puede conectar a Ollama", {
                    'original_error': str(error),
                    'error_type': type(error).__name__
                })
            else:
                return ConnectionError("Error de red con Ollama", {
                    'original_error': str(error),
                    'error_type': type(error).__name__
                })
        
        if isinstance(error, FileNotFoundError):
            return ValidationError("Archivo no encontrado", {
                'original_error': str(error),
                'error_type': type(error).__name__
            })
        
        if isinstance(error, PermissionError):
            return ValidationError("Error de permisos", {
                'original_error': str(error),
                'error_type': type(error).__name__
            })
        
        # Default to unknown error
        return OllamaError(f"Error inesperado: {str(error)}", ErrorType.UNKNOWN, {
            'original_error': str(error),
            'error_type': type(error).__name__
        })
    
    def _log_error(self, error: OllamaError, context: Optional[Dict[str, Any]] = None):
        """Log error to file"""
        log_entry = {
            'error': error.to_dict(),
            'context': context or {},
            'traceback': traceback.format_exc()
        }
        
        try:
            with open(self.log_file, 'a', encoding='utf-8') as f:
                f.write(f"{datetime.now().isoformat()} - {json.dumps(log_entry, ensure_ascii=False)}\n")
        except Exception as e:
            # Fallback to stderr if logging fails
            print(f"Error logging failed: {e}", file=sys.stderr)
            print(f"Original error: {error}", file=sys.stderr)
    
    def _get_user_message(self, error: OllamaError) -> str:
        """Get user-friendly error message"""
        messages = {
            ErrorType.CONNECTION: "❌ No se puede conectar a Ollama. Verifica que esté ejecutándose.",
            ErrorType.TIMEOUT: "⏰ La operación tardó demasiado. Intenta de nuevo.",
            ErrorType.AUTHENTICATION: "🔐 Error de autenticación. Verifica tu configuración.",
            ErrorType.VALIDATION: "⚠️ Error de validación. Verifica los datos de entrada.",
            ErrorType.RATE_LIMIT: "🚫 Demasiadas consultas. Espera un momento.",
            ErrorType.MODEL_NOT_FOUND: "🤖 Modelo no encontrado. Verifica que esté instalado.",
            ErrorType.INVALID_RESPONSE: "📡 Respuesta inválida del servidor.",
            ErrorType.FILE_SYSTEM: "📁 Error del sistema de archivos.",
            ErrorType.NETWORK: "🌐 Error de red. Verifica tu conexión.",
            ErrorType.UNKNOWN: "❓ Error inesperado. Revisa los logs para más detalles."
        }
        
        return messages.get(error.error_type, messages[ErrorType.UNKNOWN])
    
    def get_stats(self) -> Dict[str, Any]:
        """Get error statistics"""
        return {
            'total_errors': self.error_count,
            'error_types': self.error_stats,
            'log_file': self.log_file
        }
    
    def clear_stats(self):
        """Clear error statistics"""
        self.error_count = 0
        self.error_stats = {error_type.value: 0 for error_type in ErrorType}

# Global error handler instance
_error_handler = ErrorHandler()

def handle_error(error: Exception, context: Optional[Dict[str, Any]] = None) -> str:
    """Global error handling function"""
    return _error_handler.handle_error(error, context)

def get_error_stats() -> Dict[str, Any]:
    """Get error statistics"""
    return _error_handler.get_stats()

def clear_error_stats():
    """Clear error statistics"""
    _error_handler.clear_stats()

# Decorator for automatic error handling
def error_handler(func):
    """Decorator to automatically handle errors in functions"""
    async def async_wrapper(*args, **kwargs):
        try:
            return await func(*args, **kwargs)
        except Exception as e:
            context = {
                'function': func.__name__,
                'args': str(args),
                'kwargs': str(kwargs)
            }
            error_message = handle_error(e, context)
            print(error_message)
            return None
    
    def sync_wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            context = {
                'function': func.__name__,
                'args': str(args),
                'kwargs': str(kwargs)
            }
            error_message = handle_error(e, context)
            print(error_message)
            return None
    
    if asyncio.iscoroutinefunction(func):
        return async_wrapper
    else:
        return sync_wrapper

# Validation functions
def validate_question(question: str) -> bool:
    """Validate question input"""
    if not question or not question.strip():
        return False
    
    if len(question.strip()) < 3:
        return False
    
    if len(question) > 10000:
        return False
    
    return True

def validate_model(model: str) -> bool:
    """Validate model name"""
    if not model or not model.strip():
        return False
    
    # Check for potentially dangerous characters
    dangerous_chars = ['<', '>', '"', "'", '&', '|', ';', '`']
    for char in dangerous_chars:
        if char in model:
            return False
    
    return True

def validate_file_path(file_path: str) -> bool:
    """Validate file path"""
    if not file_path or not file_path.strip():
        return True  # Empty path is valid (current directory)
    
    # Check for path traversal attempts
    if '..' in file_path or file_path.startswith('/'):
        return False
    
    # Check if file exists
    if not os.path.exists(file_path):
        return False
    
    return True

# Retry mechanism
async def retry_operation(operation, max_retries: int = 3, delay: float = 1.0):
    """Retry operation with exponential backoff"""
    last_error = None
    
    for attempt in range(max_retries):
        try:
            return await operation()
        except (ConnectionError, TimeoutError) as e:
            last_error = e
            if attempt < max_retries - 1:
                wait_time = delay * (2 ** attempt)  # Exponential backoff
                print(f"⚠️ Intento {attempt + 1} falló. Reintentando en {wait_time}s...")
                await asyncio.sleep(wait_time)
            else:
                break
        except Exception as e:
            # Don't retry other types of errors
            raise e
    
    # If we get here, all retries failed
    raise last_error

# Health check functions
async def check_ollama_health() -> Dict[str, Any]:
    """Check Ollama service health"""
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get("http://localhost:11434/api/tags", timeout=5) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        'status': 'healthy',
                        'models_count': len(data.get('models', [])),
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

def get_system_info() -> Dict[str, Any]:
    """Get system information for debugging"""
    return {
        'python_version': sys.version,
        'platform': sys.platform,
        'current_directory': os.getcwd(),
        'environment_variables': {
            'OLLAMA_HOST': os.environ.get('OLLAMA_HOST', 'not set'),
            'OLLAMA_ORIGINS': os.environ.get('OLLAMA_ORIGINS', 'not set')
        }
    }