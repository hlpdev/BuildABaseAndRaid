# Architecture

## Principles

- **Server-authoritative.** Clients render replicated state and send intents. See
  `docs/ANTI_EXPLOIT.md`.
- **Shared is pure.** `src/shared` has no side effects and no singletons; both realms require it.
- **Data flows one way.** Server mutates authoritative state → replicates via ByteNet → clients
  derive UI through Vide sources. Clients never mutate authoritative state directly.

## Realms and boundaries

```
ReplicatedStorage/Shared      ← pure defs, math, net packet schemas (both realms)
ReplicatedStorage/Packages    ← Wally shared deps (Vide, ByteNet, Trove, Sift, Promise)
ServerScriptService/Server    ← authoritative services + data access
ServerScriptService/ServerPackages ← ProfileStore, Signal (never replicated)
StarterPlayerScripts/Client   ← controllers + Vide UI (renders replicated state only)
ReplicatedFirst/Boot          ← anti-flash loading UI before the client boots
```

## Server services

Single-responsibility modules with an explicit lifecycle (`init` then `start`), loaded by a small
hand-rolled loader (~80 lines). **No Knit / no DI framework** — it's unmaintained and its networking
model is exactly what we don't want at scale.

| Service           | Owns |
| ----------------- | ---- |
| `DataService`     | ProfileStore sessions; the only module that touches persistence |
| `RollService`     | Roll RNG, drop tables, cooldowns, pity/luck modifiers |
| `InventoryService`| Carried items, equip/unequip, drop-on-death |
| `VaultService`    | Vault contents, capacity, income accrual (online + offline cap) |
| `RaidService`     | Steal channel timing, position validation, exit-zone banking, the steal transaction |
| `BaseService`     | Base layout, placeable budget, defense simulation (turrets/traps) |
| `MatchmakingService` | Builds/serves **base snapshots**, bands targets by net worth |
| `EconomyService`  | Currency sinks/faucets, purchase fulfillment, receipt validation |
| `CombatService`   | Server-side damage, ability resolution, death handling |

Services talk to each other in-process via `Signal` (no serialization). They talk to clients only via
ByteNet packets defined in `src/shared/net`.

## Client controllers

| Controller        | Owns |
| ----------------- | ---- |
| `NetController`   | Wraps ByteNet listeners → Vide sources (single replication entry point) |
| `InputController` | Intent capture (roll, equip, build, channel-steal hold) |
| `CameraController`| Raid/build camera modes |
| `UIController`    | Mounts Vide app, routes screens |
| `EffectsController`| Juice: shake, hitstop, particles, sound (see design doc §6) |

UI is Vide components under `src/client/ui`. Replicated state lives in Vide **sources** owned by
`NetController`; components read them reactively. Never fetch authoritative state imperatively in a
component.

## The economy is per-account, not per-server

**A 12–16 player shard is not the economy.** The economy is each player's **profile**, and raid
targets are **matchmade snapshots**, not live foreign servers. This is the single most important
architectural fact and it shapes the data model:

- Your base layout + vault contents are periodically serialized into a **snapshot** and written to a
  store keyed by net-worth band.
- When you raid, `MatchmakingService` hands you a snapshot to instantiate locally on the server as an
  async copy. You fight its (simulated) defenses and steal from its (frozen) vault.
- A successful steal enqueues a **pending debit** against the victim's real profile, applied on their
  next session load (or immediately if they're online). See `docs/DATA_MODEL.md`.

This resolves offline-fun, low-population hours, matchmaking fairness, and dupe-safety in one model.

## Scaling to 20K+ CCU

- **Server size 12–16.** Personal raids; small live population per shard.
- **Instance budget is the real limit.** Cap placeables per base (~50). Use `StreamingEnabled` and
  stream distant/instantiated snapshot bases out aggressively. Never hold every base loaded per
  client.
- **Bandwidth is the second limit.** All gameplay replication is ByteNet buffers, not table
  RemoteEvents (5–10× reduction on the vault/raid/transfer traffic). See `docs/NETWORKING.md`.
- **Parallel Luau (Actors).** Turret targeting and raid pathfinding run hot across many bases; move
  them into Actors with `task.desynchronize()` for per-frame work. Keep authoritative mutation on the
  serial thread.
- **Cross-server data.** `MemoryStoreService` sorted maps for the weekly leaderboard and the
  matchmaking queue — DataStores are too slow and rate-limited for that. Profiles stay in
  DataStore via ProfileStore.
- **DataStore budgets** are per-key/per-server. The steal touches two profiles; make it idempotent
  with a transaction ID and never assume both writes land in one tick.

## Boot sequence

1. `ReplicatedFirst/Boot` shows a loading screen immediately (anti-flash; `CharacterAutoLoads` is
   off).
2. Server `DataService` loads the profile (session lock) before spawning the character.
3. Server replicates initial state via ByteNet; client `NetController` populates Vide sources.
4. Client mounts UI, requests character spawn, tutorial begins for new accounts.

## Testing

Pure logic in `src/shared` (drop tables, income math, economy curves, snapshot serialization) is unit
-tested with Jest. Anything touching Roblox services is exercised in Studio / via `run-in-roblox`
(deferred — see `docs/ROADMAP.md`). Keep game math pure so it's testable off-engine.
