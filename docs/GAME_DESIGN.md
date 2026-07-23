# Game Design

## The one-sentence pitch

Roll for dual-purpose loot, then decide every item's fate: **carry it and get strong but droppable,
or vault it for income but stealable.** Raid others, defend yourself, reinvest.

## Core loop (30–60s cycle)

1. **Roll** at your base's Altar. Free roll on a cooldown (starts ~30s, shrinks with upgrades).
2. **Equip or Store.** Every item is dual-purpose:
   - *Carried* → combat value, but **dropped on death**.
   - *Vaulted* → generates income (coins/sec), but **stealable** by raiders.
3. **Raid** another base; channel-steal from their vault.
4. **Reinvest** income into defenses, vault capacity, and roll quality.

The tension between carry and vault is the entire retention engine. There is no idle state — every
item is a live micro-decision.

## Loot

Rarity tiers with **visible drop rates** (Common → Uncommon → Rare → Epic → Legendary → Mythic).
Each item carries three numbers and one behavior:

- **Combat value** (if carried)
- **Vault income** — coins/sec (if stored)
- **Steal difficulty** — channel seconds to extract (scales with rarity)
- **Ability** — functional, code-only (e.g. *Chain Lightning*, *Phase Dash*), never a bare stat buff

Making Mythics *do things* is what separates this from the dead "+50% damage" loot that kills most
"Build A" games. All abilities are code; zero modeling required.

## Base building (no modeling)

Grid-based plots built from a fixed primitive kit + free Creator Store assets:

- **Walls** — block line-of-sight, have HP
- **Turrets** — auto-fire at raiders
- **Traps** — slow / damage / alarm
- **Vault** — upgradeable capacity and steal-time multiplier

Hard rule: a new player reaches a **functional layout in under 60 seconds** via snap-grid presets,
then customizes. Tedious building is the second thing that kills this genre.

## Stealing (the signature mechanic)

- Raider stands at the vault and **holds to channel** for N seconds (scales with item rarity).
- Channel **breaks on damage** → defenses matter, and solo-vs-duo raiding is a real strategic axis.
- Raider can carry out only a **limited number** of stolen items; must reach the **exit zone** to
  bank the theft. Dying en route drops the loot.
- Owner gets notified (and, if offline, a rejoin prompt).

Server-authoritative end to end. See `docs/ANTI_EXPLOIT.md` and `docs/DATA_MODEL.md`.

## Retention structure

**D1 — the tutorial is the loop itself.** Forced first roll → auto-equip → scripted raider NPC hits
your base → you defend → you raid a bot base and steal. Under 90 seconds, no text walls.

**D7:**
- Escalating daily login rewards, culminating in a guaranteed high-rarity roll on day 7.
- Offline vault income, capped (~4h) so returning feels rewarding but doesn't remove the reason to
  play actively.
- Weekly leaderboard for total value stolen; resets Monday.
- Rotating **"Mythic of the Week"**, rollable for 7 days only → FOMO return.

**New-player protection (the #1 D7 killer if wrong):**
- First ~20 minutes = raid-immunity shield.
- Everyone gets a daily shield item; shields are also purchasable.
- A player who logs in to an emptied vault churns. Protecting the vulnerable window is not optional.

---

## Critical review — where I'm pushing back

The developer asked to be challenged. These are the design risks I rate highest, with recommended
mitigations. Treat this section as live; revisit as playtest data arrives.

### 1. Offline raiding is an asymmetric-fun trap
Getting robbed while offline feels *bad* in a way that robbing feels *good* — the ledger isn't
symmetric. If vaults are freely raidable while owners sleep, churn spikes among exactly the players
you retained yesterday.
**Recommendation:** Offline vaults leak only a **capped fraction** of stored value per raid, and
offline income keeps accruing. The fantasy is "someone chipped my hoard," not "I logged in to zero."
Consider: only *online* players are fully raidable; offline bases are matchmade at a reduced reward
multiplier. Instrument churn-after-first-robbery from day one.

### 2. "Free roll every 30s" fights your own monetization
A generous free faucet trains players to wait, not to pay. But throttling it too hard kills the loop.
**Recommendation:** Keep the free roll frequent (loop health) but make the **paid axis be quality and
convenience, not raw rolls** — luck multipliers, auto-roll while away, extra vault slots, faster
steal channels. Sell *edge and time*, not the core verb. See `docs/ECONOMY_AND_MONETIZATION.md`.

### 3. Rich-get-richer runaway
Winners get better loot → better defenses → safer vaults → more income → even better loot. Left
alone, the top 1% become un-raidable and new players see no path up. This is the long-term retention
killer, past D7.
**Recommendation:** Raid rewards **scale with the gap** (raiding up is lucrative, raiding down isn't),
vault income has **diminishing returns** past a soft cap, and matchmaking bands players by net worth.
Bigger hoards should mean bigger targets, not safer ones.

### 4. Server size 12–16 vs. "live economy" is in tension
A 16-player shard is great for personal raids but is **not** a persistent economy — bases don't
persist across your sessions on one server, and offline targets must be synthesized.
**Recommendation:** Be explicit that the "economy" is **per-account, cross-server** (profiles), and
raid targets are **matchmade snapshots** pulled from MemoryStore/DataStore, not live foreign servers.
Design the snapshot format early; it changes the data model. See `docs/ARCHITECTURE.md`.

### 5. Bot/NPC targets are load-bearing and under-specified
At launch and in low-population hours, there aren't enough real vaults to raid. If raiding a bot
feels hollow, the loop's payoff half evaporates.
**Recommendation:** Treat **snapshot bases** (real players' saved layouts, raided as async copies)
as the primary raid target, not live players. This solves offline-fun, population, and matchmaking at
once — and it's the model the successful games in this genre actually use.

### 6. Emissive-primitive art is a real style — but juice is mandatory
Without modeling, "game feel" carries the visuals. Screen shake, hitstop, particle bursts on steal
completion, satisfying roll animations, sound design. Budget real time for juice; it's not polish,
it's the product.

> **Meta-point:** the biggest risk to a 20K-CCU target isn't any single mechanic — it's shipping the
> loop before the *protection/fairness* systems (shields, matchmaking bands, offline caps) exist.
> Build the loop and the fairness rails together, not sequentially.
