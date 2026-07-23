# Architecture

## Principles

- **Server-authoritative.** Clients render replicated state and send intents. See
  `docs/ANTI_EXPLOIT.md`.
- **Shared is pure.** `src/shared` has no side effects and no singletons; both realms require it.
- **Data flows one way.** Server mutates authoritative state → replicates via ByteNet → clients
  derive UI through Vide sources. Clients never mutate authoritative state directly.

## The server model: live bases, per-account economy

**Bases are live and same-server.** When a player joins a match server, `BaseService` rebuilds their
base (from the profile's `placed` list) into the shared world. All 12–16 players' bases coexist and
are raidable in real time — **but only while their owner is present**. Log off → base is removed from
the world and is safe.

**The economy is per-account, cross-server.** Profiles are the source of truth; the **flea market**
and **matchmaking** are the cross-server layers (MemoryStore + DataStore). There is no async snapshot
raiding — raids are always live vs. an online owner.

```
Hub / lobby place  ──(MMR match, MemoryStore queue)──▶  Reserved match servers (12–16, MMR-banded)
        │                                                        │
        └────────────── profiles (ProfileStore) ────────────────┘
                     flea market + leaderboards (MemoryStore/DataStore)
```

## Realms and boundaries

```
ReplicatedStorage/Shared      ← pure defs (Item/Rarity/Building), math, net schemas (both realms)
ReplicatedStorage/Packages    ← Wally shared deps (Vide, ByteNet, Trove, Sift, Promise)
ServerScriptService/Server    ← authoritative services + data access
ServerScriptService/ServerPackages ← ProfileStore, Signal (never replicated)
StarterPlayerScripts/Client   ← controllers + Vide UI (renders replicated state only)
ReplicatedFirst/Boot          ← anti-flash loading UI before the client boots
```

## Server services

Single-responsibility modules with an explicit lifecycle (`init` then `start`), loaded by a small
hand-rolled loader (~80 lines). **No Knit / no DI framework.**

| Service            | Owns |
| ------------------ | ---- |
| `DataService`      | ProfileStore sessions; the only module that touches persistence |
| `RollService`      | Roll RNG, drop tables, pity/luck, server-authoritative |
| `InventoryService` | Carried items, equip, drop-on-death, ground loot |
| `VaultService`     | Vault contents, capacity, income accrual (online + offline cap) |
| `BaseService`      | Rebuild/serialize bases, placement validation, part cap, **support graph** |
| `RaidService`      | Raid tool damage application, breach/extract, position/LoS validation |
| `CombatService`    | Server-side PvP damage, ability resolution, death handling |
| `MatchmakingService` (hub) | MMR queue, reserved-server allocation, banding |
| `RatingService`    | MMR + net-worth computation (hidden), friendly-level derivation |
| `EconomyService`   | Coin sinks/faucets, purchase/receipt validation, income |
| `FleaService`      | Order book, escrow, matching, price history (later milestone) |

Services talk to each other in-process via `Signal` (no serialization). They talk to clients only via
ByteNet packets defined in `src/shared/net`.

## Client controllers

| Controller         | Owns |
| ------------------ | ---- |
| `NetController`    | Single subscriber to server→client packets → Vide sources |
| `InputController`  | Intents: roll, equip, place/remove part, raid-tool use, drop (Delete) |
| `BuildController`  | Grid-snap placement preview, rotation, validity ghosting (client preview only) |
| `CameraController` | Build / raid / combat camera modes |
| `UIController`     | Mounts Vide app, routes screens (inventory, vault, shop, flea, market charts) |
| `EffectsController`| Juice: destruction bursts, hitstop, shake, sound |

Replicated state lives in Vide **sources** owned by `NetController`; components read them reactively
and never fetch authoritative state imperatively.

## Scaling to 10K+ CCU

- **Server size 12–16**, MMR-banded reserved servers (`docs/MATCHMAKING.md`).
- **Instance budget is the real limit.** Hard per-base part cap; `StreamingEnabled` with per-base
  streaming so a client loads only nearby bases. Never hold all bases loaded per client.
- **Destruction is deterministic** (HP + support graph, no physics) — see
  `docs/BUILDING_AND_RAIDING.md`.
- **Bandwidth** — all gameplay replication is ByteNet buffers with delta updates
  (`docs/NETWORKING.md`).
- **Parallel Luau (Actors)** for turret targeting + raid pathfinding; authoritative writes stay
  serial.
- **Cross-server data** — MemoryStore sorted maps for matchmaking queue, leaderboards, flea price
  series; DataStore (per-experience limits, 2026) for profiles via ProfileStore. Exponential backoff
  on conflicts; shard hot maps.

## Boot sequence

1. `ReplicatedFirst/Boot` shows a loading screen immediately (`CharacterAutoLoads` off).
2. Hub: player queues; `MatchmakingService` bands and teleports to a reserved match server.
3. Match server: `DataService` loads the profile (session lock); `BaseService` rebuilds the base into
   the world; `RatingService` refreshes net worth.
4. Server replicates initial state via ByteNet; client `NetController` populates Vide sources.
5. Client mounts UI, spawns character (in safezone), tutorial for new accounts.

## Testing

Pure logic in `src/shared` (drop tables, income math, damage-vs-tier tables, support-graph algorithm,
economy curves, order-matching) is unit-tested with Jest — keep it side-effect-free. Roblox-touching
code is exercised in Studio / via `run-in-roblox` (deferred, see `docs/ROADMAP.md`).
