# Cursor Butler (llama.cpp local)

Local AI for Cursor via `llama-server` (OpenAI-compatible API).

- Endpoint: `http://127.0.0.1:8080`
- Tests: `test/` (Butler). `test/legacy/` holds only `README.md` (excluded from parse CI).

Spanish: [README.es.md](README.es.md). Process: [DMAIC.md](DMAIC.md).

## Quick start

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/setup_butler.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/install_profile.ps1 -Yes
```

## Verify (integration)

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File verify.ps1
```

Uses `test/ping_model.ps1` then `test/run_3_programs_and_evaluate.ps1`. Flags: `-SkipPing`, `-PingTimeoutSec`.

## CI gates (no server except verify)

- Parse: `pwsh -NoProfile -File scripts/ci_parse_pwsh.ps1`
- Unit: `pwsh -NoProfile -File scripts/run_unit_tests.ps1` (victory gate for PS/C++ bridge contract)

## Layout (short)

| Area | Role |
|------|------|
| `cpp/` | Single client source; build → `ollama_client` / `.exe` |
| `powershell/` | Setup, profile, C++ bridge (no duplicate chat implementations) |
| `python/` | Thin `butler_wrapper.py` → same binary as profile |
| `test/` | Ping, eval runner, optional UI/form demos under `generated/`, Pester under `unit/` |

Full table: `INDEX.md`.

## Conventions

- `powershell/butler_profile.ps1`: bounded cache (`BUTLER_CACHE_MAX_ENTRIES`, default 1000).
- Canonical HTTP chat: `cpp/ollama_client.cpp`; bridge `powershell/ButlerCppBridge.ps1`; override `BUTLER_CPP_CLIENT`.
- Python: `python/butler_wrapper.py` only (forwards argv to C++ binary).

## Reproducibility (benchmarks)

Log CPU/GPU, `llama-server` build, GGUF path, flags (e.g. `--ctx-size`). Logs: `.butler/logs/`.

## Better than previous GitHub baseline

- One canonical runtime: `cpp/ollama_client.cpp` (no multi-client drift).
- Product docs consolidated under `docs/` with one product-facing index.
- Deterministic gates: parse + unit + integration (`verify.ps1`) as release criteria.
- Cleaner scope: legacy Ollama-era payloads removed from active product path.
- Clear bridge model: PowerShell/Python are wrappers around canonical C++ behavior.
