# Cursor Butler (llama.cpp local)

**IA:** leer primero [AGENTS.md](AGENTS.md).

Integracion local con `llama-server` (API compatible con OpenAI).

- Endpoint: `http://127.0.0.1:8080`
- Pruebas: `test/` (Butler); `test/legacy/` vacío (histórico en git)

Ingles: [README.md](README.md). Proceso: [DMAIC.md](DMAIC.md).

## Inicio rapido

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/setup_butler.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/install_profile.ps1 -Yes
```

## Verificacion

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File verify.ps1
```

Flags: `-SkipPing`, `-PingTimeoutSec`.

## CI

- Parse: `scripts/ci_parse_pwsh.ps1`
- Unit: `scripts/run_unit_tests.ps1` (contrato bridge)

## Notas

Cache acotada en `butler_profile.ps1`. Chat canonico: `cpp/ollama_client.cpp` + `ButlerCppBridge.ps1`. Variable `BUTLER_CPP_CLIENT`. Python: solo `python/butler_wrapper.py` (reenvío al binario C++).

## Reproducibilidad

CPU/GPU, build del servidor, GGUF, flags. Logs en `.butler/logs/`.
