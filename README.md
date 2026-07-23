# Build A Base And Raid 💥

A high-retention, PvP base-building and loot-stealing game for Roblox, built for **20K+ CCU**.

**Buy** the parts to build a fully destructible base. **Roll** for the gear, abilities, and raid
tools you carry. Grow passive income from your vaults, raid the players sharing your server in real
time (breach their walls, loot their vaults), and trade everything on a global player-run market.
Your base is safe when you log off — but everything you carry drops the moment you die. That risk is
the whole game.

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
    │   ├── ui/              # Vide components (inventory, vault, shop, flea, charts)
    │   └── controllers/     # Net, Input, Build (grid snap), Camera, UI, Effects
    ├── server/              # ServerScriptService — single source of truth
    │   ├── services/        # Data, Roll, Inventory, Vault, Base, Raid, Combat, Rating, Matchmaking, Economy, Flea
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

1. [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — the loop, retention, monetization, and open risks
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — live same-server bases, services, scaling
3. [`docs/BUILDING_AND_RAIDING.md`](docs/BUILDING_AND_RAIDING.md) — full destruction (HP + support graph, no physics)
4. [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) — profile schema, item-UID invariant, transactions
5. [`docs/MATCHMAKING.md`](docs/MATCHMAKING.md) — hidden MMR + reserved-server banding
6. [`docs/FLEA_MARKET.md`](docs/FLEA_MARKET.md) — order-book exchange + anti-fraud
7. [`docs/NETWORKING.md`](docs/NETWORKING.md) — ByteNet packets and replication
8. [`docs/ANTI_EXPLOIT.md`](docs/ANTI_EXPLOIT.md) — server authority rules
9. [`docs/ECONOMY_AND_MONETIZATION.md`](docs/ECONOMY_AND_MONETIZATION.md) — sinks, faucets, products
10. [`docs/ASSET_PIPELINE.md`](docs/ASSET_PIPELINE.md) — sourcing art without in-house modeling
11. [`docs/ROADMAP.md`](docs/ROADMAP.md) — build order and milestones

## License

MIT — see [`LICENSE`](LICENSE).
