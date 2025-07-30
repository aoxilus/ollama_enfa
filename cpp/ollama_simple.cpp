#include <iostream>
#include <string>
#include <map>
#include <chrono>
#include <thread>
#include <future>
#include <iomanip>
#include <sstream>
#include <fstream>
#include <vector>

// Configuración por defecto
const std::string DEFAULT_MODEL = "codellama:7b-code-q4_K_M";
const std::string DEFAULT_ENDPOINT = "http://localhost:11434";
const int DEFAULT_TIMEOUT = 30;
const int CACHE_EXPIRY = 3600; // 1 hora

// Estructura para cache
struct CacheEntry {
    std::string response;
    std::chrono::system_clock::time_point expiry;
};

// Cache global
std::map<std::string, CacheEntry> ollamaCache;

// Función simple para generar hash (simulación)
std::string generateHash(const std::string& prompt, const std::string& model) {
    std::string content = prompt + "|" + model;
    std::hash<std::string> hasher;
    return std::to_string(hasher(content));
}

// Función para hacer HTTP request usando curl (si está disponible)
std::string makeHttpRequest(const std::string& url, const std::string& data) {
    // En Windows, usamos curl.exe si está disponible
    std::string command = "curl.exe -s -X POST -H \"Content-Type: application/json\" -d \"" + data + "\" \"" + url + "\"";
    
    FILE* pipe = _popen(command.c_str(), "r");
    if (!pipe) {
        return "";
    }
    
    std::string result;
    char buffer[128];
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        result += buffer;
    }
    _pclose(pipe);
    
    return result;
}

// Cliente principal de Ollama
class OllamaClient {
private:
    std::string model;
    std::string endpoint;
    int timeout;
    
public:
    OllamaClient(const std::string& m = DEFAULT_MODEL, 
                 const std::string& ep = DEFAULT_ENDPOINT, 
                 int t = DEFAULT_TIMEOUT) 
        : model(m), endpoint(ep), timeout(t) {
    }
    
    // Llamada síncrona con cache
    std::string ask(const std::string& question, bool useCache = true) {
        std::cout << "🤖 Ollama: " << question << std::endl << std::endl;
        
        // Verificar cache
        if (useCache) {
            std::string hash = generateHash(question, model);
            auto it = ollamaCache.find(hash);
            if (it != ollamaCache.end()) {
                auto now = std::chrono::system_clock::now();
                if (now < it->second.expiry) {
                    std::cout << "⚡ Respuesta desde cache:" << std::endl;
                    std::cout << it->second.response << std::endl;
                    std::cout << std::endl << "⏱️  Cache hit - tiempo instantáneo" << std::endl;
                    return it->second.response;
                } else {
                    ollamaCache.erase(it);
                }
            }
        }
        
        // Preparar datos JSON
        std::string jsonData = "{\"model\":\"" + model + "\",\"prompt\":\"" + question + "\",\"stream\":false,\"options\":{\"temperature\":0.7,\"num_predict\":100}}";
        
        auto start = std::chrono::high_resolution_clock::now();
        
        // Realizar llamada HTTP
        std::string response = makeHttpRequest(endpoint + "/api/generate", jsonData);
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        // Guardar en cache
        if (useCache && !response.empty()) {
            std::string hash = generateHash(question, model);
            CacheEntry entry;
            entry.response = response;
            entry.expiry = std::chrono::system_clock::now() + std::chrono::seconds(CACHE_EXPIRY);
            ollamaCache[hash] = entry;
        }
        
        // Mostrar respuesta
        if (!response.empty()) {
            std::cout << "✅ Respuesta:" << std::endl;
            std::cout << response << std::endl;
            std::cout << std::endl << "⏱️  Tiempo: " << duration.count() << "ms" << std::endl;
        } else {
            std::cout << "❌ Error: No se pudo obtener respuesta" << std::endl;
        }
        
        return response;
    }
    
    // Llamada asíncrona
    std::future<std::string> askAsync(const std::string& question) {
        std::cout << "🔄 Iniciando pregunta asíncrona..." << std::endl;
        
        return std::async(std::launch::async, [this, question]() {
            std::string jsonData = "{\"model\":\"" + model + "\",\"prompt\":\"" + question + "\",\"stream\":false,\"options\":{\"temperature\":0.7,\"num_predict\":100}}";
            return makeHttpRequest(endpoint + "/api/generate", jsonData);
        });
    }
    
    // Pregunta rápida (menos tokens)
    std::string askFast(const std::string& question, bool useCache = true) {
        std::cout << "⚡ Pregunta rápida: " << question << std::endl << std::endl;
        
        // Verificar cache
        if (useCache) {
            std::string hash = generateHash(question, model);
            auto it = ollamaCache.find(hash);
            if (it != ollamaCache.end()) {
                auto now = std::chrono::system_clock::now();
                if (now < it->second.expiry) {
                    std::cout << "⚡ Respuesta rápida desde cache:" << std::endl;
                    std::cout << it->second.response << std::endl;
                    std::cout << std::endl << "⚡ Cache hit - tiempo instantáneo" << std::endl;
                    return it->second.response;
                } else {
                    ollamaCache.erase(it);
                }
            }
        }
        
        // Preparar datos para pregunta rápida
        std::string jsonData = "{\"model\":\"" + model + "\",\"prompt\":\"" + question + "\",\"stream\":false,\"options\":{\"temperature\":0.1,\"num_predict\":20}}";
        
        auto start = std::chrono::high_resolution_clock::now();
        
        std::string response = makeHttpRequest(endpoint + "/api/generate", jsonData);
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        // Guardar en cache
        if (useCache && !response.empty()) {
            std::string hash = generateHash(question, model);
            CacheEntry entry;
            entry.response = response;
            entry.expiry = std::chrono::system_clock::now() + std::chrono::seconds(CACHE_EXPIRY);
            ollamaCache[hash] = entry;
        }
        
        if (!response.empty()) {
            std::cout << "✅ Respuesta rápida:" << std::endl;
            std::cout << response << std::endl;
            std::cout << std::endl << "⚡ Tiempo: " << duration.count() << "ms" << std::endl;
        } else {
            std::cout << "❌ Error: No se pudo obtener respuesta" << std::endl;
        }
        
        return response;
    }
    
    // Cambiar modelo
    void setModel(const std::string& newModel) {
        model = newModel;
        std::cout << "🤖 Modelo cambiado a: " << model << std::endl;
    }
    
    // Mostrar estado
    void status() {
        std::cout << "🤖 Estado de Ollama:" << std::endl;
        std::cout << "   Modelo: " << model << std::endl;
        std::cout << "   Endpoint: " << endpoint << std::endl;
        std::cout << "   Cache: " << ollamaCache.size() << " elementos" << std::endl;
        
        // Verificar conexión
        std::string response = makeHttpRequest(endpoint + "/api/tags", "{}");
        
        if (!response.empty()) {
            std::cout << "   ✅ Servidor conectado" << std::endl;
        } else {
            std::cout << "   ❌ Servidor no disponible" << std::endl;
        }
    }
    
    // Limpiar cache
    void clearCache() {
        ollamaCache.clear();
        std::cout << "🗑️  Cache limpiado" << std::endl;
    }
    
    // Estadísticas de cache
    void cacheStats() {
        int total = ollamaCache.size();
        int valid = 0;
        int expired = 0;
        
        auto now = std::chrono::system_clock::now();
        for (const auto& entry : ollamaCache) {
            if (now < entry.second.expiry) {
                valid++;
            } else {
                expired++;
            }
        }
        
        std::cout << "📊 Estadísticas de Cache:" << std::endl;
        std::cout << "   Total: " << total << " elementos" << std::endl;
        std::cout << "   Válidos: " << valid << std::endl;
        std::cout << "   Expirados: " << expired << std::endl;
    }
};

// Función principal
int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "🚀 Ollama C++ Client (Simple)" << std::endl;
        std::cout << "Uso: " << argv[0] << " <comando> [argumentos]" << std::endl;
        std::cout << "Comandos:" << std::endl;
        std::cout << "  ask <pregunta>     - Pregunta normal" << std::endl;
        std::cout << "  fast <pregunta>    - Pregunta rápida" << std::endl;
        std::cout << "  status             - Estado del servidor" << std::endl;
        std::cout << "  clearcache         - Limpiar cache" << std::endl;
        std::cout << "  cachestats         - Estadísticas de cache" << std::endl;
        return 1;
    }
    
    OllamaClient client;
    
    std::string command = argv[1];
    
    if (command == "ask" && argc > 2) {
        std::string question = argv[2];
        client.ask(question);
    } else if (command == "fast" && argc > 2) {
        std::string question = argv[2];
        client.askFast(question);
    } else if (command == "status") {
        client.status();
    } else if (command == "clearcache") {
        client.clearCache();
    } else if (command == "cachestats") {
        client.cacheStats();
    } else {
        std::cout << "❌ Comando no válido" << std::endl;
        return 1;
    }
    
    return 0;
} 