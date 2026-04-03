# C++ client (canonical chat)

Source: `cpp/ollama_client.cpp` → build `ollama_client.exe` (or set `BUTLER_CPP_CLIENT`).

## API target

- `POST /v1/chat/completions`, `GET /v1/models`
- Default base `http://127.0.0.1:8080`, model `local` (env `BUTLER_*` / `OLLAMA_*`)

## Commands

`ask …`, `fast …`, `status`, `clearcache`, `cachestats` — multi-word prompts: all args after verb joined.

## Env (wrappers)

| Var | Effect |
|-----|--------|
| `BUTLER_MACHINE_OUTPUT=1` | stdout: assistant text only |
| `BUTLER_SYSTEM_PROMPT` | optional system message |
| `BUTLER_MAX_TOKENS` / `BUTLER_TEMPERATURE` | `ask` |
| `BUTLER_FAST_MAX_TOKENS` / `BUTLER_FAST_TEMPERATURE` | `fast` |
| `BUTLER_TIMEOUT_SEC` | HTTP timeout |

Shared helpers: `cpp/butler_openai_compat.hpp` (other `.cpp` samples).

## Build

`cd cpp` + `make build` or compile with libcurl, openssl, nlohmann/json (see vendor docs / Makefile).
