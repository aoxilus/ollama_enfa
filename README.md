# Cursor Butler 🥑🚀

Local AI that actually ships: fast, reproducible, and clean.

## Why this repo exists 💡

- 🧠 **Local-first AI**: your code stays on your machine.
- ⚡ **One canonical runtime**: C++ core, less drift, fewer surprises.
- 🛠️ **Practical DX**: setup + verify scripts that work from terminal.
- ✅ **Real gates**: parse, unit, and integration checks before shipping.

## Quick start (2 commands) 🟢

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File powershell/setup_butler.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File verify.ps1
```

If `verify.ps1` is green, your local stack is good to go. 🥑

## What you get 📦

- 🤖 Local endpoint on `http://127.0.0.1:8080`
- 🧪 Deterministic validation (`verify.ps1`)
- 🔧 PowerShell profile integration
- 🌍 Cross-platform wrapper path (C++ + Python bridge)

## Docs map 📚

- 🗺️ `docs/INDEX.md`
- 📘 `docs/README.md`
- 🌎 `docs/README.es.md`
- 📈 `docs/DMAIC.md`
