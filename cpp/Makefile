# Makefile para Ollama C++ Client
# Compilador y flags
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
LDFLAGS = -lcurl -lssl -lcrypto

# Dependencias
DEPS = -lcurl -lssl -lcrypto

# Archivos fuente
SOURCES = ollama_client.cpp
TARGET = ollama_client

# Regla principal
all: $(TARGET)

# Compilar el ejecutable
$(TARGET): $(SOURCES)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SOURCES) $(DEPS)

# Instalar dependencias (Ubuntu/Debian)
install-deps-ubuntu:
	sudo apt-get update
	sudo apt-get install -y g++ libcurl4-openssl-dev libssl-dev nlohmann-json3-dev

# Instalar dependencias (Windows con MSYS2)
install-deps-windows:
	pacman -S mingw-w64-x86_64-gcc
	pacman -S mingw-w64-x86_64-curl
	pacman -S mingw-w64-x86_64-openssl
	pacman -S mingw-w64-x86_64-nlohmann-json

# Instalar dependencias (macOS con Homebrew)
install-deps-macos:
	brew install gcc curl openssl nlohmann-json

# Verificar compilador
check-compiler:
	@echo "🔍 Verificando compilador g++..."
	@which g++ || (echo "❌ g++ no encontrado. Instala g++ primero." && exit 1)
	@g++ --version | head -1
	@echo "✅ Compilador g++ encontrado"

# Verificar dependencias
check-deps:
	@echo "🔍 Verificando dependencias..."
	@pkg-config --exists libcurl && echo "✅ libcurl encontrado" || echo "❌ libcurl no encontrado"
	@pkg-config --exists openssl && echo "✅ openssl encontrado" || echo "❌ openssl no encontrado"
	@echo "📝 Nota: nlohmann/json se incluye como header-only"

# Compilar con verificación
build: check-compiler check-deps $(TARGET)
	@echo "✅ Compilación completada: $(TARGET)"

# Limpiar archivos generados
clean:
	rm -f $(TARGET) *.o

# Ejecutar tests básicos
test: $(TARGET)
	@echo "🧪 Ejecutando tests básicos..."
	./$(TARGET) status
	./$(TARGET) cachestats

# Instalar (copiar a /usr/local/bin)
install: $(TARGET)
	sudo cp $(TARGET) /usr/local/bin/
	@echo "✅ $(TARGET) instalado en /usr/local/bin/"

# Desinstalar
uninstall:
	sudo rm -f /usr/local/bin/$(TARGET)
	@echo "✅ $(TARGET) desinstalado"

# Ayuda
help:
	@echo "🚀 Ollama C++ Client Makefile"
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  make build          - Compilar con verificación"
	@echo "  make all            - Compilar el cliente"
	@echo "  make clean          - Limpiar archivos generados"
	@echo "  make test           - Ejecutar tests básicos"
	@echo "  make install        - Instalar en /usr/local/bin"
	@echo "  make uninstall      - Desinstalar"
	@echo ""
	@echo "Instalación de dependencias:"
	@echo "  make install-deps-ubuntu   - Ubuntu/Debian"
	@echo "  make install-deps-windows  - Windows (MSYS2)"
	@echo "  make install-deps-macos    - macOS (Homebrew)"
	@echo ""
	@echo "Verificación:"
	@echo "  make check-compiler - Verificar g++"
	@echo "  make check-deps     - Verificar dependencias"

.PHONY: all clean test install uninstall help check-compiler check-deps build install-deps-ubuntu install-deps-windows install-deps-macos 