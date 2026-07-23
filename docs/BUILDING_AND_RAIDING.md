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

## Part model

Each placed part is a def reference + instance state:

```
Placed = {
    uid,                 -- server-minted, unique within the base
    kind,                -- "wall" | "door" | "hatch" | "ladder" | "vault" | "foundation" | ...
    tier,                -- "wood" | "stone" | "metal"  (drives HP + damage resistances)
    gridPos, rot,        -- snapped, server-validated
    hp, maxHp,           -- current / max
    level,               -- upgrade level (vaults, doors)
}
```

Stats (HP, resistances, income for vaults, cost) come from `src/shared/defs/BuildingDefs`, never from
the wire — rebalancing is a one-file change and untamperable.

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

- **Raid tools are rolled loot** (charges, cutters, drills), each with a **damage type** and profile.
- **Typed damage vs. tier**: e.g. explosive is strong vs. stone, weak vs. metal; cutters strong vs.
  metal doors, useless on walls. Raids are solved by **tool-vs-tier math**, deliberately, so balance
  lives in a table — not in physics.
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
