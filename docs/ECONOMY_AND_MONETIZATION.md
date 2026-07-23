# Economy & Monetization

Design goal: a self-correcting economy that stays fun for a new player on day 30 while monetizing
**edge and time**, not the core verb. Two currencies:

- **Coins** — soft currency. Earned via vault income and successful raids. Sunk into base upgrades,
  vault capacity, and roll-cooldown reductions.
- **Gems** — hard currency. Bought or earned sparsely. Sunk into luck multipliers, cosmetics, extra
  vault slots, and shields.

## Faucets (coin sources)

- Vault income (per-second, offline-capped ~4h).
- Successful raids (scaled by the net-worth *gap* — see below).
- Daily login rewards; day-7 guaranteed high-rarity roll.
- Quests / tutorial completion (one-time).

## Sinks (where coins die)

- Base defenses and upgrades (walls, turrets, traps, levels).
- Vault capacity + steal-time multiplier upgrades.
- Roll-cooldown reductions.
- Repair after raids (soft sink that scales with base value).

A healthy economy keeps total sinks ≥ faucets for engaged players. Instrument the coin
faucet/sink ratio per net-worth band from day one; inflation is the silent economy killer.

## The anti-runaway rules (critical — see Game Design §3)

1. **Raid rewards scale with the gap.** Raiding *up* (richer target) pays well; raiding *down* pays
   little. This funds newcomers and taxes the top.
2. **Vault income has diminishing returns past a soft cap.** Hoarding stops being linearly better, so
   the rich can't out-accrue everyone permanently.
3. **Matchmaking bands by net worth**, but bands overlap upward so ambitious players can punch up for
   a bigger score at higher risk.
4. **Bigger hoards are bigger targets, not safer ones** — steal difficulty scales with rarity, but
   total exposure scales with total stored value.

## Monetization (sell edge + time, never the verb)

The free roll stays frequent to keep the loop alive. Paid products accelerate and enhance:

| Product | Type | Sells |
| ------- | ---- | ----- |
| Luck Multiplier | Gamepass / timed | Better roll odds (edge) |
| Auto-Roll | Gamepass | Rolls while away (time) |
| Extra Vault Slots | Gamepass | Capacity (edge) |
| Faster Steal Channel | Gamepass | Raid speed (edge) |
| VIP / Season Pass | Subscription-style | Daily gems, cosmetics, small QoL |
| Shields | Consumable (gems) | Raid immunity window (safety) |
| Gem packs | Developer Product | Hard currency |
| Cosmetics | Product | Neon skins, vault themes, trails (pure vanity) |

**Guardrails so it doesn't become pay-to-win:**
- Never sell raw combat power or direct currency-for-vault-safety in a way that makes a spender
  un-raidable — that breaks the loop for everyone else and kills the target pool.
- Luck multipliers change *odds*, not *guarantees*; whales still gamble.
- Shields are time-boxed and visible to raiders (so protected bases aren't matchmade as targets),
  preventing "permanent fortress" accounts.

## Rolling / gacha integrity

- **Publish real drop rates** (Roblox policy + trust). The rates in UI must equal the server table.
- **Pity system** to cap bad luck: guaranteed rarity floor after N rolls without one; store pity
  counters server-side per rarity, never expose them in snapshots.
- RNG is server-side with a recorded seed for auditability; the client never rolls.

## Retention economy (the day-7 machine)

- Escalating login streak → day-7 guaranteed high-rarity roll.
- **Mythic of the Week**: one Mythic rollable for 7 days only. Drives FOMO return without permanent
  power creep (rotates out).
- Weekly "value stolen" leaderboard with cosmetic + gem rewards; resets Monday via MemoryStore.

## Metrics to instrument from day one

D1/D7 retention, session length, coin faucet/sink ratio per band, robbed-then-churned rate, ARPDAU,
roll→purchase funnel, and raid win-rate by band. The design decisions above are hypotheses; these
metrics are how we find out which ones are wrong.
