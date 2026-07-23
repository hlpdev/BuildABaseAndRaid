# Networking

All gameplay traffic goes through **ByteNet** packets defined once in `src/shared/net`. Buffer
serialization is a 5–10× bandwidth reduction over table RemoteEvents on the vault/raid/transfer
traffic that dominates this game — it is the CCU-critical dependency, not an optimization to add
later.

## Rules

1. **No raw RemoteEvents/RemoteFunctions for gameplay.** Define a ByteNet packet with an explicit
   type. The only exceptions are Roblox-required callbacks (e.g. `MarketplaceService` receipts).
2. **Client sends intents, server sends state.** Packet names read as `RequestRoll`, `RequestEquip`,
   `RequestChannelSteal` (client→server) and `VaultUpdated`, `RaidState`, `RollResult`
   (server→client). There is no `StealCompleted` from the client — completion is server-decided.
3. **Never trust a client payload as truth.** A `RequestChannelSteal` says *"I intend to channel"* —
   the server validates position, LoS, and timing each tick and decides the outcome.
4. **Replicate deltas, not snapshots, on the hot path.** Vault changes send the changed slot, not the
   whole vault. Full-state sync happens once on join and on resync request.
5. **Rate-limit every client→server packet** server-side (token bucket per player per packet). A
   flood of `RequestRoll` must not cost a DataStore call or an RNG roll beyond the cooldown gate.

## Packet surface (initial)

Client → Server (intents):
- `RequestRoll` — `{}` (cooldown + pity enforced server-side)
- `RequestEquip` / `RequestUnequip` — `{ uid }`
- `RequestVaultStore` / `RequestVaultWithdraw` — `{ uid }`
- `RequestPlace` / `RequestRemove` — `{ kind, gridPos, rot }`
- `RequestStartRaid` — `{}` (server matchmakes a snapshot)
- `RequestChannelSteal` — `{ vaultSlotId }` (hold state; server times the channel)
- `RequestUseAbility` — `{ uid, targetHint }`

Server → Client (state / events):
- `InitialState` — full profile-derived state on join
- `RollResult` — `{ uid, def, rarity, seed }`
- `InventoryDelta` / `VaultDelta` — changed slots only
- `RaidState` — snapshot base + channel progress + defense events
- `Notify` — steal-against-you, shield-expiring, leaderboard nudge
- `CurrencyDelta` — `{ coins, gems }`

Keep the surface small; every packet is attack surface and bandwidth.

## Mapping to Vide

`NetController` is the **single** subscriber to server→client packets. It writes incoming data into
Vide **sources**; UI components read those sources reactively and never touch ByteNet directly. This
keeps one replication entry point and makes the client trivially state-driven.

## Sizing discipline

- Prefer `u8`/`u16` and enum indices over strings on the wire. Item defs are referenced by a
  **stable numeric id** in `ItemDefs`, not by name string, in hot packets.
- Batch per-frame deltas; don't emit a packet per slot per frame.
- Budget: assume worst-case 16 players all raiding/rolling. Measure with the ByteNet
  debugger before scaling content.
