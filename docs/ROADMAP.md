# Roadmap

Sequencing principle: the **core loop and its fairness rails ship together**, the **item-UID
foundation is laid early** (so the flea can be built safely later), and the **highest-risk system (the
flea market) ships last** behind a proven-stable economy.

## M0 — Foundations ✅ (in progress)

- [x] Rokit toolchain, Rojo project files, Wally deps, StyLua/Selene/luau-lsp, CI
- [x] Design docs coherent with the locked vision
- [ ] Service/controller loader (~80 lines, no framework)
- [ ] `src/shared/defs` skeleton: `RarityDefs`, `ItemDefs` (typed), `BuildingDefs` (tiers/HP/damage)
- [ ] `src/shared/net` ByteNet packet definitions (initial surface)
- [ ] `DataService` + ProfileStore template; **item-UID instance model + single-location invariant**
      + transaction/`txId` ledger (laid now, used everywhere later)

## M1 — Core loop, single-server vertical slice

- [ ] `RollService`: rolls, drop tables, pity, published rates
- [ ] `InventoryService`: equip/unequip, **drop-on-death** ground loot, deliberate Delete-drop
- [ ] `BaseService`: buy parts, **grid-snap placement**, part cap, serialize/rebuild base, **support
      graph**
- [ ] `VaultService`: store/withdraw, income accrual (online)
- [ ] Vide UI: roll, inventory, vault, part shop, build mode
- [ ] Juice pass #1: destruction bursts, roll animation, hit feedback, sound

## M2 — Raiding + fairness (must land together)

- [ ] `RaidService`: raid-tool typed damage vs. tier, breach, **server-timed vault extraction**,
      position/LoS validation each tick
- [ ] Full-destruction tuning: tool-vs-tier tables, support-collapse chains, batched replication
- [ ] `CombatService`: PvP damage, abilities, death → full drop
- [ ] `RatingService`: hidden MMR + net worth; friendly level
- [ ] `MatchmakingService`: MemoryStore queue + reserved servers, **MMR banding**
- [ ] **Fairness rails, same milestone:** hub safezone, new-player protection window, shields
      (un-matchmadable), gap-scaled raid rewards, diminishing vault returns
- [ ] Offline income cap on load; base safe offline

## M3 — Retention systems

- [ ] Daily login streak → day-7 guaranteed high-rarity roll
- [ ] Weekly leaderboards (value raided / traded) — MemoryStore, Monday reset
- [ ] Rotating limited items (FOMO)
- [ ] Tutorial: scripted <90s first session (roll → equip → build → defend → breach bot → loot)
- [ ] Notifications (under-attack, shield expiring); defensive **bot bases** as population backstop

## M4 — Monetization

- [ ] `EconomyService`: receipt validation (idempotent), gem packs
- [ ] Gamepasses: luck, auto-roll, extra vault slots, income boost, plot/cap (fairness-capped)
- [ ] Shields (consumable), VIP/season pass, cosmetics/skins
- [ ] Published drop rates in UI matching server tables
- [ ] **Content-maturity questionnaire → Mild 9+ rating** before public launch

## M5 — Flea market (highest risk, ships last)

- [ ] Read-only market data + price charts over seeded liquidity
- [ ] Sell orders + buy-now (escrow-on-list, atomic settlement, `txId`)
- [ ] Buy orders + auto-matching + full charts
- [ ] Anti-manipulation: velocity limits, taxes (sink), wash-trade detection, full ledger + telemetry

## M6 — Scale hardening (toward 10K+ CCU)

- [ ] Parallel Luau (Actors) for turret targeting + raid pathfinding
- [ ] StreamingEnabled tuning; per-base streaming of live bases
- [ ] ByteNet delta audit; bandwidth budget per 16-player shard
- [ ] Rate limiting on every intent; anomaly telemetry dashboards
- [ ] Load/soak testing; MemoryStore/DataStore (per-experience) budget verification
- [ ] `run-in-roblox` integration tests in CI (Open Cloud)

## Testing maturity (deferred)

Jest covers pure logic now (drop tables, income, damage-vs-tier, support graph, order matching). Full
in-engine integration tests need `run-in-roblox` + an Open Cloud key in CI — an M6 item (needs a place
+ secret management). Keep game math pure and unit-tested off-engine until then.

## Explicitly deferred / not doing (yet)

- Guilds/alliances (raid-coordination complexity; strong later retention lever)
- Cross-server live raiding / snapshots (rejected — raids are online-only same-server by design)
- Any DI framework (Knit/Flamework) — rejected for scale reasons
- Real-money-adjacent trading features beyond the in-game flea

## Art dependencies

Several milestones gate on commissioned assets — see `docs/ASSET_PIPELINE.md`. The modular building
kit (M1) and hero weapons/raid tools (M2) are the two paid critical-path items; everything else is
code/VFX/UI/default-avatar and unblocked.
