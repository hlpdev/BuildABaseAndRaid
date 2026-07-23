# Data Model

Persistence is **session-locked ProfileStore**. Item duplication is the existential bug for this
genre; the session lock is non-negotiable, and the steal is designed as an idempotent transaction.

## Profile template (shape, not final)

```
Profile.Data = {
    version = 1,                    -- migration marker; bump + migrate on schema change

    currency = { coins = 0, gems = 0 },

    inventory = {                   -- CARRIED items (droppable on death)
        -- [uid] = { def = "chain_lightning", rolledAt = <serverTime>, seed = <n> }
    },

    vault = {                       -- STORED items (income + stealable)
        capacity = 12,
        stealTimeMult = 1.0,
        items = {
            -- [uid] = { def = "phase_dash", storedAt = <serverTime> }
        },
    },

    base = {                        -- layout; capped placeables (~50)
        preset = "starter",
        placeables = { --[[ { kind, gridPos, rot, level } ]] },
    },

    economy = {
        incomeAccruedAt = <serverTime>,   -- for offline-income cap math
        lifetimeStolenValue = 0,          -- weekly leaderboard feeds off deltas
    },

    progression = {
        loginStreak = 0,
        lastLoginDay = 0,                 -- UTC day index
        shieldUntil = 0,                  -- raid-immunity expiry (serverTime)
        pity = { epic = 0, legendary = 0, mythic = 0 },
    },

    -- Inbox of effects that happened to this player while their profile was unloaded.
    pendingEvents = {
        -- { txId, kind = "steal_debit", uid, def, byUserId, at }
    },

    seenTxIds = {},                 -- idempotency ledger (bounded/rotated)
}
```

`uid` is a server-generated unique id per item instance (never client-supplied). `def` references
`src/shared/defs/ItemDefs` — items store a *reference + roll metadata*, never their stats. Stats are
always read from the def table, so rebalancing is a one-file change and can't be tampered with.

## The steal transaction

A steal moves an item from a **victim snapshot** to a **live raider profile**. The victim may be
offline, and either write can fail independently. Design for a server dying between the two writes.

**Invariants**
- An item exists in **exactly one** of {a live inventory, a live vault, in-flight}. Never zero, never
  two.
- Every steal has a unique `txId`. Applying the same `txId` twice is a **no-op** (idempotent).
- The victim debit and the raider credit are **separately durable**; neither assumes the other landed
  in the same tick.

**Ordered flow**
1. Raider completes the channel at the exit zone (server-validated). Server mints `txId`.
2. **Reserve → remove from raider's *pending* view** of the snapshot (in-memory) so it can't be
   double-stolen this session.
3. **Credit the raider:** add item to raider profile inventory (or vault), record `txId` in
   `seenTxIds`, commit. *This is the durable point of no return for the raider.*
4. **Debit the victim:** enqueue `{ txId, kind="steal_debit", uid }` into the victim's
   `pendingEvents` via the matchmaking/store path.
   - Victim **online** → apply immediately, dedup on `txId`, commit.
   - Victim **offline** → applied on next profile load; the load handler drains `pendingEvents`,
     skipping any `txId` already in `seenTxIds`.

**Failure cases**
- Crash after step 3, before step 4 → raider keeps the item; victim debit replays from a durable
  queue (MemoryStore/DataStore-backed) on recovery. No dupe, because the item is already gone from
  the raider-facing snapshot and the victim copy is authoritative-frozen.
- Crash during step 3 → ProfileStore session lock means the partial write is resolved on reload; the
  `txId` gate prevents re-credit.

> **Ordering choice:** credit-then-debit (raider first) is deliberate. If we debited the victim first
> and crashed, the item could vanish entirely (bad, but recoverable via queue). Crediting first means
> the worst case is a *delayed debit*, never a *destroyed item* — players tolerate "my coins updated
> late" far better than "my item disappeared." The durable pending-event queue closes the gap either
> way.

## Offline vault income

`income = min(cap, ratePerSec * (now - incomeAccruedAt))`, `cap ≈ 4h * ratePerSec`. Applied on load,
then `incomeAccruedAt = now`. Rate is the **sum of vaulted items' income**, subject to the
diminishing-returns soft cap from the economy doc — never read client-side.

## Snapshots (raid targets)

A base snapshot is a **frozen, read-only copy** of `{ base.placeables, vault.items (value only) }`
plus a net-worth band key. Snapshots are written on meaningful change (throttled) to a store keyed by
band, and served by `MatchmakingService`. Raiding mutates the *snapshot's* transient copy and emits a
`steal_debit` against the real profile — it never edits the victim's live profile directly.

Snapshot must exclude anything exploitable if leaked (no seeds, no raw pity counters) — treat it as
client-adjacent data.

## Migrations

`version` gates a migration chain run at load, before gameplay sees the data. Every schema change
adds a forward migration and a Jest test that upgrades a fixture of the previous version. Never mutate
old fields in place without a version bump.
