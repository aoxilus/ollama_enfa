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
- **Cursor AI Timeout**: Automatic timeout configuration to prevent hanging

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
- ⏱️ **Timeout protection** for Cursor AI terminal

---

## Why was it developed? / ¿Por qué se desarrolló?

- **Privacy**: Use local AI without sending code to external servers
- **Speed**: Instant responses without network latency
- **Context**: Deep analysis of your specific project
- **Flexibility**: Works with any Ollama model
- **Integration**: Connects with Cursor AI and other editors
- **GPU**: Leverages your hardware for maximum speed
- **Reliability**: Prevents terminal hanging with automatic timeouts

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
.\tests\test_fast.ps1 "codellama:7b-code-q4_K_M" "What is 2+2?"

# Code generation / Generación de código
.\tests\test_code.ps1 "codellama:7b-code-q4_K_M" "Write a Python function to calculate factorial"

# General test / Test general
.\tests\test_clean.ps1 "codellama:7b-code-q4_K_M" "What is the capital of France?"

# Real-time monitoring / Monitoreo en tiempo real
.\powershell\monitor_ollama.ps1 5

# Complete setup / Configuración completa
.\powershell\setup_ollama.ps1
```

---

## Cursor AI Configuration / Configuración de Cursor AI

### ⏱️ **Automatic Timeout Protection**
The project includes automatic timeout configuration for Cursor AI to prevent terminal hanging:

El proyecto incluye configuración automática de timeout para Cursor AI para prevenir colgamientos:

```json
// .vscode/settings.json
{
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.profiles.windows": {
    "PowerShell": {
      "source": "PowerShell",
      "args": [
        "-NoExit",
        "-Command",
        "& { $env:PSDefaultParameterValues = 'Invoke-RestMethod:TimeoutSec=30'; $env:TERMINAL_TIMEOUT = '30'; Write-Host '🚀 Terminal con timeout configurado' -ForegroundColor Green }"
      ],
      "env": {
        "PSDefaultParameterValues": "Invoke-RestMethod:TimeoutSec=30",
        "TERMINAL_TIMEOUT": "30"
      }
    }
  }
}
```

### 🎯 **Features:**
- **30-second timeout** for all commands
- **Automatic process cleanup** for hanging jobs
- **PowerShell optimization** for better performance
- **No more terminal hanging** in Cursor AI

---

## Project Structure / Estructura del Proyecto

```
ollama_desktop_cursorAI/
├── .vscode/
│   └── settings.json          # Cursor AI timeout configuration
├── python/                    # Python scripts and modules
│   ├── ollama_simple_async.py # Main async client
│   ├── ollama_cache.py        # Caching system
│   ├── ollama_errors.py       # Error handling
│   ├── monitor_ollama.py      # Real-time monitoring
│   ├── optimize_ollama.py     # Performance optimization
│   └── benchmark_ollama.py    # Performance benchmarking
├── powershell/                # PowerShell scripts
│   ├── ollama_simple_async.ps1 # Main PowerShell client
│   ├── monitor_ollama.ps1     # Real-time monitoring
│   ├── setup_ollama.ps1       # Setup and configuration
│   └── optimize_ollama.ps1    # Performance optimization
├── tests/                     # Test scripts
│   ├── test_fast.py          # Fast tests (669ms)
│   ├── test_code.py          # Code generation tests (3.4s)
│   ├── test_clean.py         # General tests
│   └── test_fast.ps1         # PowerShell fast tests
├── .cursorrules              # Cursor AI configuration
├── README.md                 # This file
└── LICENSE                   # Project license
```

---

## Performance Metrics / Métricas de Rendimiento

### ⚡ **Speed Tests:**
- **Simple Questions**: 669ms average
- **Code Generation**: 3.4s average
- **GPU Utilization**: 100%
- **Memory Usage**: Optimized
- **Response Quality**: High accuracy

### 🎯 **Optimized Parameters:**
- **Temperature Fast**: 0.1 (precise answers)
- **Temperature Code**: 0.2 (balanced creativity)
- **Temperature General**: 0.7 (creative responses)
- **Tokens Fast**: 20 (quick responses)
- **Tokens Normal**: 100 (standard responses)
- **Tokens Code**: 200 (detailed code)

---

## Installation / Instalación

### Prerequisites / Prerrequisitos:
- **Ollama** installed and running
- **Python 3.8+** with required packages
- **PowerShell 5.1+** (Windows)
- **Cursor AI** for editor integration

### Setup / Configuración:
1. **Clone repository** / Clonar repositorio
2. **Install dependencies** / Instalar dependencias: `pip install -r python/requirements.txt`
3. **Configure Cursor AI** / Configurar Cursor AI: Copy `.vscode/settings.json` to your workspace
4. **Test connection** / Probar conexión: `python tests/test_fast.py`

---

## Usage Examples / Ejemplos de Uso

### Quick Questions / Preguntas Rápidas
```bash
# Python
python tests/test_fast.py codellama:7b-code-q4_K_M "What is 2+2?"

# PowerShell
.\tests\test_fast.ps1 "codellama:7b-code-q4_K_M" "What is 2+2?"
```

### Code Generation / Generación de Código
```bash
# Python
python tests/test_code.py codellama:7b-code-q4_K_M "Create a JavaScript calculator"

# PowerShell
.\tests\test_code.ps1 "codellama:7b-code-q4_K_M" "Create a JavaScript calculator"
```

### Monitoring / Monitoreo
```bash
# Real-time monitoring
.\powershell\monitor_ollama.ps1 5

# Performance optimization
python python/optimize_ollama.py
```

---

## Troubleshooting / Solución de Problemas

### Common Issues / Problemas Comunes:

#### **Cursor AI Terminal Hanging**
- **Solution**: The `.vscode/settings.json` configuration automatically prevents this
- **Manual fix**: Use `.\tests\test_clean.ps1` for cleanup

#### **Slow Responses**
- **Solution**: Check GPU utilization with `.\powershell\monitor_ollama.ps1`
- **Optimization**: Run `python python/optimize_ollama.py`

#### **Connection Errors**
- **Solution**: Ensure Ollama is running on `http://localhost:11434`
- **Test**: Use `python tests/test_fast.py` to verify connection

---

## Contributing / Contribuir

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** with the provided test scripts
5. **Submit** a pull request

---

## License / Licencia

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

## Status / Estado

**✅ Project Status**: Complete and Optimized
**✅ Cursor AI Integration**: Working with timeout protection
**✅ Performance**: Optimized for speed and reliability
**✅ Documentation**: Complete bilingual documentation

**Última actualización**: $(Get-Date)
**Versión**: 2.0 - Cursor AI Timeout Integration
