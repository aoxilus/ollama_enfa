#!/usr/bin/env python3
"""Thin wrapper: forwards argv to the canonical C++ Butler client (machine stdout)."""
import os
import shutil
import subprocess
import sys


def _resolve_exe() -> str:
    env = os.environ.get("BUTLER_CPP_CLIENT")
    if env and os.path.isfile(env):
        return env
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(here)
    for name in ("ollama_client.exe", "butler_client.exe", "ollama_client", "butler_client"):
        p = os.path.join(root, "cpp", name)
        if os.path.isfile(p):
            return p
    return ""


def main() -> int:
    exe = _resolve_exe()
    if not exe:
        print("butler_wrapper: set BUTLER_CPP_CLIENT or build cpp/ollama_client", file=sys.stderr)
        return 1
    env = os.environ.copy()
    env["BUTLER_MACHINE_OUTPUT"] = "1"
    r = subprocess.run([exe] + sys.argv[1:], env=env)
    return int(r.returncode)


if __name__ == "__main__":
    raise SystemExit(main())
