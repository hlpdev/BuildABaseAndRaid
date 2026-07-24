# Asset Pipeline (No In-House Modeling/Animation)

Neither developer models or animates. This is a **budget-allocation and sourcing** problem, not a
blocker — most of the game's "feel" is code (VFX, UI, juice), which is our strength. This doc says
where the friend's funding goes and what we build ourselves.

## Phase 1 (now → launch): dummy models everywhere

**Build the entire game with placeholder primitives first.** Every building part is a **colored
Part** (color = variant/material/tier); every item is a stand-in icon; weapons/tools are simple
Parts. This is deliberate, not a stopgap excuse:

- It **unblocks all gameplay/systems work immediately** — we don't wait on any artist.
- Dummy parts are **cheap** (critical for the mobile perf budget), so the game is playable and
  tunable at scale from day one.
- Real models drop in **later** as pure swaps behind the `BuildingDefs` / `ItemDefs` tables — the
  simulation (HP, grid size, damage, income) never changes, only the visual.

The item and part sets start **small and grow continuously** toward release (eventually hundreds of
items). Because content is data (`src/shared/defs`), adding one is a one-file diff — dummy or modeled.

## Phase 2 (post-traction): commission on the critical path, code the rest

| Asset class | Source | Who |
| ----------- | ------ | --- |
| **Modular building kit** (walls/floors/ramps/doors/hatches/ladders/vaults × wood/stone/metal) | **Commission or buy** — highest-visibility art, the core of the game | $ paid |
| **Damage states** for the kit (cracked/broken textures, debris) | **Code** — texture/SurfaceAppearance swaps + particles at HP thresholds | us |
| **Hero weapons + raid tools** (3–5) with viewmodel **animations** | **Commission** — animation is the one thing we can't fake | $ paid |
| Player characters | **Default Roblox avatars** — players bring their own | free |
| Abilities & combat VFX | **Code** — particles, beams, trails, shaders | us |
| Destruction VFX / juice (shake, hitstop, dust) | **Code** | us |
| All UI (inventory, vault, shop, flea, charts) | **Code (Vide)** | us |
| Props / decor / cosmetics | **Creator Store / Toolbox** (vetted) + code tinting | mostly free |
| SFX / music | **Creator Store audio** + licensed packs | free/$ |

## Where the funding goes, in priority order

1. **Tiered modular building kit.** Get this right first — it's on screen constantly and defines the
   art direction. Ensure parts are **grid-consistent** (uniform stud dimensions) so snap-placement and
   the support graph are clean, and that each part reads clearly at its tier (wood vs. stone vs.
   metal silhouette/material).
2. **Hero weapons + raid tools with animations.** A small, high-quality set beats a large mediocre
   one. Raid tools especially need satisfying use animations — breaching is the signature action.
3. Everything else waits or is code/marketplace.

## Requirements to hand a modeler (so assets drop in clean)

- **Grid module size** fixed up front (e.g. every wall = N×N studs) — placement + support depend on it.
- **Consistent pivots/origins** on every part for predictable snapping and rotation.
- **Separate, swappable materials/textures per tier** so damage states are texture swaps, not new
  meshes.
- **Low, budgeted tri-counts** — 15 bases on screen; parts must be cheap. Provide a poly budget.
- **Neon/emissive accent channel** so our code can tint/animate parts (ownership color, damage glow)
  without new art.

## Art direction as a constraint, not an apology

Stylized, readable, emissive-accented — reads as deliberate, performs well, and satisfies the **Mild
9+** rating (no realistic gore/weapons). Juice (screen shake, particles, sound, hitstop) does the
heavy lifting on "game feel"; that's ours to own and where a programmer-led game wins.

## Compliance touchpoints for assets

- No realistic weapons or gore; combat reads cartoon/unrealistic (Mild 9+ eligibility).
- Vet every Creator Store/Toolbox asset for licensing and hidden scripts before import.
- Keep SFX/music properly licensed — audio takedowns can pull a whole experience.
