# CLAUDE.md

Guidance for Claude (and any AI assistant) working in this repository.

## What this project is

**Build A Base And Raid 💥** — a Roblox base-building / loot-stealing PvP game targeting **20K+ CCU**.
Solo developer (`hlpdev`): strong programmer, UI, and systems; **no 3D modeling capability**. Art
direction is therefore deliberately primitive-based (neon/emissive Parts, particles, unions) — treat
that as a style, not a gap to apologize for.

## Working arrangement (important)

- The developer writes the **Lua/Luau** code by hand. When Lua is needed, **present it in chat** as
  complete, paste-ready modules with the target path stated — do **not** write `.luau` files to disk
  unless explicitly asked.
- Claude owns everything that is **not** Lua: docs, config, project/manifest files, CI, scripts,
  repo/tooling setup.
- Claude's role is **advisor first**. Challenge weak decisions with reasoning. Do not be a yes-man.
  If a request will hurt retention, scaling, or security, say so and propose the better path.

## Golden rules (architecture)

1. **Server is the single source of truth.** The client renders replicated state and sends
   *intents*, never *outcomes*. The client never says "I completed the steal" — the server runs the
   channel timer and validates position every tick. See `docs/ANTI_EXPLOIT.md`.
2. **`src/shared` is pure.** Deterministic, no side effects, no service singletons, safe to require
   from both realms. Definitions and math live here; behavior does not.
3. **Networking goes through ByteNet packets** defined once in `src/shared/net`. No raw
   RemoteEvents for gameplay traffic — bandwidth is the CCU bottleneck.
4. **All persistence is session-locked via ProfileStore.** Items can be duplicated if two sessions
   touch one profile. Never bypass the session lock.
5. **The steal is an idempotent, ordered transaction** with a transaction ID: remove-from-victim →
   commit → add-to-raider → commit. Design for a server dying mid-transfer. See `docs/DATA_MODEL.md`.
6. **Every connection, thread, and instance goes in a Trove.** Long-session servers die from leaks.
7. **Cap per-base placeables (~50) and stream distant bases out.** Instance count is what kills the
   CCU target, not CPU.

## Code conventions

- `--!strict` at the top of every Luau file. Types are not optional; `ItemDefs` is a typed table
  with an exported `type ItemDef`.
- **Vide's parenthesis-less call style is house style** (`source "x"`, `create "Frame" { ... }`).
  StyLua is configured with `call_parentheses = "Input"` so it preserves whatever the author wrote —
  do not "fix" paren style in either direction.
- Formatting: **Tabs**, width 100, double quotes. Run `just fmt`. CI runs `stylua --check`.
- Linting: `selene` + `luau-lsp analyze`. `shadowing` is allowed (Vide scopes shadow deliberately).
- Requires use `.luaurc` aliases where they help: `@shared`, `@server`, `@client`, `@pkg`, `@srvpkg`.
- Server services and client controllers are single-responsibility modules with an explicit
  lifecycle (`.init` / `.start`), loaded by a small hand-rolled loader — **do not add Knit or a DI
  framework** for this.

## Toolchain / workflow

- Tools are pinned in `rokit.toml`; `rokit install` restores them. Packages via `wally install`.
- After changing dependencies or moving files: regenerate the sourcemap and re-inject package types
  (`just types`) or luau-lsp autocomplete goes stale.
- `just check` = `fmt-check` + `lint` + `test`; this mirrors CI. Keep `main` green — it's a public
  resume repo.
- `wally.lock` is **committed**. Package folders (`Packages/`, `ServerPackages/`, `DevPackages/`)
  are **git-ignored** and restored on install.

## Content authoring

Adding an item, rarity, or building should be a **one-file diff** in `src/shared/defs/`. If a change
touches more than the def table plus one behavior module, the abstraction is wrong — flag it.

## When unsure

- Prefer the smallest change that keeps the golden rules intact.
- If a decision affects economy balance, retention, or exploitability, surface the trade-off and
  give a recommendation rather than silently picking.
- Verify package/tool versions against the Wally index and `rokit.toml` before citing them; don't
  quote versions from memory.
