#pragma once
#include <cctype>
#include <cstdlib>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>

namespace bc {

inline std::string trim_end_slash(std::string s) {
    while (!s.empty() && s.back() == '/') {
        s.pop_back();
    }
    return s;
}

inline std::string default_endpoint() {
    const char* b = std::getenv("BUTLER_ENDPOINT");
    if (b && b[0]) {
        return trim_end_slash(std::string(b));
    }
    const char* o = std::getenv("OLLAMA_ENDPOINT");
    if (o && o[0]) {
        return trim_end_slash(std::string(o));
    }
    return "http://127.0.0.1:8080";
}

inline std::string default_model() {
    const char* b = std::getenv("BUTLER_MODEL");
    if (b && b[0]) {
        return std::string(b);
    }
    const char* o = std::getenv("OLLAMA_MODEL");
    if (o && o[0]) {
        return std::string(o);
    }
    return "local";
}

inline std::string json_escape(const std::string& s) {
    std::string o;
    o.reserve(s.size() + 8);
    for (unsigned char c : s) {
        if (c == '\\') {
            o += "\\\\";
        } else if (c == '"') {
            o += "\\\"";
        } else if (c == '\n') {
            o += "\\n";
        } else if (c == '\r') {
            o += "\\r";
        } else if (c == '\t') {
            o += "\\t";
        } else {
            o += static_cast<char>(c);
        }
    }
    return o;
}

inline std::string chat_body(const std::string& model, const std::string& user_text, int max_tokens, double temperature) {
    std::ostringstream oss;
    oss << "{\"model\":\"" << json_escape(model) << "\",\"messages\":[{\"role\":\"user\",\"content\":\""
        << json_escape(user_text) << "\"}],\"stream\":false,\"max_tokens\":" << max_tokens << ",\"temperature\":"
        << temperature << "}";
    return oss.str();
}

inline std::string parse_assistant_content(const std::string& raw) {
    const std::string key = "\"content\"";
    size_t pos = raw.find(key);
    if (pos == std::string::npos) {
        return raw;
    }
    pos = raw.find(':', pos + key.size());
    if (pos == std::string::npos) {
        return raw;
    }
    pos++;
    while (pos < raw.size() && std::isspace(static_cast<unsigned char>(raw[pos]))) {
        pos++;
    }
    if (pos >= raw.size() || raw[pos] != '"') {
        return raw;
    }
    pos++;
    std::string out;
    while (pos < raw.size()) {
        char c = raw[pos];
        if (c == '\\') {
            if (pos + 1 < raw.size()) {
                char n = raw[pos + 1];
                if (n == 'n') {
                    out += '\n';
                    pos += 2;
                    continue;
                }
                if (n == 'r') {
                    out += '\r';
                    pos += 2;
                    continue;
                }
                if (n == 't') {
                    out += '\t';
                    pos += 2;
                    continue;
                }
                if (n == '"' || n == '\\') {
                    out += n;
                    pos += 2;
                    continue;
                }
            }
            out += c;
            pos++;
            continue;
        }
        if (c == '"') {
            break;
        }
        out += c;
        pos++;
    }
    return out;
}

inline std::string http_get_curl(const std::string& url, int timeout_sec) {
#if defined(_WIN32)
    std::string cmd = "curl.exe -s --max-time " + std::to_string(timeout_sec) + " \"" + url + "\"";
    FILE* pipe = _popen(cmd.c_str(), "r");
#else
    std::string cmd = "curl -s --max-time " + std::to_string(timeout_sec) + " " + url;
    FILE* pipe = popen(cmd.c_str(), "r");
#endif
    if (!pipe) {
        return "";
    }
    std::string result;
    char buffer[512];
    while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        result += buffer;
    }
#if defined(_WIN32)
    _pclose(pipe);
#else
    pclose(pipe);
#endif
    return result;
}

} // namespace bc
