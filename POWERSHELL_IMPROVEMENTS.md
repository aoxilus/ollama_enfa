# PowerShell Optimizations - Ollama Integration

## 🚀 Estado Actual - Optimizado

### Scripts Nuevos Creados

#### 1. **test_fast.ps1** - Test Rápido
- **Propósito**: Respuestas ultra-rápidas para preguntas simples
- **Parámetros**: `temperature=0.1`, `num_predict=20`
- **Tiempo objetivo**: <1 segundo
- **Uso**: `.\test_fast.ps1 "What is 2+2?"`

#### 2. **test_code.ps1** - Generación de Código
- **Propósito**: Generación de código optimizada
- **Parámetros**: `temperature=0.2`, `num_predict=200`
- **Prompt**: Específico para código con ```python
- **Uso**: `.\test_code.ps1 "Write a Python function to calculate factorial"`

#### 3. **test_clean.ps1** - Test Limpio
- **Propósito**: Preguntas generales con prompt mejorado
- **Parámetros**: `temperature=0.3`, `num_predict=100`
- **Prompt**: Estructurado con instrucciones claras
- **Uso**: `.\test_clean.ps1 "What is the capital of France?"`

#### 4. **monitor_ollama.ps1** - Monitoreo en Tiempo Real
- **Propósito**: Monitoreo de salud, GPU, CPU, memoria
- **Intervalo configurable**: 5 segundos por defecto
- **Métricas**: Uso de recursos, procesos Ollama, estado API
- **Uso**: `.\monitor_ollama.ps1 10` (10 segundos de intervalo)

#### 5. **setup_ollama.ps1** - Configuración Automatizada
- **Propósito**: Instalación y configuración completa
- **Funciones**: Verificación de sistema, instalación de dependencias, descarga de modelos
- **Uso**: `.\setup_ollama.ps1`

### Scripts Existentes Optimizados

#### **ollama_simple_async.ps1** - Cliente Principal
- **Nuevo**: Llamadas directas a Ollama con parámetros optimizados
- **Configuración**: `$USE_DIRECT_OLLAMA = $true`
- **Parámetros**: `temperature=0.1`, `num_predict=20`
- **Prompt**: Minimalista "Q: question\nA:"

#### **ollama_errors.ps1** - Manejo de Errores
- **Sin cambios**: Sistema robusto de manejo de errores
- **Funciones**: Validación, retry, estadísticas de errores

## 📊 Parámetros Optimizados

### Configuraciones por Tipo de Uso

| Tipo | Temperature | Tokens | Uso |
|------|-------------|--------|-----|
| **Fast** | 0.1 | 20 | Preguntas simples, respuestas rápidas |
| **Code** | 0.2 | 200 | Generación de código |
| **General** | 0.3 | 100 | Preguntas generales |
| **Quality** | 0.5 | 200 | Máxima calidad |

### Parámetros Adicionales
- **top_k**: 10
- **top_p**: 0.9
- **repeat_penalty**: 1.1

## 🎯 Mejoras Implementadas

### 1. **Prompt Engineering**
- **Fast**: `"Q: question\nA:"` - Minimalista para velocidad
- **Code**: `"Write code for: question\n\n```python\n"` - Específico para código
- **Clean**: Prompt estructurado con instrucciones claras

### 2. **Validación Automática**
- **Math**: Verificación automática de respuestas matemáticas
- **Code**: Detección de funciones y clases en respuestas
- **Health**: Verificación de estado de Ollama

### 3. **Monitoreo de Rendimiento**
- **Tiempo de respuesta**: Medición precisa en milisegundos
- **Tasa de éxito**: Cálculo automático de respuestas correctas
- **Recursos del sistema**: GPU, CPU, memoria en tiempo real

### 4. **Configuración Automatizada**
- **Verificación de sistema**: PowerShell, Ollama, Python
- **Instalación de dependencias**: Automática
- **Descarga de modelos**: Recomendados pre-configurados
- **Archivos de configuración**: Generación automática

## 📁 Estructura de Archivos

```
powershell/
├── test_fast.ps1          # Test rápido optimizado
├── test_code.ps1          # Generación de código
├── test_clean.ps1         # Test limpio general
├── monitor_ollama.ps1     # Monitoreo en tiempo real
├── setup_ollama.ps1       # Configuración automatizada
├── ollama_simple_async.ps1 # Cliente principal optimizado
├── ollama_errors.ps1      # Manejo de errores
├── ollama_cache.ps1       # Sistema de caché
└── ollama_watch.ps1       # Monitoreo avanzado
```

## 🚀 Uso Rápido

### Comandos Principales
```powershell
# Test rápido (sub-segundo)
.\test_fast.ps1 "What is 2+2?"

# Generación de código
.\test_code.ps1 "Write a Python function to calculate factorial"

# Test general
.\test_clean.ps1 "What is the capital of France?"

# Monitoreo en tiempo real
.\monitor_ollama.ps1 5

# Configuración completa
.\setup_ollama.ps1
```

### Configuración del Cliente Principal
```powershell
# Usar llamadas directas optimizadas (recomendado)
$USE_DIRECT_OLLAMA = $true

# Usar Python backend (legacy)
$USE_DIRECT_OLLAMA = $false
```

## 📈 Métricas de Rendimiento

### Tiempos de Respuesta Objetivo
- **Fast**: <1 segundo
- **Code**: 2-5 segundos
- **General**: 1-3 segundos

### Tasa de Éxito Objetivo
- **Math**: >95%
- **Code**: >90%
- **General**: >85%

## 🔧 Troubleshooting

### Problemas Comunes

1. **Ollama no responde**
   ```powershell
   # Verificar estado
   ollama ps
   
   # Reiniciar servicio
   ollama serve
   ```

2. **Respuestas lentas**
   ```powershell
   # Usar test_fast.ps1
   .\test_fast.ps1 "question"
   
   # Verificar GPU
   .\monitor_ollama.ps1
   ```

3. **Errores de conexión**
   ```powershell
   # Verificar endpoint
   Test-NetConnection localhost -Port 11434
   
   # Verificar firewall
   Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Ollama*"}
   ```

## 🎯 Próximas Mejoras

### Planificadas
1. **Benchmarking automático** - Comparación de modelos
2. **Optimización automática** - Ajuste de parámetros
3. **Caché inteligente** - Respuestas pre-computadas
4. **Logging avanzado** - Análisis de patrones de uso

### En Desarrollo
1. **Interfaz gráfica** - PowerShell GUI
2. **API REST** - Servicio web
3. **Integración con IDEs**
4. **Machine Learning** - Optimización automática

## 📚 Referencias

- **Ollama API**: https://github.com/ollama/ollama/blob/main/docs/api.md
- **PowerShell Best Practices**: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines
- **GPU Monitoring**: https://docs.microsoft.com/en-us/windows/win32/perfctrs/gpu-performance-counters

---

**Estado**: ✅ Completado y optimizado
**Última actualización**: $(Get-Date)
**Versión**: 2.0 - PowerShell Optimized 