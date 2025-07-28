# Ollama Desktop Cursor AI

> **Desarrollado por aoxilus** para conectar Ollama AI local con Cursor AI y herramientas de desarrollo. Integración completa entre SDKs y terminal para uso local de Ollama.

## ¿Qué es este proyecto?

Este proyecto es una **integración inteligente** entre Ollama (IA local) y Cursor AI (editor de código) que permite:

- 🔗 **Conexión directa** entre tu editor y modelos de IA locales
- 📁 **Análisis de contexto** automático de tu proyecto
- 💾 **Cache inteligente** para respuestas rápidas
- 🛠️ **Herramientas de desarrollo** mejoradas con IA local
- 🔄 **Modo sync/async** configurable

## ¿Por qué se desarrolló?

- **Privacidad**: Usa IA local sin enviar código a servidores externos
- **Velocidad**: Respuestas instantáneas sin latencia de red
- **Contexto**: Análisis profundo de tu proyecto específico
- **Flexibilidad**: Funciona con cualquier modelo de Ollama
- **Integración**: Se conecta con Cursor AI y otros editores

## ¿Quién lo hizo?

**Desarrollado por aoxilus** como solución open-source para la comunidad de desarrolladores que buscan:
- Control total sobre sus datos
- IA local para desarrollo
- Integración con herramientas modernas
- Código abierto y personalizable

## Uso rápido

### Python
```bash
python python/ollama_simple_async.py "What is 2+2"
python python/ollama_simple_async.py "Write a Python function to solve matrices in echelon form"
```

### PowerShell (con backend Python)
```bash
.\ollama_simple_async_ps.bat "What is 2+2"
.\ollama_simple_async_ps.bat "Create a JavaScript function for matrix operations"
```

### PowerShell 100% nativo
```bash
.\ollama_pure_ps.bat "What is 2+2"
.\ollama_pure_ps.bat "Create a JavaScript function to solve matrices in echelon form"
```

## Configuración
- Cambia `SYNC_MODE` en los scripts para modo sync/async
- Instala dependencias Python:
  ```bash
  pip install -r python/requirements.txt
  ```
- Descarga el modelo Ollama:
  ```bash
  ollama pull codellama:7b-instruct
  ```

## Tests
```bash
cd tests
run_tests.bat
```

## Limpieza de cache
```bash
cd tests
clear_cache.bat
```

## Características
- ✅ Cache inteligente para respuestas
- ✅ Manejo robusto de errores
- ✅ Tests automatizados
- ✅ Modo sync/async configurable
- ✅ Soporte Python y PowerShell nativo
- ✅ Validación de entrada
- ✅ Estadísticas de uso

## Estructura
```
python/
  ollama_simple_async.py
  ollama_cache.py
  ollama_errors.py
  requirements.txt
powershell/
  ollama_simple_async.ps1
  ollama_simple_async_pure.ps1
  ollama_cache.ps1
  ollama_errors.ps1
tests/
  test_ollama.py
  run_tests.bat
  clear_cache.bat
ollama_simple_async.bat
ollama_simple_async_ps.bat
ollama_pure_ps.bat
LICENSE
README.md
```
