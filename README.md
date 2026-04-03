# Cursor Butler

**Local AI for developers** — run an OpenAI-compatible API on your machine with [llama.cpp](https://github.com/ggerganov/llama.cpp) (`llama-server`), integrate with **Cursor** and your shell, and ship changes only after reproducible checks.

## Why teams use this

- **Data stays local** — no cloud round-trip for your prompts during development.
- **One canonical client** — C++ runtime; PowerShell and Python stay thin wrappers.
- **Deterministic quality gates** — PowerShell parse checks, Pester unit tests, and an integration script that pings the server then runs structured evaluations.

## Architecture (short)

| Layer | Role |
|--------|------|
| **llama-server** | GGUF model + HTTP API (default `http://127.0.0.1:8080`, model id `local`) |
| **`cpp/ollama_client.cpp`** | Canonical chat client (`POST /v1/chat/completions`) |
| **`powershell/ButlerCppBridge.ps1`** | Invokes the built binary; override path with `BUTLER_CPP_CLIENT` |
| **`powershell/butler_profile.ps1`** | Shell commands (`ask`, `fast`, …); uses C++ when the exe exists |
| **`python/butler_wrapper.py`** | Optional: forwards argv to the same binary with machine-oriented stdout |

## Requirements

- **Windows** workflows are first-class (`pwsh`). A working **llama-server** binary and a **GGUF** model (see `powershell/setup_butler.ps1` for defaults).
- To build the C++ client: toolchain with **C++17**, **libcurl**, **OpenSSL**, **nlohmann/json** (see `cpp/Makefile`).

## Quick start

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/setup_butler.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File verify.ps1
```

`verify.ps1` runs `test/ping_model.ps1` (unless `-SkipPing`) then `test/run_3_programs_and_evaluate.ps1`. Use `-PingTimeoutSec` if the server is slow to load the model.

## PowerShell profile (optional)

Install the managed profile block (idempotent):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/install_profile.ps1 -Yes
```

Uninstall: `powershell/uninstall_profile.ps1`.

## Building the C++ client

```bash
cd cpp
make build
# Windows (MSYS2): use the Makefile targets or compile ollama_client.cpp with -lcurl -lssl -lcrypto
```

Output name: `ollama_client` or `ollama_client.exe`. Set `BUTLER_CPP_CLIENT` to a full path if the binary lives elsewhere.

## Repository layout

| Path | Purpose |
|------|---------|
| `powershell/` | Setup, profile, C++ bridge |
| `cpp/` | Canonical HTTP client source |
| `python/` | `butler_wrapper.py` shim only |
| `test/` | Ping, evaluation runner, fixtures, Pester tests under `test/unit/` |
| `scripts/` | `ci_parse_pwsh.ps1`, `run_unit_tests.ps1` |
| `verify.ps1` | Official integration entry point |

`test/legacy/` is reserved (no active product scripts).

## CI / local gates

```powershell
pwsh -NoProfile -File scripts/ci_parse_pwsh.ps1
pwsh -NoProfile -File scripts/run_unit_tests.ps1
```

## Privacy & security

This project is oriented toward **local inference**. You choose the model and where it runs; outbound traffic depends only on your server configuration (e.g. model download during setup).

## License

See [LICENSE](LICENSE).

## Trademark note

*Cursor* is a trademark of its respective owner. This repository is an independent integration template and is not affiliated with or endorsed by Cursor or the llama.cpp project.
