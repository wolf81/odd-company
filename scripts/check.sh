#!/usr/bin/env bash
# Checks the project: type-checks all Luau code with luau-lsp, then makes a
# test build with Rojo. Run from the repo root:  bash scripts/check.sh
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p build

# Tools installed by Rokit (see rokit.toml). Fall back to ~/.rokit/bin if
# this shell's PATH doesn't have them yet.
ROJO=$(command -v rojo || echo "$HOME/.rokit/bin/rojo")
LUAU_LSP=$(command -v luau-lsp || echo "$HOME/.rokit/bin/luau-lsp")

# Roblox API type definitions for luau-lsp (downloaded once; delete the
# file to refresh it after Roblox API updates).
DEFS=build/globalTypes.d.luau
if [ ! -f "$DEFS" ]; then
	echo "Downloading Roblox type definitions..."
	curl -sSfL -o "$DEFS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi

echo "== Type check (luau-lsp) =="
"$ROJO" sourcemap -o sourcemap.json
"$LUAU_LSP" analyze --definitions="$DEFS" --sourcemap=sourcemap.json src

echo "== Build (rojo) =="
"$ROJO" build -o build/test.rbxl

echo "All checks passed."
