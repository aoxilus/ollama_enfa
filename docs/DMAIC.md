# DMAIC — Cursor Butler (llama.cpp local)

**AI:** `docs/AGENTS.md` for orchestration. Product markdown lives under `docs/`.

Structured improvement loop for this repo. **CTQ** = reliable local inference + reproducible verification on Windows.

---

## Define

| Item | Content |
|------|---------|
| **Customer / user** | Developer using Cursor + PowerShell; wants a local OpenAI-compatible endpoint without cloud dependency. |
| **Problem** | Drift between docs, scripts, and runtime (wrong backend name, wrong folders, flaky “it works on my machine”). |
| **Goal** | One **official** green/red check after setup; single test tree under `test/`; profile install safe to re-run. |
| **Scope (in)** | `verify.ps1`, `test/*`, `test/unit/*`, `powershell/butler_profile.ps1`, `powershell/ButlerCppBridge.ps1`, `setup_butler.ps1`, `install_profile.ps1`, `scripts/ci_parse_pwsh.ps1`, `scripts/run_unit_tests.ps1`, canonical `cpp/ollama_client.cpp`. |
| **Scope (out)** | Archived/removed legacy paths (Ollama-era; excluded from active checks). |
| **CTQs** | (1) **`scripts/run_unit_tests.ps1` exit 0** (Pester; proves bridge + stub contract); (2) `verify.ps1` exit 0 when server+model OK (integration); (3) `ci_parse_pwsh.ps1` exit 0; (4) profile idempotent install. |

---

## Measure

| Metric | Operational definition | How |
|--------|------------------------|-----|
| **End-to-end pass** | All three generated programs in `run_3_programs_and_evaluate.ps1` pass | `verify.ps1` (ping + runner) |
| **Quick availability** | API answers a trivial completion | `test/ping_model.ps1` (invoked by `verify.ps1` unless `-SkipPing`) |
| **Static quality** | No parse errors on canonical scripts | `pwsh -NoProfile -File scripts/ci_parse_pwsh.ps1` |
| **Unit suite (victory gate)** | Bridge resolves client; stub `ask`/`fast` return expected stdout (no server) | `pwsh -NoProfile -File scripts/run_unit_tests.ps1` |
| **Reproducibility (if benchmarking)** | Numbers comparable across machines | Log CPU/GPU, `llama-server` build, GGUF path, flags (e.g. `--ctx-size`); logs under `.butler/logs/` |

Record **before/after** when changing model, server build, or prompts.

---

## Analyze

| Failure mode | Likely cause | Signal |
|--------------|--------------|--------|
| Ping fails | Server down, wrong port/host, firewall | `PING_FAIL` / connection error |
| Runner fails (exit 2) | Model name mismatch, weak generation, prompt/API change | `programN FAIL` lines |
| “Profile broken” | Duplicate dot-source or wrong path | Manual profile edit; use marked block from `install_profile.ps1` |
| CI red (parse) | Syntax error in `test/` or core `powershell/*` | `PARSE_FAIL` path in CI log |
| CI red (unit) | Bridge regression or Pester failure | `run_unit_tests.ps1` / Pester output |
| Doc contradiction | Second source of truth | Compare `docs/README.md`, `docs/README.es.md`, `docs/AGENTS.md`, `.cursorrules` |

---

## Improve

Already implemented (examples):

- Official runner + ping orchestration in `verify.ps1` (`-SkipPing`, `-PingTimeoutSec`).
- Bounded cache + eviction + `BUTLER_CACHE_MAX_ENTRIES` in `butler_profile.ps1`.
- Idempotent `install_profile.ps1` with markers + `-Yes`.
- `RequestTimeoutSec` wired into chat calls in `run_3_programs_and_evaluate.ps1`.
- `scripts/ci_parse_pwsh.ps1` + GitHub Actions workflow for the Butler-critical path.
- **C++ canonical chat** (`cpp/ollama_client.cpp`): `BUTLER_MACHINE_OUTPUT`, `BUTLER_SYSTEM_PROMPT`, `BUTLER_MAX_TOKENS`, joined argv for `ask`/`fast`.
- **`powershell/ButlerCppBridge.ps1`** + profile prefers C++ when `ollama_client.exe` or `BUTLER_CPP_CLIENT` exists; else HTTP fallback.
- **`python/butler_wrapper.py`** forwards argv to the C++ client with machine output.
- **Pester** `test/unit/ButlerBridge.Tests.ps1` + stub `test/fixtures/stub_butler_client.cmd`; **`scripts/run_unit_tests.ps1`**.

Backlog (prioritize by impact):

- Repair or quarantine obsolete scripts under `powershell/` if discovered (optional scope expansion).
- Pin or checksum `llama-server` + GGUF in docs/runbook for supply-chain clarity.
- Add one more deterministic eval case in `test/` if regressions appear on model upgrades.

---

## Improve Execution Plan (for AI agents)

Objective: converge to a sellable cross-platform architecture with **C++ core + Python distribution layer + minimal PowerShell bootstrap**.

### Approved direction (simplicity / one core)

**Yes:** one **C++ client binary** owns chat, cache, and HTTP to the same OpenAI-compatible **endpoints** (`/v1/chat/completions`, `/v1/models`). **Python** and **PowerShell** must not re-implement that logic in the long term; they only **invoke the binary** (or ship it), set `BUTLER_ENDPOINT` / `BUTLER_MODEL`, and handle UX (profile aliases, `pip install`, CI).

**Clarifications**

- **Endpoints** live on **llama-server** (still the inference process). C++ talks HTTP to them; Py/PS do not need their own HTTP client for “ask” once the wrapper lands.
- **Orchestration** (download GGUF, start `llama-server`, `verify.ps1`) can stay **PowerShell** - that is installer/test glue, not duplicate *chat* runtime.
- **Migration** is incremental: keep `verify.ps1` green; replace duplicated clients only after the canonical binary is buildable on every path you care about.

### Guardrails (must follow)

- Keep one source of truth for runtime logic: C++ only.
- Do not duplicate chat/cache/business logic in PowerShell.
- Python is allowed as wrapper/distribution (`pip`) and tests, not as a second core runtime.
- Keep obsolete scripts archived only; no new features in archived paths.
- Every phase must keep **`scripts/run_unit_tests.ps1` green** and `verify.ps1` green when integration is in scope.

### Phase 1 — Canonical runtime (C++ only)

Owner: AI-Cpp-Refactor

Tasks:

- Canonical client: `cpp/ollama_client.cpp` (alternate `.cpp` variants removed).
- Extract repeated flow (`ask`, `askFast`, `askAsync` common pipeline) into shared internal functions.
- Ensure one cache strategy, one HTTP strategy, one command map.

Definition of done:

- No duplicated client variants with active feature drift.
- `cpp` docs describe one canonical binary and one command surface.

### Phase 2 — Python distribution layer (no duplicated core logic)

Owner: AI-Python-Packaging

Tasks:

- Create/clean a Python package path dedicated to distribution/SDK ergonomics.
- Wire Python calls to canonical C++ interface (wrapper or subprocess bridge).
- Provide minimal smoke tests for Linux/macOS/Windows install paths.
- Publish packaging metadata and reproducible install instructions.

Definition of done:

- Python package installs and can execute core commands without re-implementing runtime internals.
- Documentation clearly states Python is a wrapper layer over C++ core.

### Phase 3 — PowerShell minimization

Owner: AI-PowerShell-Hardening

Tasks:

- Keep only setup/verify/profile bootstrap scripts in active path.
- De-duplicate profile functionality in favor of `powershell/butler_profile.ps1`.
- Move remaining non-core scripts to archive paths.
- Keep idempotent install/uninstall behavior.

Definition of done:

- PowerShell scripts are thin orchestration only.
- No duplicated model/chat/cache implementation in PowerShell.

### Phase 4 — Repo slimming and dependency policy

Owner: AI-Repo-Cleanup

Tasks:

- Separate heavy video toolchains from core Butler path (submodule, archive, or independent workspace).
- Keep main CI and verify focused on core product path.
- Add dependency policy: any new dependency requires explicit runtime value and owner.

Definition of done:

- Core repo checkout is significantly smaller and easier to reason about.
- CI scope matches product scope (Butler core first).

### Phase 5 — Cross-platform release contract

Owner: AI-Release-Engineer

Tasks:

- Define release artifacts for Linux/macOS/Windows.
- Standardize install docs and verification commands per platform.
- Add release checklist: setup, verify, smoke test, rollback note.

Definition of done:

- A new user on each platform can install, run, and verify using one documented path.

### Agent handoff template (use in PR description)

- Scope:
- Files touched:
- Risk:
- Verify command(s) run:
- Result:
- Follow-up for next phase:

---

## Control

| Control | Owner | Trigger |
|---------|--------|---------|
| **Repo contract** | Maintainers + AI assistants | `.cursorrules` — do not contradict `docs/README.md` / `docs/README.es.md` / `docs/AGENTS.md` |
| **Release gate** | Contributor | Run `verify.ps1` after any change to setup, runner, or profile |
| **Static gate** | CI + local | `scripts/ci_parse_pwsh.ps1` on push/PR |
| **Unit gate** | CI + local | `scripts/run_unit_tests.ps1` after parse job |
| **Change review** | PR | If prompts or assertions in `run_3_programs_and_evaluate.ps1` change, note in PR description |

**SOP (short):** after `setup_butler` or model swap → `verify.ps1` → if red, check `.butler/logs/` and ping with `test/ping_model.ps1` manually.

---

*DMAIC is a cycle: re-run **Measure → Analyze → Improve** when the server, model, or evaluation prompts change.*
