# Matchmaking & MMR

Full-loot PvP for a 9+ audience is only fair if players face similar opponents. A hidden rating bands
players into skill-appropriate servers.

## MMR (hidden rating)

- A single server-owned number per player combining **skill signals** (raid success/failure, PvP
  K/D, survival) and **net worth** (base value + vault value + liquid coins). Net worth matters
  because a rich turtle is a fat target regardless of aim.
- **Hidden from players.** The UI shows a friendly *level* (derived, monotonic-ish) so progression
  feels good, but the raw MMR is never exposed — exposing it invites gaming and demoralization.
- Updated server-side after meaningful events; stored on the profile; **read-only to clients**.
- **Cold start:** new accounts seed low with a wide protection window and are matched into
  low-band/newbie servers first.

## Matchmaking architecture

Standard, proven Roblox pattern — **MemoryStore queue + reserved servers via `TeleportService`**:

1. Players land in a **lightweight hub/lobby place** (also the safezone).
2. Client requests a match; server enqueues `{ userId, mmr, partyId? }` into a **MemoryStore sorted
   map** keyed by MMR band.
3. A **matchmaker loop** (run on a designated server or the lobby) pops nearby-MMR players, reserves a
   server code (`TeleportService:ReserveServer`), stores the code in a short-lived MemoryStore entry,
   and teleports the group with `TeleportToPrivateServer`.
4. Late-fillers for an existing match reuse the stored access code — **handle the ~30s reserved-server
   grace window expiring** (a stale code errors on teleport; fall back to a fresh reservation).

### 2026 platform notes (verified)
- DataStore limits are now **per-experience**, not per-server — friendlier to cross-server
  matchmaking bookkeeping.
- MemoryStore is a *maybe-30-day, definitely-shorter-under-pressure* cache; treat queue/code entries
  as ephemeral with TTLs, use **exponential backoff** on `DataUpdateConflict`, and **shard** hot maps.
- Re-evaluate Roblox's first-party matchmaking features as they mature; the custom
  MemoryStore+reserved-server approach is the reliable baseline today.

## Banding policy

- Bands are **MMR ranges with upward overlap** — you can be matched slightly above your band (more
  risk, bigger reward) but never far below (no farming minnows).
- **Party handling:** a party matches at the **max MMR** of its members (prevents a shark
  smurf-carrying into low bands).
- Low population / off-hours: widen bands gradually and backfill with **defensive bot bases** so a
  server is never empty of raid targets — bots are the population backstop, not the main content.

## Fairness backstops (secondary to banding)

- **Hub is a hard safezone** (no damage, no theft).
- **New-player protection window** (time- or progress-boxed): reduced raidability + can't be targeted
  by much-higher-MMR players.
- **Shields** (daily + purchasable) mark a base un-raidable and therefore **not matchmade as a
  target** — no permanent-fortress accounts.

## Anti-exploit

- MMR and net worth are computed and written **server-side only**; never accept a client-reported
  rating or worth.
- Validate teleport tickets/reservations server-side; don't let a client pick its own destination
  server or band.
