set shell := ["bash", "-uc"]

# List available recipes.
default:
    @just --list

# One-shot: install toolchain, packages, Roblox defs, and generate types.
install:
    rokit install
    wally install
    just defs
    just types

# Fetch Roblox API type definitions + docs for luau-lsp (gitignored, regenerable).
defs:
    mkdir -p .luau-analyze
    curl -fsSL -o .luau-analyze/globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.PluginSecurity.d.luau
    curl -fsSL -o .luau-analyze/api-docs.json https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/api-docs/en-us.json

# Regenerate sourcemap and re-inject Wally-stripped package types.
types:
    rojo sourcemap default.project.json --output sourcemap.json
    wally-package-types --sourcemap sourcemap.json Packages/ || true
    wally-package-types --sourcemap sourcemap.json ServerPackages/ || true

# Serve for live sync into Studio (Rojo plugin connects to this).
serve:
    rojo serve default.project.json

# Serve the DEV place tree instead.
serve-dev:
    rojo serve dev.project.json

# Keep the sourcemap fresh while editing (run alongside `serve`).
watch:
    rojo sourcemap default.project.json --output sourcemap.json --watch

# Format all source.
fmt:
    stylua src/

# Verify formatting without writing (CI uses this).
fmt-check:
    stylua --check src/

# Lint: selene rules + luau-lsp type analysis. Analyze is skipped until src/ has Luau files.
lint:
    selene src/
    @if find src -name '*.luau' | grep -q .; then \
        luau-lsp analyze --sourcemap=sourcemap.json --defs=.luau-analyze/globalTypes.d.luau --docs=.luau-analyze/api-docs.json --settings=.vscode/settings.json --ignore="Packages/**" --ignore="ServerPackages/**" --ignore="DevPackages/**" src/; \
    else echo "no .luau files in src/ yet — skipping analyze"; fi

# Run unit tests. Placeholder until the Jest runner lands (see docs/ROADMAP.md).
test:
    @if [ -f scripts/run-tests.luau ]; then lune run scripts/run-tests; else echo "no test runner yet — skipping (see docs/ROADMAP.md)"; fi

# Build a distributable place file.
build:
    rojo build default.project.json --output build.rbxlx

# Everything CI runs, locally.
check: fmt-check lint test
