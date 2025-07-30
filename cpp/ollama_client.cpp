#include <iostream>
#include <string>
#include <map>
#include <chrono>
#include <thread>
#include <future>
#include <curl/curl.h>
#include <nlohmann/json.hpp>
#include <openssl/sha.h>
#include <iomanip>
#include <sstream>

using json = nlohmann::json;

// Configuración por defecto
const std::string DEFAULT_MODEL = "codellama:7b-code-q4_K_M";
const std::string DEFAULT_ENDPOINT = "http://localhost:11434";
const int DEFAULT_TIMEOUT = 30;
const int CACHE_EXPIRY = 3600; // 1 hora

// Estructura para cache
struct CacheEntry {
    json response;
    std::chrono::system_clock::time_point expiry;
};

// Cache global
std::map<std::string, CacheEntry> ollamaCache;

// Función para generar hash SHA256
std::string generateHash(const std::string& prompt, const std::string& model) {
    std::string content = prompt + "|" + model;
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, content.c_str(), content.length());
    SHA256_Final(hash, &sha256);
    
    std::stringstream ss;
    for(int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(hash[i]);
    }
    return ss.str();
}

// Callback para CURL
size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    userp->append((char*)contents, size * nmemb);
    return size * nmemb;
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
        curl_global_init(CURL_GLOBAL_DEFAULT);
    }
    
    ~OllamaClient() {
        curl_global_cleanup();
    }
    
    // Llamada síncrona con cache
    json ask(const std::string& question, bool useCache = true) {
        std::cout << "🤖 Ollama: " << question << std::endl << std::endl;
        
        // Verificar cache
        if (useCache) {
            std::string hash = generateHash(question, model);
            auto it = ollamaCache.find(hash);
            if (it != ollamaCache.end()) {
                auto now = std::chrono::system_clock::now();
                if (now < it->second.expiry) {
                    std::cout << "⚡ Respuesta desde cache:" << std::endl;
                    std::cout << it->second.response["response"] << std::endl;
                    std::cout << std::endl << "⏱️  Cache hit - tiempo instantáneo" << std::endl;
                    return it->second.response;
                } else {
                    ollamaCache.erase(it);
                }
            }
        }
        
        // Preparar datos
        json data = {
            {"model", model},
            {"prompt", question},
            {"stream", false},
            {"options", {
                {"temperature", 0.7},
                {"num_predict", 100},
                {"top_k", 40},
                {"top_p", 0.9},
                {"repeat_penalty", 1.1}
            }}
        };
        
        auto start = std::chrono::high_resolution_clock::now();
        
        // Realizar llamada HTTP
        json response = makeRequest(data);
        
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
            std::cout << response["response"] << std::endl;
            std::cout << std::endl << "⏱️  Tiempo: " << duration.count() << "ms" << std::endl;
        }
        
        return response;
    }
    
    // Llamada asíncrona
    std::future<json> askAsync(const std::string& question) {
        std::cout << "🔄 Iniciando pregunta asíncrona..." << std::endl;
        
        return std::async(std::launch::async, [this, question]() {
            json data = {
                {"model", model},
                {"prompt", question},
                {"stream", false},
                {"options", {
                    {"temperature", 0.7},
                    {"num_predict", 100},
                    {"top_k", 40},
                    {"top_p", 0.9},
                    {"repeat_penalty", 1.1}
                }}
            };
            
            return makeRequest(data);
        });
    }
    
    // Pregunta rápida (menos tokens)
    json askFast(const std::string& question, bool useCache = true) {
        std::cout << "⚡ Pregunta rápida: " << question << std::endl << std::endl;
        
        // Verificar cache
        if (useCache) {
            std::string hash = generateHash(question, model);
            auto it = ollamaCache.find(hash);
            if (it != ollamaCache.end()) {
                auto now = std::chrono::system_clock::now();
                if (now < it->second.expiry) {
                    std::cout << "⚡ Respuesta rápida desde cache:" << std::endl;
                    std::cout << it->second.response["response"] << std::endl;
                    std::cout << std::endl << "⚡ Cache hit - tiempo instantáneo" << std::endl;
                    return it->second.response;
                } else {
                    ollamaCache.erase(it);
                }
            }
        }
        
        // Preparar datos para pregunta rápida
        json data = {
            {"model", model},
            {"prompt", question},
            {"stream", false},
            {"options", {
                {"temperature", 0.1},
                {"num_predict", 20},
                {"top_k", 10},
                {"top_p", 0.9},
                {"repeat_penalty", 1.1}
            }}
        };
        
        auto start = std::chrono::high_resolution_clock::now();
        
        json response = makeRequest(data);
        
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
            std::cout << response["response"] << std::endl;
            std::cout << std::endl << "⚡ Tiempo: " << duration.count() << "ms" << std::endl;
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
        json data = {{"model", model}};
        json response = makeRequest(data, "/api/tags");
        
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
    
private:
    json makeRequest(const json& data, const std::string& path = "/api/generate") {
        CURL* curl = curl_easy_init();
        if (!curl) {
            std::cerr << "❌ Error: No se pudo inicializar CURL" << std::endl;
            return json();
        }
        
        std::string url = endpoint + path;
        std::string jsonStr = data.dump();
        std::string response;
        
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, jsonStr.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, timeout);
        
        struct curl_slist* headers = NULL;
        headers = curl_slist_append(headers, "Content-Type: application/json");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        
        CURLcode res = curl_easy_perform(curl);
        
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
        
        if (res != CURLE_OK) {
            std::cerr << "❌ Error CURL: " << curl_easy_strerror(res) << std::endl;
            return json();
        }
        
        try {
            return json::parse(response);
        } catch (const std::exception& e) {
            std::cerr << "❌ Error parsing JSON: " << e.what() << std::endl;
            return json();
        }
    }
};

// Función principal
int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "🚀 Ollama C++ Client" << std::endl;
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