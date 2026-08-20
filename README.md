# Aoxilus Butler 🥑🚀

**Local AI for developers** — run an OpenAI-compatible API on your machine with [llama.cpp](https://github.com/ggerganov/llama.cpp) (`llama-server`), integrate with your editor and your shell, and ship with reproducible checks.

If you are from the `var aguacate = x; function aguacate(){}` school: you are home. 🥑

## Why this is good 🧠

- 🔒 **Local-first**: prompts stay on your machine.
- ⚙️ **One canonical runtime**: C++ core, thin wrappers.
- ✅ **Real quality gates**: parse + unit + integration.
- 🧰 **Terminal friendly**: setup and verify scripts ready to run.

## Quick start (2 commands) 🟢

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/setup_butler.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File verify.ps1
```

`verify.ps1` runs:
1. `test/ping_model.ps1`
2. `test/run_3_programs_and_evaluate.ps1`

Use `-SkipPing` or `-PingTimeoutSec` when needed.

## Terminal example (Fibonacci 🥑)

```powershell
# If profile is installed:
code "Write a PowerShell script that prints the first 10 Fibonacci numbers."

# Direct endpoint call:
$body = @{
  model = "local"
  messages = @(
    @{ role = "user"; content = "Write a PowerShell script that prints the first 10 Fibonacci numbers. Output only code." }
  )
  temperature = 0.2
  max_tokens = 300
  stream = $false
}
Invoke-RestMethod -Uri "http://127.0.0.1:8080/v1/chat/completions" -Method Post -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 8)
```

## What we publish to GitHub 📦

- `cpp/` → canonical client (`cpp/ollama_client.cpp`)
- `powershell/` → setup/profile/bridge scripts
- `python/` → `butler_wrapper.py` shim
- `test/` + `scripts/` + `verify.ps1` → validation flow
- Root docs (`README.md`, `CHANGELOG.md`, etc.) → product-facing only

## What we do NOT publish (local noise) 🙈

- Model files, local caches, logs, machine-specific artifacts
- Personal notes/work-in-progress scratch

Use `.gitignore` to keep those out. That is part of the secret sauce. 🤫🥑

## Build C++ client 🛠️

```bash
cd cpp
make build
```

Set `BUTLER_CPP_CLIENT` if your binary path is custom.

## CI / local gates 🧪

```powershell
pwsh -NoProfile -File scripts/ci_parse_pwsh.ps1
pwsh -NoProfile -File scripts/run_unit_tests.ps1
```

## License

MIT — see [LICENSE](LICENSE).

Made with 🥑 by [aoxilus](https://github.com/aoxilus)
