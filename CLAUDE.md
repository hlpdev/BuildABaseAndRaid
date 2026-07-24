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

## The game model (read before touching systems)

- **Buy parts, roll loot.** Building parts are purchased (coin sink); gear/abilities/raid-tools/props
  are rolled (gacha faucet).
- **Live same-server bases.** A player's base rebuilds into the world when they're online and is
  **raidable only while they're online**; offline = removed from world = safe. There is **no** async
  snapshot raiding. The economy is per-account (profiles) + cross-server (flea, matchmaking).
- **Full destruction, no physics.** Parts have HP + material tier; raid tools deal typed damage;
  destroyed at 0 HP; a server-side **support graph** (event-driven, not per-frame) handles collapse.
- **Full-loot on death for carried items; currency never drops.** Deliberate Delete-drop exists.
  Vaulted items are safe unless breached.
- **Hidden MMR** bands players into reserved servers; players see a friendly level only.
- **Order-book flea market** ships last but the item model supports it from day one.
- **Mobile/console-first.** Every interaction works thumb-on-glass and on gamepad; KBM is third. No
  system reads raw input — all go through `InputController` intents. See `docs/PLATFORMS_AND_INPUT.md`.
- **Dummy models now.** Parts/items are colored primitives; real models swap in behind the def tables
  later. Content lives in `src/shared/defs` — adding an item/part is a one-file diff.
- **Rarity ≠ price/stats.** A tier sets *only* drop rate + UI color. Item stats are per-item; price is
  market-only. There are **more than six** tiers.
- **Vaults are placeable & plural** — multiple types/levels, placed anywhere; income sums across them.
- **The Forge** combines N same-rarity items into one random next-rarity item (item sink + gamble).

## Golden rules (architecture)

1. **Server is the single source of truth.** The client renders replicated state and sends
   *intents*, never *outcomes*. Breach damage, vault extraction, and casts are server-timed and
   validated every tick. See `docs/ANTI_EXPLOIT.md`.
2. **The item-UID single-location invariant is sacred.** Every item is a server-minted global UID in
   exactly one of {inventory, vault, ground, flea escrow}, moved only by the server, only atomically.
   This is the root dupe/fraud defense. See `docs/DATA_MODEL.md`.
3. **`src/shared` is pure.** Deterministic, no side effects, no singletons, safe from both realms.
   Definitions and math live here; behavior does not.
4. **Networking goes through ByteNet packets** in `src/shared/net`. No raw RemoteEvents for gameplay;
   deltas on the hot path. Bandwidth is a CCU bottleneck.
5. **All persistence is session-locked via ProfileStore.** Never bypass the session lock.
6. **Value moves are idempotent `txId` transactions**, ordered so the worst-case failure is a delayed
   credit, never a destroyed item. Design for a server dying mid-transfer.
7. **Every connection, thread, and instance goes in a Trove.** Long-session servers die from leaks.
8. **Hard per-base part cap + stream distant bases out.** Instance count is what kills the CCU
   target, not CPU. Destruction batches removed UIDs into one replication message.
9. **Server owns all stats.** Item damage, part HP, income, MMR, prices — read from def tables or
   computed server-side, never from the wire.

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
