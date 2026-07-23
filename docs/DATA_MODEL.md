# Data Model

Persistence is **session-locked ProfileStore**. Item duplication is the existential bug — it corrupts
PvP *and* becomes real-money fraud once the flea market is live. The data model is built around one
invariant and one transaction pattern that protect against it.

## The item-instance invariant

Every rollable item is a **server-minted global UID instance** from creation. A UID lives in **exactly
one location, ever**:

```
carried inventory  |  vault  |  ground loot  |  flea escrow
```

Only the server moves a UID, and every move is **atomic** (leaves one location in the same commit
that enters the next). No UID is ever in two places or none. See `docs/FLEA_MARKET.md`.

## Profile template (shape, not final)

```
Profile.Data = {
    version = 1,                         -- migration marker

    currency = { coins = 0, gems = 0 },  -- coins NOT lost on death; deliberate-drop only

    inventory = {                        -- CARRIED items (drop on death)
        -- [uid] = { def, tier?, rolledAt, seed }
    },

    vault = {                            -- STORED items (income + raidable-only-when-breached)
        -- [uid] = { def, tier?, storedAt }
    },

    fleaEscrow = {                       -- items + coins locked in listings/orders
        listings = { --[[ { txId, uid, ask, listedAt, ttl } ]] },
        buyOrders = { --[[ { txId, defType, maxPrice, coinsReserved, at, ttl } ]] },
    },

    base = {                             -- layout; rebuilt on join (see BUILDING_AND_RAIDING.md)
        plotId,
        placed = { --[[ { uid, kind, tier, gridPos, rot, level } ]] },  -- HP resets to max on load
    },

    economy = {
        incomeAccruedAt,                 -- offline-income cap math
        lifetimeRaidedValue = 0,
        lifetimeTradedValue = 0,
    },

    rating = {
        mmr = <hidden>,                  -- server-only; never sent to clients
        netWorthCache,                   -- recomputed periodically
        level = 1,                       -- friendly derived value shown to players
    },

    progression = {
        loginStreak = 0, lastLoginDay = 0,
        protectionUntil = 0,             -- new-player window
        shieldUntil = 0,                 -- raid-immunity (marks base un-matchmadable)
        pity = { epic = 0, legendary = 0, mythic = 0 },
    },

    pendingEvents = {},                  -- durable inbox applied on load (flea fills, etc.)
    seenTxIds = {},                      -- idempotency ledger (bounded/rotated)
}
```

`uid` and `txId` are **server-minted**; a client-supplied id is rejected. `def` references
`src/shared/defs`; items store a *reference + roll metadata*, never their stats. Stats are always read
from def tables so rebalancing is a one-file change and untamperable.

## Transactions (idempotent, crash-safe)

Every value-moving action — a **flea fill**, a **raid steal**, a **roll payout** — is an ordered,
idempotent transaction with a unique `txId`:

- Applying the same `txId` twice is a **no-op** (dedup via `seenTxIds`).
- Each side of a two-party move is **separately durable**; neither assumes the other landed in the
  same tick.
- Cross-account effects that can't complete in one write (e.g. a flea fill crediting an offline
  seller) enqueue into the counterparty's **`pendingEvents`**, drained on their next load, skipping
  any `txId` already seen.

### Ordering principle
Prefer orderings whose worst-case failure is a **delayed credit**, never a **destroyed item**.
Players forgive "my coins updated late"; they quit over "my item vanished." Escrow-on-list (flea) and
credit-before-debit (raid) both follow this rule.

## Raiding & death

- **Carried inventory drops on death** → ground loot (each UID moves inventory → ground atomically).
- **Currency never drops on death.** It can be **deliberately** dropped (piles) as a manual,
  trust-based transfer.
- **Vault items** are safe until a raider breaches the base and channel-extracts them (UID moves
  victim-vault → raider-inventory under a `txId`). Because raiding is **online-only, same-server**,
  the victim is present — no offline snapshot debit needed.

## Passive income

`income = min(cap, ratePerSec * (now - incomeAccruedAt))`, applied on load/collect, then
`incomeAccruedAt = now`. `ratePerSec` = Σ(vault tier × stored item value) × boosts/gamepasses, subject
to a **diminishing-returns soft cap** (anti-hoard) and a **~few-hour offline cap** (return incentive).
Never computed client-side.

## Base persistence

The base is stored as a compact `placed` list. **HP/damage do not persist** — offline bases aren't
raidable, so they always rebuild at full HP. `BaseService` reconstructs the base on join and registers
it into the server's live world + support graph.

## Migrations

`version` gates a migration chain run at load before gameplay sees the data. Each schema change adds a
forward migration and a Jest test upgrading a fixture of the previous version. Never mutate old fields
in place without a version bump.
