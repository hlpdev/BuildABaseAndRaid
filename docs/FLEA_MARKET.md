# Flea Market (Order-Book Exchange)

A global, async, player-run market — Steam-market / Tarkov-flea in spirit. Players list items, set
prices, place **buy and sell orders** that auto-match, and read **price-history charts**. No trade
GUI, no direct player-to-player transfer (deliberate face-to-face dropping is the only manual hand-off,
see `docs/GAME_DESIGN.md`).

> **This is the highest-risk system in the game.** A single dupe becomes real-money fraud the moment a
> liquid market exists. It ships **last**, behind a proven-stable core economy — but the item model is
> built to support it from day one.

## The one invariant that keeps the economy alive

**Every item UID exists in exactly one location, ever:**

```
carried inventory  |  vault  |  ground loot  |  flea escrow
```

The server is the **only** authority that moves a UID between locations, and a move is **atomic** —
it leaves one location in the same committed write that puts it in the next. There is never a window
where a UID is in two places or none. Break this once and dupes flood the market. Everything below
exists to protect this invariant.

## Listing = immediate escrow

- Listing an item **moves the UID into flea escrow in the same commit** — it leaves your inventory
  instantly. There is no "list it, then it's still in my bag" window to exploit.
- Cancelling a listing returns the UID from escrow to your inventory (atomic, same rule).
- Escrowed items are **not raidable, not droppable, not carriable** — they're off the board until
  sold or cancelled.

## Orders & matching

- **Sell order:** UID + ask price → escrow. **Buy order:** item-type + max price + coins reserved
  (coins move to escrow too, so you can't place buy orders you can't fund).
- The server **matches** compatible buy/sell orders (price-time priority). On a match, atomically:
  UID escrow → buyer; coin escrow → seller (minus tax). One transaction, one `txId`, idempotent.
- **Market vs. limit:** "buy now" fills against the best resting sell; "place order" rests until
  matched or cancelled/expired (TTL).

## Prices, charts, discovery

- Prices are **player-set**; the server records every fill into a **price-history series** per item
  type (backed by MemoryStore/DataStore, sharded) for candles/sparklines.
- Discovery: search + sort/filter by type, rarity, price, recency. Show best bid / best ask / last /
  volume per item type.

## Anti-fraud / anti-manipulation (the reason it ships last)

- **Dupe defense:** the single-location UID invariant + full transaction ledger. Every move is logged
  with `txId`, actor, from→to. Anomaly detection flags impossible transitions.
- **Idempotency:** every fill/cancel carries a `txId`; replays are no-ops (crash-safe like all
  economy transactions — see `docs/DATA_MODEL.md`).
- **Manipulation defense:** per-account listing/trade **velocity limits**, a **listing tax + sale
  tax** (also a healthy coin *sink*), and detection of **wash trading** (same-cluster accounts
  round-tripping to fake volume/price).
- **RMT defense:** taxes and velocity caps make cross-account value transfer costly and visible; log
  everything for moderation. Currency itself can be dropped on the ground (a laundering vector) — cap
  drop sizes and log large transfers.
- **Session-lock safety:** flea writes touch the profile under ProfileStore session lock; escrow
  state lives on the profile so a crash can't strand an item outside the invariant.

## Why escrow-on-list, not escrow-on-sale

If items stayed in the seller's inventory until sale, they could be **raided, dropped, or re-listed**
while also listed — every one of those is a dupe or a "sold something I no longer have" bug.
Escrow-on-list makes the listed item genuinely gone from play, which is the only safe model.

## Rollout

1. Item-UID instance model + single-location invariant + transaction ledger (built in the core, M-early).
2. Read-only market data (browse, charts) on top of a small seeded/NPC liquidity base.
3. Sell orders + buy-now.
4. Buy orders + auto-matching + full charts.
5. Anti-manipulation tuning under real volume.
