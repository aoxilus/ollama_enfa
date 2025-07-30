# Ollama Desktop Cursor AI

> **Developed by aoxilus** to connect local Ollama AI with Cursor AI and development tools. Complete integration between SDKs and terminal for local Ollama usage with GPU optimization.

---

# Ollama Desktop Cursor AI

> **Desarrollado por aoxilus** para conectar Ollama AI local con Cursor AI y herramientas de desarrollo. Integración completa entre SDKs y terminal para uso local de Ollama con optimización GPU.

---

## 🚀 Current Status - Optimized / Estado Actual - Optimizado

### ✅ **Implemented Improvements / Mejoras Implementadas:**
- **GPU Acceleration**: 100% GPU utilization with codellama:7b-code-q4_K_M
- **Fast Responses**: 669ms for simple questions, 3.4s for code
- **Automatic Validation**: Response quality verification
- **Optimized Prompts**: Enhanced structure for different query types
- **Adjusted Parameters**: Temperature and tokens optimized by question type

### 🎯 **Main Model / Modelo Principal:**
- **Model**: `codellama:7b-code-q4_K_M`
- **GPU**: 100% utilization
- **Speed**: Responses in <1s for simple questions
- **Quality**: Coherent and precise responses

---

## What is this project? / ¿Qué es este proyecto?

This project is an **intelligent integration** between Ollama (local AI) and Cursor AI (code editor) that enables:

Este proyecto es una **integración inteligente** entre Ollama (IA local) y Cursor AI (editor de código) que permite:

- 🔗 **Direct connection** between your editor and local AI models
- 📁 **Automatic context analysis** of your project
- 💾 **Smart cache** for fast responses
- 🛠️ **Enhanced development tools** with local AI
- 🔄 **Configurable sync/async mode**
- 🚀 **GPU optimization** for maximum speed
- ✅ **Automatic response validation**

---

## Why was it developed? / ¿Por qué se desarrolló?

- **Privacy**: Use local AI without sending code to external servers
- **Speed**: Instant responses without network latency
- **Context**: Deep analysis of your specific project
- **Flexibility**: Works with any Ollama model
- **Integration**: Connects with Cursor AI and other editors
- **GPU**: Leverages your hardware for maximum speed

---

## Quick Usage - Optimized / Uso Rápido - Optimizado

### 🚀 Fast Test (Recommended) / Test Rápido (Recomendado)
```bash
# Simple questions - 669ms / Preguntas simples - 669ms
python tests/test_fast.py codellama:7b-code-q4_K_M "What is 2+2?"

# Code - 3.4s / Código - 3.4s
python tests/test_code.py codellama:7b-code-q4_K_M "Write a Python function to calculate factorial"
```

### Complete Python / Python Completo
```bash
python python/ollama_simple_async.py "What is 2+2"
python python/ollama_simple_async.py "Write a Python function to solve matrices in echelon form"
```

### Optimized PowerShell / PowerShell Optimizado
```powershell
# Fast test (sub-second) / Test rápido (sub-segundo)
.\powershell\test_fast.ps1 "What is 2+2?"

# Code generation / Generación de código
.\powershell\test_code.ps1 "Write a Python function to calculate factorial"

# General test / Test general
.\powershell\test_clean.ps1 "What is the capital of France?"

# Real-time monitoring / Monitoreo en tiempo real
.\powershell\monitor_ollama.ps1 5

# Complete setup / Configuración completa
.\powershell\setup_ollama.ps1
```

### PowerShell (with Python backend) / PowerShell (con backend Python)
```bash
.\ollama_simple_async_ps.bat "What is 2+2"
.\ollama_simple_async_ps.bat "Create a JavaScript function for matrix operations"
```

### 100% Native PowerShell / PowerShell 100% nativo
```bash
.\ollama_pure_ps.bat "What is 2+2"
.\ollama_pure_ps.bat "Create a JavaScript function to solve matrices in echelon form"
```

---

## Usage with Cursor AI from Terminal / Uso con Cursor AI desde Terminal

### Direct integration in Cursor / Integración directa en Cursor
1. **Open terminal in Cursor**: `Ctrl + `` (backtick)
2. **Navigate to project**: `cd path/to/ollama_desktop_cursorAI`
3. **Use from Cursor terminal**:

```bash
# Fast test from Cursor terminal / Test rápido desde terminal de Cursor
python tests/test_fast.py codellama:7b-code-q4_K_M "Analyze this React component and suggest improvements"

# Python from Cursor terminal / Python desde terminal de Cursor
python python/ollama_simple_async.py "Analyze this React component and suggest improvements"

# PowerShell from Cursor terminal / PowerShell desde terminal de Cursor
.\ollama_pure_ps.bat "Create a TypeScript interface for user data"
```

### Usage examples in Cursor / Ejemplos de uso en Cursor
```bash
# Code analysis / Análisis de código
python tests/test_fast.py codellama:7b-code-q4_K_M "Review this function for security issues"

# Code generation / Generación de código
python tests/test_code.py codellama:7b-code-q4_K_M "Create a responsive CSS grid layout"

# Debugging / Debugging
python tests/test_fast.py codellama:7b-code-q4_K_M "Why is this JavaScript function returning undefined?"

# Refactoring / Refactoring
python tests/test_code.py codellama:7b-code-q4_K_M "Refactor this Python class to use dependency injection"
```

### Cursor Configuration / Configuración en Cursor
- **Default model**: `codellama:7b-code-q4_K_M` (GPU optimized)
- **Endpoint**: `http://localhost:11434`
- **Cache**: Automatic (24 hours)
- **Logs**: `logs/` directory
- **GPU**: 100% automatic utilization

---

## Configuration / Configuración

### Dependencies Installation / Instalación de Dependencias
```bash
pip install -r python/requirements.txt
```

### Recommended Model (GPU) / Modelo Recomendado (GPU)
```bash
# Main optimized model / Modelo principal optimizado
ollama pull codellama:7b-code-q4_K_M

# Verify GPU / Verificar GPU
ollama ps
```

### Parameter Configuration / Configuración de Parámetros
- **Temperature**: 0.1 (simple questions), 0.2 (code), 0.7 (conversation)
- **Tokens**: 20 (fast), 100 (normal), 200 (code)
- **GPU**: Automatic with CUDA/Metal

---

## Tests

### Automated Tests / Tests Automatizados
```bash
cd tests
run_tests.bat
```

### Manual Tests / Tests Manuales
```bash
# Fast test / Test rápido
python tests/test_fast.py codellama:7b-code-q4_K_M "What is 2+2?"

# Code test / Test de código
python tests/test_code.py codellama:7b-code-q4_K_M "Write a Python function to calculate factorial"

# Complete test / Test completo
python tests/test_clean.py codellama:7b-code-q4_K_M "What is 2+2?"
```

### PowerShell Tests / Tests PowerShell
```powershell
# Fast test / Test rápido
.\powershell\test_fast.ps1 "What is 2+2?"

# Code test / Test de código
.\powershell\test_code.ps1 "Write a Python function to calculate factorial"

# Complete test / Test completo
.\powershell\test_clean.ps1 "What is 2+2?"
```

### Cache cleanup / Limpieza de cache
```bash
cd tests
clear_cache.bat
```

---

## Features / Características

### ✅ **Main Features / Funcionalidades Principales:**
- ✅ Smart cache for responses / Cache inteligente para respuestas
- ✅ Robust error handling / Manejo robusto de errores
- ✅ Automated tests / Tests automatizados
- ✅ Configurable sync/async mode / Modo sync/async configurable
- ✅ Native Python and PowerShell support / Soporte Python y PowerShell nativo
- ✅ Input validation / Validación de entrada
- ✅ Usage statistics / Estadísticas de uso

### 🚀 **GPU Optimizations / Optimizaciones GPU:**
- ✅ Automatic GPU acceleration / Aceleración GPU automática
- ✅ Parameters optimized by question type / Parámetros optimizados por tipo de pregunta
- ✅ Structured prompts for better performance / Prompts estructurados para mejor rendimiento
- ✅ Automatic response validation / Validación automática de respuestas
- ✅ Intelligent timeouts / Timeouts inteligentes

### 📊 **Current Performance / Rendimiento Actual:**
- **Simple questions**: 669ms / **Preguntas simples**: 669ms
- **Code**: 3.4s / **Código**: 3.4s
- **GPU**: 100% utilization / **GPU**: 100% utilización
- **Accuracy**: 100% in math tests / **Precisión**: 100% en tests matemáticos

---

## Project Structure / Estructura del Proyecto

```
ollama_desktop_cursorAI/
├── python/
│   ├── ollama_simple_async.py    # Main async client / Cliente principal async
│   ├── ollama_cache.py           # Cache system / Sistema de cache
│   ├── ollama_errors.py          # Error handling / Manejo de errores
│   ├── ollama_improved.py        # Improved client (new) / Cliente mejorado (nuevo)
│   └── requirements.txt
├── tests/
│   ├── test_ollama.py            # Automated tests (Python) / Tests automatizados (Python)
│   ├── test_fast.py              # Fast optimized test (Python) / Test rápido optimizado (Python)
│   ├── test_code.py              # Code test (Python) / Test para código (Python)
│   ├── test_clean.py             # Clean test (Python) / Test limpio (Python)
│   ├── test_model.py             # Basic model test (Python) / Test básico de modelo (Python)
│   ├── test_model_clean.ps1      # Clean model test (PowerShell) / Test limpio de modelo (PowerShell)
│   ├── test_model_curl.ps1       # Curl model test (PowerShell) / Test curl de modelo (PowerShell)
│   ├── test_model_timeout.ps1    # Timeout model test (PowerShell) / Test timeout de modelo (PowerShell)
│   ├── setup_ollama.py           # Automated setup (Python) / Configuración automatizada (Python)
│   ├── run_tests.bat             # Run all tests / Ejecutar todos los tests
│   └── clear_cache.bat           # Clear test cache / Limpiar cache de tests
├── powershell/
│   ├── ollama_simple_async.ps1    # Updated: Optimized direct calls / Actualizado: Llamadas directas optimizadas
│   ├── ollama_simple_async_pure.ps1
│   ├── ollama_cache.ps1
│   ├── ollama_errors.ps1
│   ├── test_fast.ps1              # New: Fast optimized test / Nuevo: Test rápido optimizado
│   ├── test_code.ps1              # New: Code generation / Nuevo: Generación de código
│   ├── test_clean.ps1             # New: Clean test / Nuevo: Test limpio
│   ├── monitor_ollama.ps1         # New: Real-time monitoring / Nuevo: Monitoreo en tiempo real
│   └── setup_ollama.ps1           # New: Automated setup / Nuevo: Configuración automatizada
├── logs/                         # Response logs / Logs de respuestas
├── cache/                        # Response cache / Cache de respuestas
├── ollama_simple_async.bat
├── ollama_simple_async_ps.bat
├── ollama_pure_ps.bat
└── README.md
```

---

## Optimization Parameters / Parámetros de Optimización

### 🌡️ **Temperature**
- **0.1**: Simple questions, precise responses / Preguntas simples, respuestas precisas
- **0.2**: Code, deterministic logic / Código, lógica determinista
- **0.7**: General conversation, more creative / Conversación general, más creativo

### 🔢 **Tokens (num_predict)**
- **20**: Very short responses (fast test) / Respuestas muy cortas (test rápido)
- **100**: Normal responses / Respuestas normales
- **200**: Complete code / Código completo

### ⚡ **GPU Optimization / Optimización GPU**
- **GPU**: Automatic with CUDA/Metal / Automático con CUDA/Metal
- **Memory**: 7.1 GB for codellama:7b-code-q4_K_M / Memoria: 7.1 GB para codellama:7b-code-q4_K_M
- **Speed**: 100% GPU utilization / Velocidad: 100% utilización GPU

---

## Troubleshooting

### Common Problems / Problemas Comunes
1. **Slow model**: Use `test_fast.py` with fewer tokens / **Modelo lento**: Usar `test_fast.py` con menos tokens
2. **Incoherent responses**: Verify temperature (use 0.1-0.3) / **Respuestas incoherentes**: Verificar temperatura (usar 0.1-0.3)
3. **Timeout**: Increase timeout or reduce tokens / **Timeout**: Aumentar timeout o reducir tokens
4. **GPU not detected**: Verify `ollama ps` / **GPU no detectado**: Verificar `ollama ps`

### Useful Commands / Comandos Útiles
```bash
# Verify GPU status / Verificar estado GPU
ollama ps

# List models / Listar modelos
ollama list

# Verify connection / Verificar conexión
python tests/test_fast.py codellama:7b-code-q4_K_M "test"
```

---

## Contributing / Contribuir

This project is open-source. Contributions welcome:
Este proyecto es open-source. Contribuciones bienvenidas:

- Report bugs / Reportar bugs
- Suggest improvements / Sugerir mejoras
- Optimize performance / Optimizar rendimiento
- Add new models / Agregar nuevos modelos

---

## License / Licencia

MIT License - See LICENSE for details.
MIT License - Ver LICENSE para detalles.
