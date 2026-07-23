# Build A Base And Raid 💥

A high-retention, PvP base-building and loot-stealing game for Roblox, built for **20K+ CCU**.

You roll for loot at your base. Loot is **dual-purpose** — carry it to fight, or lock it in your
vault for passive income. Other players raid your base and steal from your vault. Every item is a
live risk/reward decision, and there is no idle state. That tension is the whole game.

> **Status:** Pre-alpha. Toolchain, project structure, and design docs are in place; gameplay
> systems are being implemented. See [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## Why this project exists

This is a portfolio-grade Roblox project engineered like production software: server-authoritative,
session-locked persistence, buffer-serialized networking, strict Luau typing, CI, and a
fast-iteration Rojo workflow. The design target is a genuinely sticky game loop — high D1 **and** D7
retention — not a tech demo.

## Tech stack

| Concern            | Choice                                    | Why |
| ------------------ | ----------------------------------------- | --- |
| Toolchain manager  | [Rokit](https://github.com/rojo-rbx/rokit) | Successor to Foreman/Aftman; pins every tool per-project |
| Sync / build       | [Rojo](https://rojo.space) 7              | Filesystem ↔ Studio, place builds |
| Package manager    | [Wally](https://wally.run)                | Reproducible dependency graph |
| UI + reactive state| [Vide](https://centau.github.io/vide/)    | Fine-grained reactivity; parenthesis-less call style |
| Networking         | [ByteNet](https://github.com/ffrostflame/ByteNet) | Buffer serialization — the CCU-critical dependency |
| Persistence        | [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) | Session-locked profiles; no item dupes |
| Cleanup            | [Trove](https://sleitnick.github.io/RbxUtil/api/Trove/) | One `:Destroy()` tears down a whole scope |
| Immutable state    | [Sift](https://csqrl.github.io/sift/)     | Pure table ops that pair with Vide |
| Async              | [Promise](https://eryn.io/roblox-lua-promise/) | Explicit failure modes for DataStore/Teleport |
| Lint / format      | Selene · StyLua · luau-lsp analyze        | Enforced in CI |
| Tests              | Jest (jsdotlua)                           | Unit tests for pure logic |

## Repository layout

```
.
├── default.project.json     # Production Rojo tree
├── dev.project.json         # Studio-only playtest tree
├── wally.toml               # Dependencies (commit wally.lock)
├── rokit.toml               # Pinned toolchain
├── stylua.toml selene.toml .luaurc
├── Justfile                 # Task runner: `just install`, `just serve`, `just check`
├── docs/                    # Architecture + design specs (read these first)
└── src/
    ├── client/              # StarterPlayerScripts — renders replicated state, never authoritative
    │   ├── ui/              # Vide components
    │   └── controllers/     # Input, camera, client-side prediction
    ├── server/              # ServerScriptService — single source of truth
    │   ├── services/        # Roll, Vault, Raid, Economy, Base, Matchmaking
    │   └── data/            # ProfileStore templates + access
    ├── shared/              # ReplicatedStorage — pure, deterministic, no side effects
    │   ├── defs/            # ItemDefs, RarityDefs, BuildingDefs (one-file-diff to add content)
    │   ├── net/             # ByteNet packet definitions
    │   └── util/
    └── replicatedfirst/     # Boot splash / anti-flash loading UI
```

## Getting started

Prerequisites: [Rokit](https://github.com/rojo-rbx/rokit) installed. Everything else is pinned in
`rokit.toml` and restored automatically.

```bash
rokit install     # rojo, wally, stylua, selene, luau-lsp, just — all pinned
just install      # wally install + sourcemap + type injection
```

Live-sync into Studio (two terminals):

```bash
just serve        # Rojo server; connect the Rojo Studio plugin to it
just watch        # keeps sourcemap fresh so luau-lsp autocomplete stays accurate
```

Other recipes:

```bash
just check        # fmt-check + lint + analyze (what CI runs)
just fmt          # format src/
just build        # produce build.rbxlx
just --list       # everything
```

> **Fedora + Vinegar:** Studio runs under Wine but shares the host network stack, so the Rojo
> plugin reaches `localhost:34872` normally. If it can't connect, confirm Studio's HTTP requests
> aren't blocked and that Rojo is bound to loopback.

## Documentation

Read in this order:

1. [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — the loop, retention, and monetization
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — services, scaling, streaming, actors
3. [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) — profile schema and the atomic steal transaction
4. [`docs/NETWORKING.md`](docs/NETWORKING.md) — ByteNet packets and replication strategy
5. [`docs/ANTI_EXPLOIT.md`](docs/ANTI_EXPLOIT.md) — server authority rules
6. [`docs/ECONOMY_AND_MONETIZATION.md`](docs/ECONOMY_AND_MONETIZATION.md) — sinks, faucets, products
7. [`docs/ROADMAP.md`](docs/ROADMAP.md) — build order and milestones

## License

MIT — see [`LICENSE`](LICENSE).
