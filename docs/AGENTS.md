# AGENTS (AI-only)

Non-verbose contract. Humans: `README.md`.

## Read order

1. `AGENTS.md` (this)
2. `README.md` (facts + commands)
3. `DMAIC.md` only if changing process, scope, or multi-phase refactors

## Invariants

- Backend: **llama-server** OpenAI API `http://127.0.0.1:8080`, model default **`local`**.
- **All product markdown** lives under **`docs/`** (except repo root stub `../README.md`). Do not add sibling `.md` at root.
- Spanish mirror: **`README.es.md`** must match **`README.md`** facts.

## Gates (green = ship)

| Gate | Command |
|------|---------|
| Unit | `pwsh -NoProfile -File scripts/run_unit_tests.ps1` |
| Parse | `pwsh -NoProfile -File scripts/ci_parse_pwsh.ps1` |
| Integration | `pwsh -NoProfile -File verify.ps1` (needs server) |

## Core paths

| Role | Path |
|------|------|
| Chat (canonical) | `cpp/ollama_client.cpp` → `ollama_client.exe`; env `BUTLER_CPP_CLIENT` |
| PS bridge | `powershell/ButlerCppBridge.ps1` |
| Profile | `powershell/butler_profile.ps1` (C++ if exe exists, else HTTP) |
| Setup | `powershell/setup_butler.ps1` |
| Py shim | `python/butler_wrapper.py` |
| Unit tests | `test/unit/*.Tests.ps1`, stub `test/fixtures/stub_butler_client.cmd` |

## Orchestration rules

- One PR = one concern; PR text lists gates run + pass/fail.
- No new features under archived paths or `video/tools/**` vendor trees.
- Doc edits: update **both** `README.md` and `README.es.md` when user-facing facts change.
- Contradiction check: `README.md`, `README.es.md`, `DMAIC.md`, `AGENTS.md`, `.cursorrules` (paths under `docs/` from repo root: `docs/…`).

## Index

See **`INDEX.md`** for full doc map.
