#include <iostream>
#include <string>
#include <map>
#include <chrono>
#include <thread>
#include <future>
#include <cstdlib>
#include <curl/curl.h>
#include <nlohmann/json.hpp>
#include <openssl/sha.h>
#include <iomanip>
#include <sstream>
#include <cstring>

#include "butler_openai_compat.hpp"

using json = nlohmann::json;

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

static json normalize_chat_response(const json& response) {
    json out = json::object();
    std::string text;
    try {
        if (response.contains("choices") && response["choices"].is_array() && !response["choices"].empty()) {
            const auto& ch = response["choices"][0];
            if (ch.contains("message") && ch["message"].contains("content")) {
                text = ch["message"]["content"].get<std::string>();
            }
        }
    } catch (...) {
    }
    out["response"] = text;
    return out;
}

static bool machine_output() {
    const char* q = std::getenv("BUTLER_MACHINE_OUTPUT");
    return q && q[0] && std::strcmp(q, "0") != 0;
}

static json chat_payload(const std::string& model, const std::string& question, int max_tokens, double temperature) {
    json messages = json::array();
    const char* sys = std::getenv("BUTLER_SYSTEM_PROMPT");
    if (sys && sys[0]) {
        json sm;
        sm["role"] = "system";
        sm["content"] = std::string(sys);
        messages.push_back(sm);
    }
    json um;
    um["role"] = "user";
    um["content"] = question;
    messages.push_back(um);
    return json{
        {"model", model},
        {"messages", messages},
        {"stream", false},
        {"max_tokens", max_tokens},
        {"temperature", temperature}
    };
}

static bool has_assistant_text(const json& response) {
    return response.is_object() && response.contains("response") && response["response"].is_string()
        && !response["response"].get<std::string>().empty();
}

// Cliente principal (llama-server OpenAI API)
class OllamaClient {
private:
    std::string model;
    std::string endpoint;
    int timeout;
    
public:
    OllamaClient(const std::string& m = "", 
                 const std::string& ep = "", 
                 int t = DEFAULT_TIMEOUT) 
        : model(m.empty() ? bc::default_model() : m), 
          endpoint(ep.empty() ? bc::default_endpoint() : bc::trim_end_slash(ep)), 
          timeout(t) {
        if (const char* te = std::getenv("BUTLER_TIMEOUT_SEC")) {
            int v = std::atoi(te);
            if (v > 0) {
                timeout = v;
            }
        }
        curl_global_init(CURL_GLOBAL_DEFAULT);
    }
    
    ~OllamaClient() {
        curl_global_cleanup();
    }
    
    // Llamada síncrona con cache
    json ask(const std::string& question, bool useCache = true) {
        const bool quiet = machine_output();
        if (!quiet) {
            std::cout << "🤖 Ollama: " << question << std::endl << std::endl;
        }
        
        if (useCache) {
            std::string hash = generateHash(question, model);
            auto it = ollamaCache.find(hash);
            if (it != ollamaCache.end()) {
                auto now = std::chrono::system_clock::now();
                if (now < it->second.expiry) {
                    if (quiet) {
                        std::cout << it->second.response["response"].get<std::string>() << std::endl;
                    } else {
                        std::cout << "⚡ Respuesta desde cache:" << std::endl;
                        std::cout << it->second.response["response"] << std::endl;
                        std::cout << std::endl << "⏱️  Cache hit - tiempo instantáneo" << std::endl;
                    }
                    return it->second.response;
                } else {
                    ollamaCache.erase(it);
                }
            }
        }
        
        int max_tok = 100;
        if (const char* e = std::getenv("BUTLER_MAX_TOKENS")) {
            int v = std::atoi(e);
            if (v > 0) {
                max_tok = v;
            }
        }
        double temp = 0.7;
        if (const char* e = std::getenv("BUTLER_TEMPERATURE")) {
            temp = std::strtod(e, nullptr);
        }
        json data = chat_payload(model, question, max_tok, temp);
        
        auto start = std::chrono::high_resolution_clock::now();
        
        json raw = makeRequest(data, "/v1/chat/completions");
        json response = normalize_chat_response(raw);
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        // Guardar en cache
        if (useCache && has_assistant_text(response)) {
            std::string hash = generateHash(question, model);
            CacheEntry entry;
            entry.response = response;
            entry.expiry = std::chrono::system_clock::now() + std::chrono::seconds(CACHE_EXPIRY);
            ollamaCache[hash] = entry;
        }
        
        if (has_assistant_text(response)) {
            if (quiet) {
                std::cout << response["response"].get<std::string>() << std::endl;
            } else {
                std::cout << "✅ Respuesta:" << std::endl;
                std::cout << response["response"] << std::endl;
                std::cout << std::endl << "⏱️  Tiempo: " << duration.count() << "ms" << std::endl;
            }
        }
        
        return response;
    }
    
    // Llamada asíncrona
    std::future<json> askAsync(const std::string& question) {
        std::cout << "🔄 Iniciando pregunta asíncrona..." << std::endl;
        
        return std::async(std::launch::async, [this, question]() {
            json data = chat_payload(model, question, 100, 0.7);
            json raw = makeRequest(data, "/v1/chat/completions");
            return normalize_chat_response(raw);
        });
    }
    
    // Pregunta rápida (menos tokens)
    json askFast(const std::string& question, bool useCache = true) {
        const bool quiet = machine_output();
        if (!quiet) {
            std::cout << "⚡ Pregunta rápida: " << question << std::endl << std::endl;
        }
        
        if (useCache) {
            std::string hash = generateHash(question, model);
            auto it = ollamaCache.find(hash);
            if (it != ollamaCache.end()) {
                auto now = std::chrono::system_clock::now();
                if (now < it->second.expiry) {
                    if (quiet) {
                        std::cout << it->second.response["response"].get<std::string>() << std::endl;
                    } else {
                        std::cout << "⚡ Respuesta rápida desde cache:" << std::endl;
                        std::cout << it->second.response["response"] << std::endl;
                        std::cout << std::endl << "⚡ Cache hit - tiempo instantáneo" << std::endl;
                    }
                    return it->second.response;
                } else {
                    ollamaCache.erase(it);
                }
            }
        }
        
        int max_tok = 20;
        if (const char* e = std::getenv("BUTLER_FAST_MAX_TOKENS")) {
            int v = std::atoi(e);
            if (v > 0) {
                max_tok = v;
            }
        }
        double temp = 0.1;
        if (const char* e = std::getenv("BUTLER_FAST_TEMPERATURE")) {
            temp = std::strtod(e, nullptr);
        }
        json data = chat_payload(model, question, max_tok, temp);
        
        auto start = std::chrono::high_resolution_clock::now();
        
        json raw = makeRequest(data, "/v1/chat/completions");
        json response = normalize_chat_response(raw);
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        // Guardar en cache
        if (useCache && has_assistant_text(response)) {
            std::string hash = generateHash(question, model);
            CacheEntry entry;
            entry.response = response;
            entry.expiry = std::chrono::system_clock::now() + std::chrono::seconds(CACHE_EXPIRY);
            ollamaCache[hash] = entry;
        }
        
        if (has_assistant_text(response)) {
            if (quiet) {
                std::cout << response["response"].get<std::string>() << std::endl;
            } else {
                std::cout << "✅ Respuesta rápida:" << std::endl;
                std::cout << response["response"] << std::endl;
                std::cout << std::endl << "⚡ Tiempo: " << duration.count() << "ms" << std::endl;
            }
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
        std::cout << "🤖 Estado (llama-server / OpenAI API):" << std::endl;
        std::cout << "   Modelo: " << model << std::endl;
        std::cout << "   Endpoint: " << endpoint << std::endl;
        std::cout << "   Cache: " << ollamaCache.size() << " elementos" << std::endl;
        
        json response = makeGetRequest("/v1/models");
        
        if (!response.empty() && response.contains("data")) {
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
    json makeGetRequest(const std::string& path) {
        CURL* curl = curl_easy_init();
        if (!curl) {
            std::cerr << "❌ Error: No se pudo inicializar CURL" << std::endl;
            return json();
        }
        std::string url = endpoint + path;
        std::string response;
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, timeout);
        CURLcode res = curl_easy_perform(curl);
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

    json makeRequest(const json& data, const std::string& path = "/v1/chat/completions") {
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

static std::string join_argv(int argc, char** argv, int start) {
    std::string s;
    for (int i = start; i < argc; ++i) {
        if (i > start) {
            s += ' ';
        }
        s += argv[i];
    }
    return s;
}

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
        std::cout << "Env: BUTLER_MACHINE_OUTPUT=1 (stdout solo texto), BUTLER_SYSTEM_PROMPT, BUTLER_MAX_TOKENS, ..." << std::endl;
        return 1;
    }
    
    OllamaClient client;
    
    std::string command = argv[1];
    
    if (command == "ask" && argc > 2) {
        std::string question = join_argv(argc, argv, 2);
        client.ask(question);
    } else if (command == "fast" && argc > 2) {
        std::string question = join_argv(argc, argv, 2);
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