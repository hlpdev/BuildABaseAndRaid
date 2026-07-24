# Economy & Monetization

Goal: a self-correcting economy that stays fun for a day-30 player while monetizing **edge and time**,
never raw power. Two currencies:

- **Coins** — soft. Earned from vault income, raids, quests, and flea sales. Sunk into **building
  parts** (primary sink), upgrades, roll costs, and flea taxes.
- **Gems** — hard. Bought or earned sparsely. Sunk into luck, cosmetics, vault slots, shields, boosts.

## Faucets (coin sources)

- Vault passive income (offline-capped ~few hours; diminishing returns past a soft cap).
- Successful raids (scaled by the MMR/net-worth **gap** — raiding up pays, raiding down doesn't).
- Daily login + streak (day-7 guaranteed high-rarity roll).
- Quests / tutorial (one-time).
- Flea sales (secondary — moves value between players, net-neutral minus tax).

## Sinks (where coins die)

- **Building parts** — the main sink; every wall/door/vault costs coins and gets destroyed in raids
  (repair/rebuild = recurring sink).
- Part and vault **upgrades** (higher tier = more HP + income).
- **Roll costs** beyond the free cadence.
- **Flea listing + sale taxes** (also throttles manipulation).
- Base repair after raids (scales with base value).

Keep total sinks ≥ faucets for engaged players. Instrument the **faucet/sink ratio per MMR band** from
day one — inflation is the silent economy killer, and a destructible-base game has a naturally strong
sink (rebuilding) that helps.

## The Forge (item sink + up-tier gamble)

A hub installation: combine several items **of the same rarity** into **one random item of the next
rarity up**. It's a gambling-flavored chase *and* the game's primary **item sink** — it destroys its
inputs, which is what keeps the flea market from drowning in commons over time. The combine count is a
tuned constant; the top rarity can't forge upward. The Forge is deliberately an **item** sink, not a
coin sink (an optional small coin fee per forge is available as a tuning lever). Watch item supply per
rarity per week — if a tier inflates, the Forge ratio or drop weights are miscalibrated.

## Tiers are not prices

A rarity **tier sets only drop rate + UI color** — never price, combat value, or income. An item's
income "value" is a def field; its **price is 100% market-determined**. A rare item can be cheap if
it's weak or abundant; a common item can be pricey if it's useful and scarce. This keeps rarity honest
(it means "hard to roll," nothing more) and lets the flea discover real value.

## Anti-runaway rules (critical)

1. **Raid rewards scale with the gap** — raiding a richer/higher-MMR base pays well; punching down
   pays little. Funds newcomers, taxes the top.
2. **Vault income has diminishing returns past a soft cap** — hoarding stops being linearly better.
3. **MMR bands** put you against peers; bigger hoards mean bigger targets, not safer ones.
4. **Destruction is a natural wealth tax** — the rich rebuild more, sinking coins back out.

## Monetization (sell edge + time, never raw power)

| Product | Type | Sells |
| ------- | ---- | ----- |
| Gem packs | Developer Product | Hard currency |
| Luck Multiplier | Gamepass / timed | Better roll odds (edge, not guarantees) |
| Auto-Roll | Gamepass | Rolls while away (time) |
| Extra Vault Slots | Gamepass | Capacity (edge) |
| Income Boost | Gamepass / timed | Faster passive income (time) |
| Bigger Plot / Part Cap+ | Gamepass | Build bigger (careful: perf + fairness) |
| Shields | Consumable (gems) | Raid-immunity window (safety) |
| VIP / Season Pass | Subscription-style | Daily gems, cosmetics, small QoL |
| Cosmetics / Skins | Product | Weapon skins, base themes, neon trails (pure vanity) |

**Guardrails (so it stays Mild-9+ friendly and not pay-to-win):**
- Never sell raw combat power or make a spender **un-raidable** — that breaks the target pool for
  everyone.
- Luck changes **odds, not guarantees**; whales still gamble (published drop rates must match server
  tables — Roblox policy).
- Shields are time-boxed and mark a base **un-matchmadable**, preventing permanent-fortress accounts.
- "Bigger plot / part cap" upgrades must respect the perf cap and MMR fairness — cap the cap.

## Flea market's economic role

The flea (see `docs/FLEA_MARKET.md`) is a **value-transfer layer**, not a faucet — it's net-neutral in
coins minus taxes. Its jobs: give rolled items a **liquid price** (so loot always has meaning), create
a **trading meta** (a retention hook across all ages), and act as a **sink** via taxes. Its risk
(dupe→fraud, manipulation, RMT) is why it ships last and why the item-UID invariant is sacred.

## Compliance-aware monetization

Targeting **Mild 9+ / Roblox Select (9–15)** means monetization must avoid predatory patterns that
draw scrutiny: publish odds, no fake-scarcity dark patterns, clear gem pricing, no gambling-styled
loops beyond standard published-odds rolls. Complete the content-maturity questionnaire pre-launch.

## Metrics to instrument from day one

D1/D7 retention, session length, **coin faucet/sink ratio per MMR band**, robbed-then-churned rate by
band, ARPDAU, roll→purchase funnel, raid win-rate by band, and (once live) flea volume, spread, and
wash-trade flags. Every balance decision above is a hypothesis these metrics test.
