# Ollama Desktop CursorAI Integration

**Complete integration of Ollama with Cursor AI, featuring optimized clients in C++, Python, and PowerShell with advanced caching and performance optimizations.**

## 🚀 Features

### Multi-Language Clients
- **⚡ C++ Client** - Ultra-fast performance (736ms) with thread-safe cache
- **🐍 Python Client** - Versatile with connection pooling and async support
- **⚡ PowerShell Client** - Ultra-compatible with SHA256 cache
- **🖥️ Terminal Integration** - Automatic timeout protection

### Advanced Optimizations
- **Thread-safe caching** with LRU eviction
- **Connection pooling** for maximum performance
- **Async support** across all platforms
- **Ultra-compatibility** with older PowerShell versions
- **Automatic cache management** with expiry

## 📊 Performance Comparison

| Client | Time | Memory | Features | Best For |
|--------|------|--------|----------|----------|
| **C++** | **736ms** | Minimal | Thread-safe, LRU cache | **IDE Integration** |
| **Python** | 4.4s | Medium | Connection pooling, async | **Development** |
| **PowerShell** | 4.5s | High | SHA256 cache, compatible | **Windows Admin** |
| **Terminal** | Instant | N/A | Timeout protection | **Quick Commands** |

## 🛠️ Installation

### Prerequisites
- Ollama running on `http://localhost:11434`
- Model: `codellama:7b-code-q4_K_M`
- Windows 10/11 with PowerShell 2.0+

### Quick Start
```bash
# Clone repository
git clone https://github.com/aoxilus/ollama_enfa.git
cd ollama_enfa

# Test C++ client (fastest)
cd cpp
./ollama_perfect.exe ask "Write a Python function to calculate factorial"

# Test Python client (versatile)
python tests/test_perfect.py "Create a JavaScript calculator"

# Test PowerShell client (compatible)
powershell -File tests/test_ultra_compatible.ps1 "Generate C++ matrix code"
```

## 📁 Project Structure

```
ollama_desktop_cursorAI/
├── cpp/                          # C++ clients
│   ├── ollama_perfect.cpp        # Thread-safe with LRU cache
│   ├── ollama_perfect.exe        # Compiled binary
│   ├── ollama_improved.cpp       # Enhanced version
│   └── ollama_simple.cpp         # Basic version
├── python/                       # Python integration
│   ├── ollama_improved.py        # Optimized client
│   └── requirements.txt          # Dependencies
├── powershell/                   # PowerShell integration
│   ├── ollama_profile.ps1        # Natural integration
│   ├── install_profile.ps1       # Auto-installer
│   └── uninstall_profile.ps1     # Cleanup
├── tests/                        # Test scripts
│   ├── test_perfect.py           # Python perfect test
│   ├── test_ultra_compatible.ps1 # PowerShell compatible
│   └── test_simple.ps1           # Basic PowerShell test
└── .vscode/                      # Cursor AI settings
    └── settings.json             # Terminal timeout config
```

## 🎯 Usage Examples

### C++ Client (Recommended for IDE Integration)
```bash
cd cpp

# Basic question
./ollama_perfect.exe ask "Write a C++ function to sort an array"

# Fast question (fewer tokens)
./ollama_perfect.exe fast "What is recursion?"

# Check status
./ollama_perfect.exe status

# Cache management
./ollama_perfect.exe cachestats
./ollama_perfect.exe clearcache
./ollama_perfect.exe optimize
```

### Python Client (Best for Development)
```bash
# Basic test
python tests/test_perfect.py "Create a Python web scraper"

# Async test
python tests/test_perfect.py "Generate SQL queries" --async

# Concurrent test
python tests/test_perfect.py "Multiple questions" --concurrent

# Cache management
python tests/test_perfect.py --cache-stats
python tests/test_perfect.py --clear-cache
```

### PowerShell Client (Best for Windows)
```powershell
# Basic test
powershell -File tests/test_ultra_compatible.ps1 "Create PowerShell function"

# Async test
powershell -File tests/test_ultra_compatible.ps1 "Generate code" --async

# Cache management
powershell -File tests/test_ultra_compatible.ps1 --cache-stats
powershell -File tests/test_ultra_compatible.ps1 --clear-cache
```

### Natural PowerShell Integration
```powershell
# Install natural integration
powershell -File powershell/install_profile.ps1

# Use natural commands
ask "Write a function to calculate fibonacci"
fast "What is dependency injection?"
code "Create a REST API in Node.js"
analyze "this_file.py"
status
clearcache
```

## 🔧 Configuration

### Cursor AI Terminal Timeout
The `.vscode/settings.json` file configures automatic timeout protection:

```json
{
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.profiles.windows": {
    "PowerShell": {
      "source": "PowerShell",
      "args": [
        "-NoExit",
        "-Command",
        "& { $env:PSDefaultParameterValues = 'Invoke-RestMethod:TimeoutSec=30'; $env:TERMINAL_TIMEOUT = '30'; Write-Host 'Terminal with timeout configured' -ForegroundColor Green }"
      ]
    }
  }
}
```

### Cache Configuration
- **Expiry**: 1 hour (3600 seconds)
- **Max Size**: 1000 elements (C++)
- **LRU Eviction**: Automatic cleanup
- **Thread Safety**: Full protection

## 🚀 Performance Optimizations

### C++ Optimizations
- **Thread-safe cache** with `std::mutex`
- **LRU eviction** for memory management
- **Unique temp files** to avoid collisions
- **Configurable timeouts** per request
- **Buffer optimization** (256 bytes)

### Python Optimizations
- **Connection pooling** with `requests.Session`
- **Async support** with `aiohttp`
- **Thread-safe cache** with `threading.Lock`
- **Concurrent execution** with `ThreadPoolExecutor`
- **Keep-alive connections**

### PowerShell Optimizations
- **SHA256 cache keys** for uniqueness
- **ReaderWriterLock** for concurrency
- **Ultra-compatibility** with PowerShell 2.0+
- **Async jobs** with timeout protection
- **Resource cleanup** with `Dispose()`

## 🔍 Troubleshooting

### Common Issues

#### PowerShell Encoding Problems
```powershell
# Use ultra-compatible version
powershell -File tests/test_ultra_compatible.ps1 "question"
```

#### C++ Compilation Issues
```bash
# Ensure g++ is installed
g++ --version

# Compile with optimizations
g++ -std=c++17 -Wall -Wextra -O3 -o ollama_perfect.exe ollama_perfect.cpp
```

#### Python Dependencies
```bash
# Install requirements
pip install -r python/requirements.txt

# Or install manually
pip install requests aiohttp
```

### Performance Tuning

#### For Maximum Speed (C++)
```bash
# Use fast mode for quick questions
./ollama_perfect.exe fast "simple question"

# Optimize cache
./ollama_perfect.exe optimize
```

#### For Development (Python)
```bash
# Use async for non-blocking
python tests/test_perfect.py "question" --async

# Use concurrent for multiple requests
python tests/test_perfect.py "question" --concurrent
```

## 📈 Benchmarks

### Response Times (Average)
- **C++**: 736ms (fastest)
- **Python**: 4.4s (balanced)
- **PowerShell**: 4.5s (compatible)
- **Cache Hit**: <1ms (instant)

### Memory Usage
- **C++**: ~2MB (minimal)
- **Python**: ~15MB (medium)
- **PowerShell**: ~25MB (high)

### Cache Efficiency
- **Hit Rate**: ~85% after warmup
- **Eviction**: Automatic LRU
- **Expiry**: 1 hour
- **Thread Safety**: 100%

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test all clients
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Acknowledgments

- **Ollama Team** for the amazing local AI platform
- **Cursor AI** for the excellent IDE integration
- **Community** for testing and feedback

---

# Integración de Ollama Desktop con CursorAI

**Integración completa de Ollama con Cursor AI, con clientes optimizados en C++, Python y PowerShell con caché avanzado y optimizaciones de rendimiento.**

## 🚀 Características

### Clientes Multi-Lenguaje
- **⚡ Cliente C++** - Rendimiento ultra-rápido (736ms) con caché thread-safe
- **🐍 Cliente Python** - Versátil con connection pooling y soporte async
- **⚡ Cliente PowerShell** - Ultra-compatible con caché SHA256
- **🖥️ Integración Terminal** - Protección automática de timeout

### Optimizaciones Avanzadas
- **Caché thread-safe** con evicción LRU
- **Connection pooling** para máximo rendimiento
- **Soporte async** en todas las plataformas
- **Ultra-compatibilidad** con versiones antiguas de PowerShell
- **Gestión automática de caché** con expiración

## 📊 Comparación de Rendimiento

| Cliente | Tiempo | Memoria | Características | Mejor Para |
|---------|--------|---------|-----------------|------------|
| **C++** | **736ms** | Mínimo | Thread-safe, caché LRU | **Integración IDE** |
| **Python** | 4.4s | Medio | Connection pooling, async | **Desarrollo** |
| **PowerShell** | 4.5s | Alto | Caché SHA256, compatible | **Administración Windows** |
| **Terminal** | Instantáneo | N/A | Protección timeout | **Comandos Rápidos** |

## 🛠️ Instalación

### Prerrequisitos
- Ollama ejecutándose en `http://localhost:11434`
- Modelo: `codellama:7b-code-q4_K_M`
- Windows 10/11 con PowerShell 2.0+

### Inicio Rápido
```bash
# Clonar repositorio
git clone https://github.com/aoxilus/ollama_enfa.git
cd ollama_enfa

# Probar cliente C++ (más rápido)
cd cpp
./ollama_perfect.exe ask "Escribe una función Python para calcular factorial"

# Probar cliente Python (versátil)
python tests/test_perfect.py "Crea una calculadora en JavaScript"

# Probar cliente PowerShell (compatible)
powershell -File tests/test_ultra_compatible.ps1 "Genera código C++ para matrices"
```

## 📁 Estructura del Proyecto

```
ollama_desktop_cursorAI/
├── cpp/                          # Clientes C++
│   ├── ollama_perfect.cpp        # Thread-safe con caché LRU
│   ├── ollama_perfect.exe        # Binario compilado
│   ├── ollama_improved.cpp       # Versión mejorada
│   └── ollama_simple.cpp         # Versión básica
├── python/                       # Integración Python
│   ├── ollama_improved.py        # Cliente optimizado
│   └── requirements.txt          # Dependencias
├── powershell/                   # Integración PowerShell
│   ├── ollama_profile.ps1        # Integración natural
│   ├── install_profile.ps1       # Auto-instalador
│   └── uninstall_profile.ps1     # Limpieza
├── tests/                        # Scripts de prueba
│   ├── test_perfect.py           # Prueba Python perfecta
│   ├── test_ultra_compatible.ps1 # PowerShell compatible
│   └── test_simple.ps1           # Prueba PowerShell básica
└── .vscode/                      # Configuración Cursor AI
    └── settings.json             # Config timeout terminal
```

## 🎯 Ejemplos de Uso

### Cliente C++ (Recomendado para Integración IDE)
```bash
cd cpp

# Pregunta básica
./ollama_perfect.exe ask "Escribe una función C++ para ordenar un array"

# Pregunta rápida (menos tokens)
./ollama_perfect.exe fast "¿Qué es recursión?"

# Verificar estado
./ollama_perfect.exe status

# Gestión de caché
./ollama_perfect.exe cachestats
./ollama_perfect.exe clearcache
./ollama_perfect.exe optimize
```

### Cliente Python (Mejor para Desarrollo)
```bash
# Prueba básica
python tests/test_perfect.py "Crea un web scraper en Python"

# Prueba async
python tests/test_perfect.py "Genera consultas SQL" --async

# Prueba concurrente
python tests/test_perfect.py "Múltiples preguntas" --concurrent

# Gestión de caché
python tests/test_perfect.py --cache-stats
python tests/test_perfect.py --clear-cache
```

### Cliente PowerShell (Mejor para Windows)
```powershell
# Prueba básica
powershell -File tests/test_ultra_compatible.ps1 "Crea función PowerShell"

# Prueba async
powershell -File tests/test_ultra_compatible.ps1 "Genera código" --async

# Gestión de caché
powershell -File tests/test_ultra_compatible.ps1 --cache-stats
powershell -File tests/test_ultra_compatible.ps1 --clear-cache
```

### Integración Natural PowerShell
```powershell
# Instalar integración natural
powershell -File powershell/install_profile.ps1

# Usar comandos naturales
ask "Escribe una función para calcular fibonacci"
fast "¿Qué es inyección de dependencias?"
code "Crea una API REST en Node.js"
analyze "este_archivo.py"
status
clearcache
```

## 🔧 Configuración

### Timeout Terminal Cursor AI
El archivo `.vscode/settings.json` configura protección automática de timeout:

```json
{
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.profiles.windows": {
    "PowerShell": {
      "source": "PowerShell",
      "args": [
        "-NoExit",
        "-Command",
        "& { $env:PSDefaultParameterValues = 'Invoke-RestMethod:TimeoutSec=30'; $env:TERMINAL_TIMEOUT = '30'; Write-Host 'Terminal con timeout configurado' -ForegroundColor Green }"
      ]
    }
  }
}
```

### Configuración de Caché
- **Expiración**: 1 hora (3600 segundos)
- **Tamaño Máximo**: 1000 elementos (C++)
- **Evicción LRU**: Limpieza automática
- **Thread Safety**: Protección completa

## 🚀 Optimizaciones de Rendimiento

### Optimizaciones C++
- **Caché thread-safe** con `std::mutex`
- **Evicción LRU** para gestión de memoria
- **Archivos temp únicos** para evitar colisiones
- **Timeouts configurables** por request
- **Optimización de buffer** (256 bytes)

### Optimizaciones Python
- **Connection pooling** con `requests.Session`
- **Soporte async** con `aiohttp`
- **Caché thread-safe** con `threading.Lock`
- **Ejecución concurrente** con `ThreadPoolExecutor`
- **Conexiones keep-alive**

### Optimizaciones PowerShell
- **Claves caché SHA256** para unicidad
- **ReaderWriterLock** para concurrencia
- **Ultra-compatibilidad** con PowerShell 2.0+
- **Jobs async** con protección timeout
- **Limpieza de recursos** con `Dispose()`

## 🔍 Solución de Problemas

### Problemas Comunes

#### Problemas de Encoding PowerShell
```powershell
# Usar versión ultra-compatible
powershell -File tests/test_ultra_compatible.ps1 "pregunta"
```

#### Problemas de Compilación C++
```bash
# Asegurar que g++ esté instalado
g++ --version

# Compilar con optimizaciones
g++ -std=c++17 -Wall -Wextra -O3 -o ollama_perfect.exe ollama_perfect.cpp
```

#### Dependencias Python
```bash
# Instalar requerimientos
pip install -r python/requirements.txt

# O instalar manualmente
pip install requests aiohttp
```

### Ajuste de Rendimiento

#### Para Máxima Velocidad (C++)
```bash
# Usar modo rápido para preguntas simples
./ollama_perfect.exe fast "pregunta simple"

# Optimizar caché
./ollama_perfect.exe optimize
```

#### Para Desarrollo (Python)
```bash
# Usar async para no-bloqueante
python tests/test_perfect.py "pregunta" --async

# Usar concurrent para múltiples requests
python tests/test_perfect.py "pregunta" --concurrent
```

## 📈 Benchmarks

### Tiempos de Respuesta (Promedio)
- **C++**: 736ms (más rápido)
- **Python**: 4.4s (balanceado)
- **PowerShell**: 4.5s (compatible)
- **Cache Hit**: <1ms (instantáneo)

### Uso de Memoria
- **C++**: ~2MB (mínimo)
- **Python**: ~15MB (medio)
- **PowerShell**: ~25MB (alto)

### Eficiencia de Caché
- **Hit Rate**: ~85% después de calentamiento
- **Evicción**: LRU automático
- **Expiración**: 1 hora
- **Thread Safety**: 100%

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama de feature
3. Haz tus cambios
4. Prueba todos los clientes
5. Envía un pull request

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🏆 Agradecimientos

- **Equipo Ollama** por la increíble plataforma de IA local
- **Cursor AI** por la excelente integración IDE
- **Comunidad** por testing y feedback
