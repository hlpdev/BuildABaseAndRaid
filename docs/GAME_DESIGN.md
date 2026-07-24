# Game Design

## The pitch

**Buy** the parts to build a destructible base. **Roll** for the gear, abilities, and raid tools you
carry. Grow passive income from your vaults, raid the players sharing your server in real time, and
trade everything on a global player-run market. Your base is safe when you log off — but everything
you carry can be lost the moment you die.

## Two economies, cleanly separated

- **Building parts are purchased** with coins (the primary coin *sink*).
- **Loot is rolled** — a gacha of weapons, abilities, raid tools, boosts, and building props (the
  primary dopamine *faucet*).

Keeping "the thing you grind for" (rolls) separate from "the thing you spend on" (parts) makes both
loops legible and independently tunable.

## Core loops

**Seconds → minutes (moment-to-moment):** roll at your altar, fight or farm, drop-in on a neighbor's
base, breach a wall, grab loot, run it home.

**A session (minutes → an hour):** convert income + raid spoils into more parts → a stronger base →
safer vaults → higher income; flip items on the flea market; climb toward better matchmade lobbies.

**Days → weeks (meta):** capped offline income pulls you back; daily/streak rewards; rotating
limited items; weekly leaderboards; a living market you check like a stock ticker.

## The base

Built from **purchased modular parts** on a per-player plot: foundations, walls, floors, ramps,
**doors**, **hatches** (vertical doors), **ladders**, and **vaults** — each in tiers
(wood → stone → metal) and variants. Bases:

- **Persist on your profile**, not on the server.
- **Instantiate into the server when you're online**, and are **only raidable while you're online**.
- Are **completely safe while you're offline.** This deliberately deletes the genre's #1 churn source
  — nobody ever logs in to an emptied vault.

Full **destruction** is real: walls, doors, and hatches have HP and material tiers; raid tools deal
typed damage; parts are removed at 0 HP; a cheap server-side **support graph** decides what stays
standing. No live physics. See `docs/BUILDING_AND_RAIDING.md`.

## Loot

Rolled from **rarity tiers** (more than six; e.g. Common → … → Divine) with **published drop rates**.
Crucially, **a tier defines only two things: its drop rate and its UI color.** Tiers do **not** set
price, combat value, or income — an item's stats are per-item, and its price is set entirely by the
market. A high-tier item is *rare*, not automatically *strong* or *expensive*. Categories:

- **Weapons** — PvP.
- **Abilities** — code-only, functional (e.g. *Phase Dash*, *Chain Lightning*), never bare stat buffs.
- **Raid tools** — the only way to breach (charges, cutters, drills); typed vs. material tiers.
- **Boosts** — income, luck, speed, defense.
- **Building props / cosmetics** — vanity and flavor.

Every item is a **server-minted global UID instance** from birth — because it may later be vaulted,
dropped on the ground, or listed on the flea market, and the server must track it everywhere.

## Carry, death, and dropping

- **Carried items drop on death** (full-loot) as ground loot anyone can pick up.
- **Currency does NOT drop on death** — losing rolled gear stings enough; losing coins too would be
  brutal and rage-inducing for the target age.
- Players can **deliberately drop** currency (piles) and items (Delete key) onto the ground. This is
  the *only* face-to-face "trading" — trust-based, risky, no trade GUI. Real trading is the flea.
- **Vaulted items are safe** unless a raider breaches your base and reaches the vault.

## Raiding

Same-server, real-time, **only vs. online players**:

1. Find a target base in your server (matchmade lobby, so targets are near your level).
2. **Breach** — spend raid tools to destroy doors/hatches/weak points and tunnel toward the vault.
3. **Loot the vault**, carry it out, survive the trip home. Die and it drops.

Server-authoritative end to end (`docs/ANTI_EXPLOIT.md`). Defense = base layout + traps/turrets +
being present to fight back.

## Fairness: MMR-banded matchmaking + protection

Full-loot PvP for a 9+ audience only works if minnows don't get fed to sharks.

- A **hidden MMR** (skill × net worth) rates every player. Players see a friendly *level*, never the
  raw rating, so it can't be gamed or demoralize.
- The matchmaker bands players by MMR into **reserved servers** via `TeleportService` +
  MemoryStore queue. See `docs/MATCHMAKING.md`.
- **Hub/spawn is a safezone.** New players get a **protection window**. Both are backstops; MMR
  banding is the primary fairness mechanism.

## Safe zones (the hub)

The hub is a non-combat, non-theft zone with exactly two interactive installations (nothing else is
interactive there):

- **The Forge** — combine several items **of the same rarity** into **one random item of the next
  rarity up**. A gambling-flavored **up-tier** mechanic and a powerful **item sink** (it destroys the
  inputs). Players will feed it their commons to chase higher tiers. The top tier can't forge upward.
  Combine count is a tuned constant. See `docs/ECONOMY_AND_MONETIZATION.md`.
- **The Market** — where the flea market lives: walk up to Market NPCs, they pop the market UI (browse,
  charts, buy/sell orders). Purely UI-driven; no other world interaction.

The hub is also the matchmaking lobby and the safezone backstop for new players.

## Global flea market

An async, player-run **order-book exchange** (Steam-market / Tarkov flea in spirit): global listings,
player-set prices, **buy orders and sell orders** that auto-match, and **price history charts**.
Items move into **server-side escrow** the instant they're listed — the item leaves your inventory
immediately, closing the list-then-dupe window. See `docs/FLEA_MARKET.md`. Built late; the item model
supports it from day one.

## Passive income

Accrues from **vault tier × stored item value × boosts/gamepasses**, with **diminishing returns past
a soft cap** (anti-hoarding) and a **~few-hour offline cap** (return incentive without idling being
optimal). Never computed client-side.

## Retention structure

- **D1:** the tutorial *is* the loop — roll → equip → build a starter wall → defend against a scripted
  raider → breach a bot base → loot it. Under ~90s, no text walls.
- **D7:** daily login streak → guaranteed high-rarity roll; capped offline income; weekly "value
  raided/traded" leaderboards; rotating limited items (FOMO return); a market worth checking daily.
- **Protection window** for new accounts so the first bad beat doesn't end the relationship.

## Platforms: mobile & console first

Most of Roblox plays on phones and consoles. Building, breaching, combat, and the market are all
designed to be fully playable **thumb-on-glass and on a gamepad** first, mouse+keyboard third. This is
a hard design constraint on every interaction. See `docs/PLATFORMS_AND_INPUT.md`.

## Audience & launch phasing (verified 2026)

Reaching under-16 players is **gated on traction**, not just content:

- To be playable by under-16s (Roblox Kids 5–8, Select 9–15), a game must pass a **3-step review**,
  which only completes after **500 unique plays by "highly engaged," age-checked users in a 60-day
  window** (the metric is deliberately vague to resist botting). Drop below **100** active in 60 days
  and under-16 access is lost until 500 is re-hit. Creator prerequisites: account in good standing,
  ID/parent verification, 2FA. Content must be **Minimal or Mild** (Mild = Select).
- **Therefore we phase the launch:** ship to **16+/general**, drive to **500 highly-engaged
  age-verified players** on ad spend, *then* unlock under-16 on review. We build **Mild-9+ compliant
  from day one** (cartoon/unrealistic combat, no realistic gore/weapons, safe chat) so we pass the
  instant we qualify — but the first ~60 days are planned as a 16+ game. The hardcore full-loot
  audience skews older anyway, so this ordering fits.

---

## Critical review — live risks in *this* design

The developer asked to be challenged. The four choices locked this turn each carry a cost:

### 1. Full destruction is the scope/perf boss fight
Chosen deliberately, but it *is* the hardest system in the game. Mitigations are structural, not
optional: deterministic HP (no physics), hard per-base part cap, aggressive streaming of other bases,
and typed damage so raids are tuned by tool-vs-tier math, not physics. If perf work slips, this is
what breaks first at 10K CCU. See `docs/BUILDING_AND_RAIDING.md`.

### 2. Full-loot + young audience still needs constant fairness attention
MMR banding is the right primary fix (better than a shield alone), but MMR is only as good as its
inputs and cold-start. Instrument *robbed-then-churned* by MMR band from day one; if a band churns,
the matchmaker is miscalibrated, not the players.

### 3. Turtling and "log off to protect"
Offline-safe bases mean the optimal cowardly play is: farm, vault, log off. Counter-pressure:
income requires being online to *collect past the offline cap*, best rolls/keys gate behind active
objectives, and raiding is where the big rewards are. Watch session length vs. base value.

### 4. The flea market is an economy you can lose control of
Order-book + player pricing invites **duping → fraud**, **price manipulation/wash trading**, and
**RMT**. The item-UID single-location invariant is the dupe defense; velocity limits, listing taxes
(a sink), full transaction logging, and per-account throttles are the manipulation/RMT defenses. This
is the highest-risk system to ship — hence last, behind a proven-stable core economy. See
`docs/FLEA_MARKET.md`.

> **Meta:** the loop and its fairness rails (MMR, safezones, offline cap, income diminishing returns)
> ship together in M2 — never the raid loop first and safety later.
