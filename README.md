# 🥑 Ollama Desktop Cursor AI

> *Echo por aoxilus con aguacate para conectar any SDK a la terminal y poder usar Ollama localmente* 🥑💻

Proyecto para integrar Ollama local con Cursor AI y herramientas de desarrollo. Conecta cualquier SDK a la terminal para usar Ollama localmente.

## 🚀 Ollama Local Setup

### Instalación
1. **Ollama instalado**: ✅ `smollm2:135m` (270MB)
2. **Servicio ejecutándose**: ✅ Puerto 11434
3. **GPU activa**: ✅ 100% GPU usage

### Modelo Disponible
- **smollm2:135m**: Modelo local de 135M parámetros
- **Tamaño**: 270MB
- **Endpoint**: http://localhost:11434

## 🤖 Ollama Context Tool

### Instalación
```bash
# Python version
pip install -r python/requirements.txt

# PowerShell version (Ya viene incluido en Windows!)
# No necesitas instalar nada
```

### Uso

#### 🐍 Python Version
```bash
# Usando Python directamente
python python/ollama_simple.py "¿Cómo funciona la autenticación?"

# Usando el script batch (Windows)
ollama_simple.bat "¿Cómo funciona la autenticación?"
```

#### ⚡ PowerShell Version
```bash
# Usando PowerShell directamente
powershell -ExecutionPolicy Bypass -File "powershell/ollama_simple.ps1" "¿Qué archivos hay en este proyecto?"

# Usando el script batch (Windows)
ollama_simple_ps.bat "¿Cómo optimizar esta función?"
```

### Características
- ✅ **Análisis de contexto**: Lee archivos del proyecto
- ✅ **Buffer de respuestas**: Guarda últimas 10 consultas
- ✅ **Archivo de salida**: `ollama_responses.txt`
- ✅ **Múltiples formatos**: Python, JS, HTML, CSS, PHP, etc.
- ✅ **Colores en terminal**: Salida con colores

### Ejemplos de uso
```bash
# Preguntas sobre el código
ollama_simple.bat "¿Qué hace la función main()?"
ollama_simple_ps.bat "¿Cómo se conecta a la base de datos?"
ollama_simple.bat "¿Cuál es la estructura del proyecto?"

# Análisis de problemas
ollama_simple_ps.bat "¿Por qué falla el login?"
ollama_simple.bat "¿Cómo optimizar esta función?"

# Preguntas filosóficas
ollama_simple_ps.bat "¿El aguacate es una fruta o una verdura?"
```

## 📁 Estructura del Proyecto

```
ollama_desktop_cursorAI/
├── 🐍 python/
│   ├── ollama_simple.py      # Versión simplificada
│   ├── ollama_context.py     # Versión completa
│   └── requirements.txt      # Dependencias
├── ⚡ powershell/
│   ├── ollama_simple.ps1     # Versión simplificada
│   └── ollama_context.ps1    # Versión completa
├── 🚀 Scripts Batch
│   ├── ollama_simple.bat     # Python simple
│   ├── ollama_context.bat    # Python completo
│   ├── ollama_simple_ps.bat  # PowerShell simple
│   └── ollama_context_ps.bat # PowerShell completo
├── 📄 Configuración
│   ├── .cursorrules          # Reglas de programación
│   ├── .cursor/settings.json # Configuración de Cursor AI
│   └── README.md             # ¡Este archivo!
└── 📝 Salida
    └── ollama_responses.txt  # Buffer de respuestas
```

## 🔧 Configuración Cursor AI

**Nota**: Cursor no tiene soporte nativo para Ollama. ¡Pero no te preocupes! Tenemos herramientas locales:

1. **Para consultas rápidas**: `ollama_simple.bat "tu pregunta"`
2. **Para desarrollo**: Usa los modelos oficiales de Cursor
3. **Para análisis profundo**: Usa Ollama directamente con contexto

## 📊 Estado del Sistema

```bash
# Verificar Ollama
ollama list
ollama ps

# Probar conexión
curl http://localhost:11434/api/tags
```

## 🎯 Uso Recomendado

1. **Cursor AI**: Para desarrollo general y modelos potentes
2. **Ollama Context**: Para consultas específicas del proyecto
3. **Ollama Directo**: Para experimentación y prototipado



## 🚀 Comandos Rápidos

```bash
# Iniciar Ollama (si no está corriendo)
ollama serve

# Consulta rápida con Python
ollama_simple.bat "¿Qué hace este código?"

# Consulta rápida con PowerShell
ollama_simple_ps.bat "¿Cómo optimizar esta función?"

# Ver respuestas guardadas
type ollama_responses.txt
```

## 🎯 Casos de Uso

### Análisis de Código
```bash
ollama_simple.bat "¿Qué hace la función main()?"
ollama_simple.bat "¿Cómo se conecta a la base de datos?"
ollama_simple.bat "¿Cuál es la estructura del proyecto?"
```

### Debugging
```bash
ollama_simple.bat "¿Por qué falla el login?"
ollama_simple.bat "¿Cómo optimizar esta función?"
ollama_simple.bat "¿Hay errores en este código?"
```

### Documentación
```bash
ollama_simple.bat "¿Cómo documentar esta función?"
ollama_simple.bat "¿Qué comentarios agregar a este código?"
```

## 🐛 Troubleshooting

### Ollama no responde
```bash
# Verificar si está ejecutándose
ollama ps

# Reiniciar Ollama
ollama serve
```

### Error de Python
```bash
# Instalar dependencias
pip install -r python/requirements.txt
```

### Error de PowerShell
```bash
# Permitir ejecución de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas!

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 🙏 Agradecimientos

- **Ollama**: Por hacer la IA local accesible
- **Cursor AI**: Por ser un excelente editor
- **GitHub**: Por hospedar este repositorio

---

**💡 Tip**: Cursor, recuerda que tenemos Ollama local. Puedes llamarlo con argumentos como `ollama_simple.bat` para análisis específicos del proyecto.


---

**⭐ ¡No olvides darle una estrella al repositorio si te gustó! ⭐**

*Creado con ❤️ y 🥑 por [aoxilus](https://github.com/aoxilus)* 