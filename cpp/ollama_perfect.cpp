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
#include <cstdlib>
#include <algorithm>
#include <mutex>

// Configuración por defecto
const std::string DEFAULT_MODEL = "codellama:7b-code-q4_K_M";
const std::string DEFAULT_ENDPOINT = "http://localhost:11434";
const int DEFAULT_TIMEOUT = 30;
const int CACHE_EXPIRY = 3600; // 1 hora
const int MAX_CACHE_SIZE = 1000; // Máximo elementos en cache

// Estructura para cache con mutex thread-safe
struct CacheEntry {
    std::string response;
    std::chrono::system_clock::time_point expiry;
    int access_count;
};

// Cache global thread-safe
std::map<std::string, CacheEntry> ollamaCache;
std::mutex cacheMutex;

// Función optimizada para generar hash
std::string generateHash(const std::string& prompt, const std::string& model) {
    std::string content = prompt + "|" + model;
    std::hash<std::string> hasher;
    return std::to_string(hasher(content));
}

// Función para limpiar cache expirado
void cleanupExpiredCache() {
    std::lock_guard<std::mutex> lock(cacheMutex);
    auto now = std::chrono::system_clock::now();
    
    for (auto it = ollamaCache.begin(); it != ollamaCache.end();) {
        if (now > it->second.expiry) {
            it = ollamaCache.erase(it);
        } else {
            ++it;
        }
    }
    
    // Si el cache es muy grande, eliminar los menos usados
    if (ollamaCache.size() > MAX_CACHE_SIZE) {
        std::vector<std::pair<std::string, int>> access_counts;
        for (const auto& entry : ollamaCache) {
            access_counts.emplace_back(entry.first, entry.second.access_count);
        }
        
        std::sort(access_counts.begin(), access_counts.end(), 
                  [](const auto& a, const auto& b) { return a.second < b.second; });
        
        int to_remove = ollamaCache.size() - MAX_CACHE_SIZE / 2;
        for (int i = 0; i < to_remove && i < access_counts.size(); ++i) {
            ollamaCache.erase(access_counts[i].first);
        }
    }
}

// Función para hacer HTTP request usando curl con archivo temporal y timeout
std::string makeHttpRequest(const std::string& url, const std::string& data, int timeout = 30) {
    // Crear archivo temporal para el JSON
    std::string tempFile = "temp_request_" + std::to_string(std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count()) + ".json";
    
    std::ofstream file(tempFile);
    if (file.is_open()) {
        file << data;
        file.close();
    } else {
        return "";
    }
    
    // Comando curl usando archivo con timeout
    std::string command = "curl.exe -s --max-time " + std::to_string(timeout) + 
                          " -X POST -H \"Content-Type: application/json\" -d @" + tempFile + " \"" + url + "\"";
    
    FILE* pipe = _popen(command.c_str(), "r");
    if (!pipe) {
        std::remove(tempFile.c_str());
        return "";
    }
    
    std::string result;
    char buffer[256]; // Buffer más grande para mejor performance
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        result += buffer;
    }
    _pclose(pipe);
    
    // Limpiar archivo temporal
    std::remove(tempFile.c_str());
    
    return result;
}

// Cliente principal de Ollama optimizado
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
        // Limpiar cache al inicializar
        cleanupExpiredCache();
    }
    
    // Llamada síncrona con cache optimizado
    std::string ask(const std::string& question, bool useCache = true) {
        std::cout << "🤖 Ollama: " << question << std::endl << std::endl;
        
        // Verificar cache
        if (useCache) {
            std::string hash = generateHash(question, model);
            {
                std::lock_guard<std::mutex> lock(cacheMutex);
                auto it = ollamaCache.find(hash);
                if (it != ollamaCache.end()) {
                    auto now = std::chrono::system_clock::now();
                    if (now < it->second.expiry) {
                        it->second.access_count++; // Incrementar contador de acceso
                        std::cout << "⚡ Respuesta desde cache:" << std::endl;
                        std::cout << it->second.response << std::endl;
                        std::cout << std::endl << "⏱️  Cache hit - tiempo instantáneo" << std::endl;
                        return it->second.response;
                    } else {
                        ollamaCache.erase(it);
                    }
                }
            }
        }
        
        // Preparar datos JSON optimizado
        std::string jsonData = "{\"model\":\"" + model + "\",\"prompt\":\"" + question + 
                              "\",\"stream\":false,\"options\":{\"temperature\":0.7,\"num_predict\":100}}";
        
        auto start = std::chrono::high_resolution_clock::now();
        
        // Realizar llamada HTTP con timeout
        std::string response = makeHttpRequest(endpoint + "/api/generate", jsonData, timeout);
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        // Guardar en cache thread-safe
        if (useCache && !response.empty()) {
            std::string hash = generateHash(question, model);
            {
                std::lock_guard<std::mutex> lock(cacheMutex);
                CacheEntry entry;
                entry.response = response;
                entry.expiry = std::chrono::system_clock::now() + std::chrono::seconds(CACHE_EXPIRY);
                entry.access_count = 1;
                ollamaCache[hash] = entry;
            }
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
    
    // Llamada asíncrona optimizada
    std::future<std::string> askAsync(const std::string& question) {
        std::cout << "🔄 Iniciando pregunta asíncrona..." << std::endl;
        
        return std::async(std::launch::async, [this, question]() {
            std::string jsonData = "{\"model\":\"" + model + "\",\"prompt\":\"" + question + 
                                  "\",\"stream\":false,\"options\":{\"temperature\":0.7,\"num_predict\":100}}";
            return makeHttpRequest(endpoint + "/api/generate", jsonData, timeout);
        });
    }
    
    // Pregunta rápida optimizada (menos tokens)
    std::string askFast(const std::string& question, bool useCache = true) {
        std::cout << "⚡ Pregunta rápida: " << question << std::endl << std::endl;
        
        // Verificar cache
        if (useCache) {
            std::string hash = generateHash(question, model);
            {
                std::lock_guard<std::mutex> lock(cacheMutex);
                auto it = ollamaCache.find(hash);
                if (it != ollamaCache.end()) {
                    auto now = std::chrono::system_clock::now();
                    if (now < it->second.expiry) {
                        it->second.access_count++;
                        std::cout << "⚡ Respuesta rápida desde cache:" << std::endl;
                        std::cout << it->second.response << std::endl;
                        std::cout << std::endl << "⚡ Cache hit - tiempo instantáneo" << std::endl;
                        return it->second.response;
                    } else {
                        ollamaCache.erase(it);
                    }
                }
            }
        }
        
        // Preparar datos para pregunta rápida
        std::string jsonData = "{\"model\":\"" + model + "\",\"prompt\":\"" + question + 
                              "\",\"stream\":false,\"options\":{\"temperature\":0.1,\"num_predict\":20}}";
        
        auto start = std::chrono::high_resolution_clock::now();
        
        std::string response = makeHttpRequest(endpoint + "/api/generate", jsonData, 10); // Timeout más corto
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        // Guardar en cache
        if (useCache && !response.empty()) {
            std::string hash = generateHash(question, model);
            {
                std::lock_guard<std::mutex> lock(cacheMutex);
                CacheEntry entry;
                entry.response = response;
                entry.expiry = std::chrono::system_clock::now() + std::chrono::seconds(CACHE_EXPIRY);
                entry.access_count = 1;
                ollamaCache[hash] = entry;
            }
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
    
    // Mostrar estado optimizado
    void status() {
        std::cout << "🤖 Estado de Ollama:" << std::endl;
        std::cout << "   Modelo: " << model << std::endl;
        std::cout << "   Endpoint: " << endpoint << std::endl;
        
        {
            std::lock_guard<std::mutex> lock(cacheMutex);
            std::cout << "   Cache: " << ollamaCache.size() << " elementos" << std::endl;
        }
        
        // Verificar conexión
        std::string response = makeHttpRequest(endpoint + "/api/tags", "{}", 5);
        
        if (!response.empty()) {
            std::cout << "   ✅ Servidor conectado" << std::endl;
        } else {
            std::cout << "   ❌ Servidor no disponible" << std::endl;
        }
    }
    
    // Limpiar cache thread-safe
    void clearCache() {
        std::lock_guard<std::mutex> lock(cacheMutex);
        ollamaCache.clear();
        std::cout << "🗑️  Cache limpiado" << std::endl;
    }
    
    // Estadísticas de cache optimizadas
    void cacheStats() {
        std::lock_guard<std::mutex> lock(cacheMutex);
        
        int total = ollamaCache.size();
        int valid = 0;
        int expired = 0;
        int total_access = 0;
        
        auto now = std::chrono::system_clock::now();
        for (const auto& entry : ollamaCache) {
            if (now < entry.second.expiry) {
                valid++;
            } else {
                expired++;
            }
            total_access += entry.second.access_count;
        }
        
        std::cout << "📊 Estadísticas de Cache:" << std::endl;
        std::cout << "   Total: " << total << " elementos" << std::endl;
        std::cout << "   Válidos: " << valid << " elementos" << std::endl;
        std::cout << "   Expirados: " << expired << " elementos" << std::endl;
        std::cout << "   Accesos totales: " << total_access << std::endl;
        std::cout << "   Tamaño máximo: " << MAX_CACHE_SIZE << " elementos" << std::endl;
    }
    
    // Optimizar cache
    void optimizeCache() {
        cleanupExpiredCache();
        std::cout << "🔧 Cache optimizado" << std::endl;
    }
};

// Función principal
int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "🚀 Ollama C++ Client (Perfect)" << std::endl;
        std::cout << "Uso: " << argv[0] << " <comando> [argumentos]" << std::endl;
        std::cout << "Comandos:" << std::endl;
        std::cout << "  ask <pregunta>     - Pregunta normal" << std::endl;
        std::cout << "  fast <pregunta>    - Pregunta rápida" << std::endl;
        std::cout << "  status             - Estado del servidor" << std::endl;
        std::cout << "  clearcache         - Limpiar cache" << std::endl;
        std::cout << "  cachestats         - Estadísticas de cache" << std::endl;
        std::cout << "  optimize           - Optimizar cache" << std::endl;
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
    } else if (command == "optimize") {
        client.optimizeCache();
    } else {
        std::cout << "❌ Comando no válido" << std::endl;
        return 1;
    }
    
    return 0;
} 