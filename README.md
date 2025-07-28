# Ollama Desktop Cursor AI Integration

> Developed by aoxilus to connect Ollama AI to Cursor AI via terminal. Can be used with other SDKs and serves as an example for other AI integrations.

A comprehensive solution for integrating local Ollama instances with Cursor AI and development tools. Provides seamless connection between any SDK and terminal for local Ollama usage.

## 🚀 Ollama Local Setup

### Installation
1. **Ollama installed**: ✅ `smollm2:135m` (270MB)
2. **Service running**: ✅ Port 11434
3. **GPU active**: ✅ 100% GPU usage

### Available Model
- **smollm2:135m**: Local model with 135M parameters
- **Size**: 270MB
- **Endpoint**: http://localhost:11434

## 🤖 Ollama Context Tool

### Installation
```bash
# Python version
pip install -r python/requirements.txt

# PowerShell version (Included with Windows)
# No additional installation required
```

### Usage

#### 🐍 Python Version
```bash
# Using Python directly
python python/ollama_simple.py "How does authentication work?"

# Using batch script (Windows)
ollama_simple.bat "How does authentication work?"
```

#### ⚡ PowerShell Version
```bash
# Using PowerShell directly
powershell -ExecutionPolicy Bypass -File "powershell/ollama_simple.ps1" "What files are in this project?"

# Using batch script (Windows)
ollama_simple_ps.bat "How to optimize this function?"
```

### Features
- ✅ **Context analysis**: Reads project files
- ✅ **Response buffer**: Saves last 10 queries
- ✅ **Output file**: `ollama_responses.txt`
- ✅ **Multiple formats**: Python, JS, HTML, CSS, PHP, etc.
- ✅ **Terminal colors**: Colored output

### Usage Examples
```bash
# Code-related questions
ollama_simple.bat "What does the main() function do?"
ollama_simple_ps.bat "How does it connect to the database?"
ollama_simple.bat "What is the project structure?"

# Problem analysis
ollama_simple_ps.bat "Why does the login fail?"
ollama_simple.bat "How to optimize this function?"

# General questions
ollama_simple_ps.bat "What is the capital of France?"
```

## 📁 Project Structure

```
ollama_desktop_cursorAI/
├── 🐍 python/
│   ├── ollama_simple.py      # Simplified version
│   ├── ollama_context.py     # Complete version
│   └── requirements.txt      # Dependencies
├── ⚡ powershell/
│   ├── ollama_simple.ps1     # Simplified version
│   └── ollama_context.ps1    # Complete version
├── 🚀 Batch Scripts
│   ├── ollama_simple.bat     # Python simple
│   ├── ollama_context.bat    # Python complete
│   ├── ollama_simple_ps.bat  # PowerShell simple
│   └── ollama_context_ps.bat # PowerShell complete
├── 📄 Configuration
│   ├── .cursorrules          # Programming rules
│   ├── .cursor/settings.json # Cursor AI configuration
│   └── README.md             # This file
└── 📝 Output
    └── ollama_responses.txt  # Response buffer
```

## 🔧 Cursor AI Configuration

**Note**: Cursor does not have native Ollama support. However, we provide local tools:

1. **For quick queries**: `ollama_simple.bat "your question"`
2. **For development**: Use Cursor's official models
3. **For deep analysis**: Use Ollama directly with context

## 📊 System Status

```bash
# Verify Ollama
ollama list
ollama ps

# Test connection
curl http://localhost:11434/api/tags
```

## 🎯 Recommended Usage

1. **Cursor AI**: For general development and powerful models
2. **Ollama Context**: For project-specific queries
3. **Ollama Direct**: For experimentation and prototyping

## 🚀 Quick Commands

```bash
# Start Ollama (if not running)
ollama serve

# Quick query with Python
ollama_simple.bat "What does this code do?"

# Quick query with PowerShell
ollama_simple_ps.bat "How to optimize this function?"

# View saved responses
type ollama_responses.txt
```

## 🎯 Use Cases

### Code Analysis
```bash
ollama_simple.bat "What does the main() function do?"
ollama_simple.bat "How does it connect to the database?"
ollama_simple.bat "What is the project structure?"
```

### Debugging
```bash
ollama_simple.bat "Why does the login fail?"
ollama_simple.bat "How to optimize this function?"
ollama_simple.bat "Are there errors in this code?"
```

### Documentation
```bash
ollama_simple.bat "How to document this function?"
ollama_simple.bat "What comments to add to this code?"
```

## 🐛 Troubleshooting

### Ollama not responding
```bash
# Check if it's running
ollama ps

# Restart Ollama
ollama serve
```

### Python error
```bash
# Install dependencies
pip install -r python/requirements.txt
```

### PowerShell error
```bash
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🤖 Technical Architecture (For AI Understanding)

### System Components

#### 1. **Ollama Local Server**
- **Function**: Local AI model server
- **Endpoint**: `http://localhost:11434`
- **Model**: `smollm2:135m` (135M parameters, 270MB)
- **Protocol**: REST API with `/api/generate` and `/api/tags` endpoints

#### 2. **Integration Scripts**

**Python (`ollama_simple.py`)**
```python
# Execution flow:
1. check_ollama_connection() → Verify service + detect best model
2. get_project_files() → Read project files (max 10, <50KB)
3. query_ollama() → Send prompt with context to API
4. save_response() → Save to ollama_responses.txt
```

**PowerShell (`ollama_simple.ps1`)**
```powershell
# Equivalent flow:
1. Test-OllamaConnection → Same verification
2. Get-ProjectFiles → Same file reading
3. Invoke-OllamaQuery → Same API query
4. Save-Response → Same saving
```

#### 3. **Context Mechanism**
- **Input**: User question + project files
- **Processing**: 
  - Scan patterns: `*.py`, `*.js`, `*.html`, `*.css`, `*.json`, `*.md`, `*.txt`
  - Read content (first 2000 characters per file)
  - Build structured prompt
- **Output**: Ollama response + buffer save

#### 4. **Model Management**
```python
# Selection algorithm:
for model in available_models:
    size_mb = model.size / (1024 * 1024)
    if size_mb > largest_size:
        best_model = model.name
```

#### 5. **Error Handling**
- **Connection**: 5s timeout for verification, 60s for queries
- **Models**: Fallback if no models available
- **Files**: Skip large or inaccessible files
- **Encoding**: UTF-8 with error handling

#### 6. **Data Flow**
```
User → Script (Python/PowerShell) → Ollama API → Local Model → Response → File
```

#### 7. **Technical Features**
- **Buffer**: Maintains last 10 responses
- **Format**: Timestamp + Q&A in `ollama_responses.txt`
- **Cross-platform**: Windows batch scripts for easy execution
- **Modular**: Python/PowerShell separation for flexibility

#### 8. **Use Cases**
- Project-specific code analysis
- Local debugging with context
- Automatic documentation
- Technical queries with project knowledge

This system acts as an **intelligent bridge** between local development environment and local AI model, providing project-specific context for more accurate queries.

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- **Ollama**: For making local AI accessible
- **Cursor AI**: For being an excellent editor
- **GitHub**: For hosting this repository

---

*Developed by [aoxilus](https://github.com/aoxilus)*
