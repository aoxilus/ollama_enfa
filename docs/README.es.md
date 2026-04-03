# Cursor Butler (llama.cpp local)

Integracion local con `llama-server` (API compatible con OpenAI).

- Endpoint: `http://127.0.0.1:8080`
- Pruebas: `test/`

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

Flags: `-SkipPing`, `-PingTimeoutSec`. Runner: `test/run_3_programs_and_evaluate.ps1`; ping: `test/ping_model.ps1`.

## CI

- Parse: `scripts/ci_parse_pwsh.ps1`
- Unit: `scripts/run_unit_tests.ps1` (contrato bridge)

## Estructura (resumen)

| Area | Rol |
|------|-----|
| `cpp/` | Unico cliente; build → `ollama_client` / `.exe` |
| `powershell/` | Setup, perfil, puente C++ |
| `python/` | `butler_wrapper.py` → mismo binario |
| `test/` | Ping, evaluacion, demos `generated/`, Pester `unit/` |

Detalle completo: `INDEX.md`.

## Notas

Cache acotada en `butler_profile.ps1`. Chat canonico: `cpp/ollama_client.cpp` + `ButlerCppBridge.ps1`. Variable `BUTLER_CPP_CLIENT`. Python: solo `python/butler_wrapper.py` (reenvío al binario C++).

## Reproducibilidad

CPU/GPU, build del servidor, GGUF, flags. Logs en `.butler/logs/`.

## Mejoras respecto al baseline anterior

- Un runtime canonico en C++ sin variantes duplicadas.
- Documentacion de producto consolidada en `docs/`.
- Gates: parse + unit + `verify.ps1`.
- PS/Python solo envoltorio del cliente C++.
