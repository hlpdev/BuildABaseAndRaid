# Networking

All gameplay traffic goes through **ByteNet** packets defined once in `src/shared/net`. Buffer
serialization is a 5–10× bandwidth reduction over table RemoteEvents on the placement/destruction/raid
traffic that dominates this game — it is the CCU-critical dependency, not a later optimization.

## Rules

1. **No raw RemoteEvents/RemoteFunctions for gameplay.** Define a typed ByteNet packet. Only
   Roblox-required callbacks (e.g. `MarketplaceService` receipts) are exempt.
2. **Client sends intents, server sends state.** Names read as `RequestPlacePart`,
   `RequestUseRaidTool`, `RequestRoll` (client→server) and `PartPlaced`, `PartsDestroyed`,
   `VaultUpdated` (server→client). There is no client-declared outcome.
3. **Never trust a client payload as truth.** `RequestUseRaidTool` means *"I intend to hit that
   part"* — the server validates ownership, cooldown, position, LoS, and applies damage.
4. **Deltas on the hot path.** Destruction sends **removed UIDs** (batched, incl. support-collapse
   chains), placement sends the one new part. Full base state syncs once when a base streams in.
5. **Rate-limit every client→server packet** server-side (token bucket per player per packet). No
   hot-path packet may trigger a DataStore write directly.

## Packet surface (initial)

Client → Server (intents):
- `RequestRoll` — `{}` (cooldown/pity enforced server-side)
- `RequestEquip` / `RequestUnequip` — `{ uid }`
- `RequestDrop` — `{ uid | coinAmount }` (deliberate ground drop)
- `RequestVaultStore` / `RequestVaultWithdraw` — `{ uid }`
- `RequestBuyPart` — `{ kind, tier }` (coin sink; server validates funds)
- `RequestPlacePart` / `RequestRemovePart` — `{ kind, tier, gridPos, rot }` (server snaps + validates)
- `RequestUseRaidTool` — `{ toolUid, targetPartUid }` (hold/tick state; server times + validates)
- `RequestExtractVault` — `{ targetPartUid }` (server-timed channel)
- `RequestUseAbility` — `{ uid, targetHint }`
- `RequestQueueMatch` / `RequestLeaveQueue` — `{ }` (hub only)
- Flea (later): `RequestListItem`, `RequestBuyNow`, `RequestPlaceOrder`, `RequestCancel`

Server → Client (state / events):
- `InitialState` — full profile-derived state on join
- `BaseSync` — full base part list when a base streams in
- `PartPlaced` / `PartsDestroyed` — deltas (destruction batches removed UIDs + one VFX cue)
- `RollResult` — `{ uid, def, rarity, tier?, seed }`
- `InventoryDelta` / `VaultDelta` / `GroundLootDelta` — changed slots only
- `RaidState` — active raid: tool cooldowns, breach/extract progress, defense events
- `CurrencyDelta` — `{ coins, gems }`
- `LevelUpdate` — friendly derived level (never raw MMR)
- `Notify` — under-attack, shield expiring, order filled
- Flea (later): `MarketData`, `PriceSeries`, `OrderUpdate`

Keep the surface small — every packet is attack surface and bandwidth.

## Mapping to Vide

`NetController` is the **single** subscriber to server→client packets; it writes into Vide **sources**
that components read reactively. One replication entry point, trivially state-driven UI.

## Sizing discipline

- Prefer `u8`/`u16` and enum indices over strings. Item/part defs are referenced by a **stable numeric
  id**, not a name string, in hot packets. Grid positions pack into small ints.
- Batch per-frame deltas; never a packet-per-part-per-frame. A raid collapsing 30 parts is one
  message.
- Budget for worst case: 16 players all building/raiding. Measure with the ByteNet debugger before
  scaling content.
