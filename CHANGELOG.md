# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2024-12-19

### Added
- **Cursor AI Timeout Integration**: Automatic timeout configuration to prevent terminal hanging
- **`.vscode/settings.json`**: Workspace configuration for Cursor AI with 30-second timeout
- **PowerShell optimization**: Enhanced PowerShell scripts with better error handling
- **Unified prompt system**: Both Python and PowerShell now use consistent prompts
- **High temperature support**: Configurable temperature (0.8) and tokens (500) for creative code generation

### Changed
- **README.md**: Complete rewrite with bilingual documentation and Cursor AI integration
- **Test scripts**: Updated to use consistent parameters and prompts
- **Project structure**: Cleaned up legacy files and optimized organization
- **Performance**: Improved response times and reliability

### Fixed
- **PowerShell prompt issue**: Fixed hardcoded Python prompt in PowerShell scripts
- **Terminal hanging**: Resolved Cursor AI terminal hanging with automatic timeout
- **Code generation consistency**: Both Python and PowerShell now generate similar quality code
- **Parameter optimization**: Unified temperature and token settings across all scripts

### Removed
- **Legacy files**: Removed unnecessary cursor settings files
- **Duplicate scripts**: Cleaned up redundant test and fix scripts
- **Unused configurations**: Removed outdated configuration files

## [1.0.0] - 2024-12-18

### Added
- **Initial project setup**: Basic Ollama integration with Cursor AI
- **Python client**: `ollama_simple_async.py` for async communication
- **PowerShell client**: `ollama_simple_async.ps1` for PowerShell integration
- **Test scripts**: Fast and code generation tests
- **Caching system**: Response caching for improved performance
- **Error handling**: Robust error handling and logging
- **GPU optimization**: Automatic GPU utilization for codellama:7b-code-q4_K_M

### Performance Metrics
- **Simple questions**: 669ms average response time
- **Code generation**: 3.4s average response time
- **GPU utilization**: 100% with optimized parameters
- **Memory usage**: Optimized for efficiency

---

## Version History

### v2.0.0 - Cursor AI Timeout Integration
- Complete Cursor AI integration with timeout protection
- Unified prompt system across Python and PowerShell
- Enhanced documentation and troubleshooting guides
- Optimized performance and reliability

### v1.0.0 - Initial Release
- Basic Ollama integration
- Python and PowerShell clients
- Test suite and performance optimization
- GPU acceleration support 