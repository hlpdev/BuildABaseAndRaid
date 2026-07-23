# Roadmap

Build order is deliberate: the **loop and the fairness rails ship together**. Shipping the steal loop
before shields/matchmaking/offline-caps exist would torch D7 retention (see Game Design §meta).

## M0 — Foundations ✅ (in progress)

- [x] Rokit toolchain, Rojo project files, Wally deps, StyLua/Selene/luau-lsp, CI
- [x] Repository docs and conventions
- [ ] Service/controller loader (~80 lines, no framework)
- [ ] `src/shared/defs` skeleton: `RarityDefs`, `ItemDefs` (typed), `BuildingDefs`
- [ ] `src/shared/net` ByteNet packet definitions (initial surface)
- [ ] `DataService` + ProfileStore template, load/save, migration harness

## M1 — The loop (vertical slice, single player)

- [ ] Roll at Altar → `RollService` with drop table + pity, server-authoritative
- [ ] Inventory equip/unequip, drop-on-death
- [ ] Vault store/withdraw + income accrual (online)
- [ ] Base placement on snap-grid with placeable cap and presets (<60s to functional)
- [ ] Vide UI for roll / inventory / vault / build
- [ ] Juice pass #1: roll animation, steal SFX, screen shake, particles

## M2 — Raiding + fairness (the two halves must land together)

- [ ] Base snapshot serialization + MemoryStore/DataStore store, banded by net worth
- [ ] `MatchmakingService` serves snapshots; `RaidService` instantiates + simulates defenses
- [ ] Server-authoritative steal channel (position/LoS/timing validation each tick)
- [ ] Idempotent steal transaction (txId, pendingEvents drain on load)
- [ ] **Fairness rails, same milestone:** new-player shield window, daily/purchasable shields,
      offline-loss cap, gap-scaled raid rewards, diminishing vault returns
- [ ] Offline income cap applied on load

## M3 — Retention systems

- [ ] Daily login streak → day-7 guaranteed high-rarity roll
- [ ] Weekly "value stolen" leaderboard (MemoryStore sorted map, Monday reset)
- [ ] Mythic of the Week rotation
- [ ] Tutorial: scripted <90s first-session loop (roll → equip → defend NPC → raid bot → steal)
- [ ] Notifications (robbed-while-away, shield expiring)

## M4 — Monetization

- [ ] EconomyService: receipt validation (idempotent), gem packs
- [ ] Gamepasses: luck multiplier, auto-roll, extra vault slots, faster channel
- [ ] Shields as consumables; VIP/season pass
- [ ] Cosmetics (neon skins, vault themes, trails)
- [ ] Published drop rates in UI matching server tables

## M5 — Scale hardening (toward 20K CCU)

- [ ] Parallel Luau (Actors) for turret targeting + raid pathfinding
- [ ] StreamingEnabled tuning; per-base streaming of instantiated snapshots
- [ ] ByteNet delta replication audit; bandwidth budget per 16-player shard
- [ ] Rate limiting on every intent packet; anomaly telemetry
- [ ] Load/soak testing; DataStore/MemoryStore budget verification
- [ ] `run-in-roblox` integration tests in CI (Open Cloud) — see below

## Testing maturity (deferred item)

Jest covers pure logic in `src/shared` now. Full in-engine integration tests need `run-in-roblox`
driven by an Open Cloud key in CI; that's an M5 item because it requires a place + secret management,
not just code. Until then, keep game math pure and unit-tested off-engine.

## Explicitly deferred / not doing (yet)

- Trading between players (dupe/scam surface; revisit after economy is stable)
- Guilds/alliances (raid-coordination complexity; strong retention lever for later)
- Mobile-specific control scheme polish (validate the loop on PC first, but keep UI touch-friendly)
- Any DI framework (Knit/Flamework) — explicitly rejected for scale reasons
