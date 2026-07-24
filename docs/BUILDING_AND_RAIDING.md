# Building & Raiding (Full Destruction)

The signature — and heaviest — system. Design goal: the full Rust "blow a hole and tunnel to the
vault" fantasy, **deterministically, with zero live physics**, at 10K+ CCU.

## Hard rules

1. **No live physics for structures.** Parts never fall, tip, or simulate. A part is either present
   (anchored) or destroyed (removed). This is a scale and anti-exploit requirement, not a shortcut.
2. **Server owns all structure state.** Placement, HP, and destruction are server-authoritative. The
   client renders and predicts VFX only.
3. **Grid-snapped placement.** Parts snap to a build grid on the plot; the server validates every
   placement (bounds, overlap, support, cap, cost). Client coordinates are never trusted.
4. **Hard per-base part cap.** A fixed budget (e.g. ~200–400, tuned) bounds worst-case instance count
   and raid cost. Hitting the cap is a design pressure (build smart), not a bug.

## Parts: variable-size, rectangular, grid-aligned

Bases are **large**. Parts come in **many sizes** but are always **rectangular/square and
grid-aligned — no triangles, nothing that can't snap to the grid.** Kinds include: `Foundation`,
`Floor`, `Wall`, `HalfWall`, `DoorFrame`, `Door`, `Hatch`, `Ladder`, `Ramp`, `Pillar`, and `Vault`
(see vaults below). Each kind has a **footprint + height** (in grid units) declared in its def, so a
wall, a half-wall, and a floor occupy the grid differently but all snap cleanly.

A `material` (`Wood` / `Stone` / `Metal`, extensible) is **separate from `kind`** and drives HP and
damage resistances. Grid resolution and level height are tunables in `src/shared/Config`.

Each placed part is a def reference + instance state:

```
Placed = {
    uid,                 -- server-minted, unique within the base
    defKey,              -- -> BuildingDefs entry (kind, material, size, hp, resist, cost, ...)
    gridPos, rot,        -- snapped, server-validated (rot in 90° steps)
    hp,                  -- current (maxHp comes from the def)
    level,               -- upgrade level (vaults, doors)
    -- Vault instances additionally carry their stored item UIDs (see below).
}
```

**Dummy models for now:** every part renders as a **colored Part** (color = material/variant/tier)
until real models are commissioned. The def carries a `color`; swapping in a model later never touches
the simulation. See `docs/ASSET_PIPELINE.md`.

All stats (HP, resistances, size, income, cost) come from `src/shared/defs/BuildingDefs`, never from
the wire — rebalancing is a one-file change and untamperable.

## Vaults are placeable, typed, and plural

A vault is **not** a fixed object on the plot. There are **multiple vault types and levels**, each a
placeable part the player can put **anywhere inside their base**. A vault def carries **storage slots**
and an **income multiplier**; higher types/levels store more and/or boost income more (and cost more,
and have more HP). Passive income sums across **all** the player's placed vaults. This makes base
layout a real decision: spread vaults out (harder to raid all of them) or cluster them (easier to
defend, easier to lose at once). Stored item UIDs live on the specific vault instance (see
`docs/DATA_MODEL.md`).

## Structural integrity — the support graph (cheap, event-driven)

Instead of physics, a **support graph** answers "is this part still attached to a foundation?"

- Foundations are **anchors**. Every other part must trace a support path (through adjacent
  placed parts) back to an anchor.
- The graph is recomputed **only on a structural change** (place / destroy), never per frame — and
  only for the **connected component** touched, not the whole base.
- When a part is destroyed, any parts that lose all support paths are also destroyed (a satisfying
  chain-collapse) — resolved as a bounded flood-fill, then a single batched replication of removed
  UIDs.

This gives "cut the supports and the roof drops" gameplay for the cost of a small graph walk on
destruction events.

## Damage & raid tools

- **Raid tools are rolled loot** (charges, cutters, drills, thermite), each with a **damage type**
  (`Explosive` / `Ballistic` / `Kinetic` / `Fire`, extensible) and its own **damage amount** — like
  Rust, not every tool (or weapon) hits equally hard.
- **Asymmetric resistance:** damage is scaled by the target's **material** *and* **structure type** —
  e.g. explosives strong vs. stone but poor vs. metal; cutters shred metal doors but barely scratch
  walls; fire good vs. wood. Each `BuildingDef` carries a per-damage-type `resist` multiplier. Raids
  are solved by **tool-vs-material/type math**, deliberately, so balance lives in a table — not in
  physics. Picking the right tool for the wall you're hitting is the skill.
- Damage is applied **server-side** on validated tool use (ownership, cooldown, position, LoS to the
  target part every tick). See `docs/ANTI_EXPLOIT.md`.
- Doors/hatches have their own HP and can be **lock-broken** or **destroyed**; vaults have the highest
  HP and a soft-timer on loot extraction once exposed.

## The raid, step by step

1. Matchmaker places you with same-band players (`docs/MATCHMAKING.md`); their bases are instanced.
2. You approach a target base (owner may be present and fighting back — defenses + traps + turrets).
3. **Breach:** spend raid tools to destroy doors/hatches/weak walls and open a path. The support graph
   may collapse sections, opening shortcuts (or burying the vault deeper).
4. **Extract:** reach an exposed vault; extraction is a short server-timed channel (breaks on damage).
   Stolen items move to your carried inventory as ground-lootable-on-death.
5. **Escape:** carry loot to safety. Die en route → full drop.

## Replication & performance

- **ByteNet deltas only.** Placement and destruction send changed/removed UIDs, never whole-base
  snapshots (except one full sync when a base streams in). See `docs/NETWORKING.md`.
- **StreamingEnabled** with per-base streaming: a client loads only bases within raid range; distant
  plots stream out. Never hold all 15 other bases fully loaded.
- **Actors / parallel Luau** for turret targeting and raid pathfinding across bases; authoritative
  mutation (HP writes, support recompute) stays on the serial thread.
- **Batch destruction:** a chain-collapse replicates as one message of removed UIDs + one VFX cue, not
  N messages.

## Persistence

A base is serialized to the profile as a compact list of `Placed` entries (kind/tier/gridPos/rot/
level — HP resets to max on load; damage doesn't persist since offline bases aren't raidable). On
join, `BaseService` rebuilds the base from this list. See `docs/DATA_MODEL.md`.

## Anti-exploit notes specific to building

- Reject placements outside plot bounds, overlapping, unsupported, over cap, or unaffordable —
  server-side, every time.
- Never trust client-reported destruction or HP; the server is the only writer.
- Rate-limit place/destroy/tool-use packets per player (token bucket).
- Validate raider position and LoS to the targeted part each damage tick; reject impossible reach.
