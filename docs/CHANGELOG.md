# Changelog

Product documentation index: [INDEX.md](INDEX.md). AI contract: [AGENTS.md](AGENTS.md).

## Unreleased

- Product markdown consolidated under `docs/`; root `README.md` is stub only.
- Removed duplicate `cpp/*.cpp` clients, Ollama-era `python/` and `powershell/` scripts, and `test/legacy/` payloads; canonical chat remains `cpp/ollama_client.cpp`; Python shim `python/butler_wrapper.py` only.
- Release gates clarified and passing locally: `scripts/ci_parse_pwsh.ps1`, `scripts/run_unit_tests.ps1`, `verify.ps1`.

### Why this is better than old GitHub state

- Less architectural drift: one canonical runtime path.
- Smaller maintenance surface: removed duplicate/legacy clients and scripts.
- Stronger reliability: explicit green/red gates before shipping.
- Better contributor alignment: `docs/AGENTS.md` defines one contract for AI and humans.

---
