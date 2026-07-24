# Platforms & Input (Mobile / Console First)

Most of Roblox is on **phones and consoles**, not PC. This game is designed **mobile- and
console-first**, with mouse+keyboard as the *third* target, not the first. Every interaction —
building, breaching, combat, market — must be fully playable with a **thumb on glass** and with a
**gamepad**, or it doesn't ship.

## Non-negotiables

1. **One input abstraction.** `InputController` translates touch / gamepad / KBM into the same
   **intent** events the rest of the client consumes. No system reads raw `UserInputService` directly;
   they read intents (`PlacePart`, `Breach`, `Fire`, `Interact`, `RotatePart`). Adding a control
   scheme is a change in one file.
2. **No precision-mouse dependency anywhere.** Building can't require pixel-accurate cursor
   placement; it uses **grid snapping + a movable placement ghost** driven by camera/stick, confirmed
   with a big button. Combat uses **assisted aim** on touch/gamepad, not raw cursor.
3. **Thumb-reachable UI.** Primary actions sit in the bottom corners (thumb zones); nothing critical in
   the top-center. Honor device **safe areas** (notches, rounded corners, the Roblox topbar).
4. **Gamepad navigation is first-class.** Every screen is traversable with a D-pad/stick + A/B; set
   `GuiObject.NextSelection*` or use a selection system. No screen is mouse-only.
5. **Performance budget targets low-end mobile**, not a gaming PC. This is the real ceiling on part
   counts, draw calls, and VFX density — see below.

## Build mode on touch/gamepad

- **Placement ghost** follows a reticle at a fixed distance from the camera; the player moves the
  camera (drag / right stick) to aim it. It **snaps to the grid**, so precision comes from the grid,
  not the finger.
- **On-screen controls:** part picker (radial or tray), **Rotate**, **Place** (large confirm),
  **Delete**, and **Up/Down level** for vertical placement. Gamepad maps these to face/shoulder
  buttons.
- **Multi-place / drag-build** for walls where feasible, but the atomic unit is always "ghost →
  snap → confirm," which is identical across inputs.

## Combat & raiding on touch/gamepad

- **Assisted aim** (soft lock / aim-assist cone) on touch and gamepad; tune per weapon. Raw twitch
  aim is a PC-only luxury we never *require*.
- **Raid tools** target the part under the reticle; **hold-to-breach** is a big on-screen button with
  a clear progress ring — readable at a glance on a small screen.
- Movement: default Roblox touch thumbstick + jump; keep the character controller standard so mobile
  players get the muscle memory they already have.

## UI rules for small screens

- Minimum touch target ~44pt; generous spacing; no hover-only affordances (there is no hover on
  touch).
- Text legible at phone size; scale with `AbsoluteSize`, not fixed pixels; test at 720p phone and 4K TV.
- The **market/flea UI** is the hardest mobile screen (tables, charts, orders) — design it as
  **stacked cards + sparklines** on narrow screens, expanding to columns on wide ones. Charts must be
  readable and scrollable with a thumb.

## Performance budget (the real scaling ceiling)

- **StreamingEnabled** always; stream distant bases out aggressively (mobile RAM is the limit).
- **Hard per-base part cap** tuned to keep a full 12–16-base server within mobile memory + draw-call
  budgets, not just server CPU. See `docs/BUILDING_AND_RAIDING.md`.
- **Dummy parts are cheap by default** (colored Parts) — keep them that way; when real models land,
  hold a strict tri/draw-call budget (`docs/ASSET_PIPELINE.md`).
- VFX density scales down on low-end devices; destruction bursts must degrade gracefully.
- Profile on a **real mid/low phone**, not Studio, before declaring anything "fine."

## Testing

- Studio device emulator for layout, but **real-device passes** for touch feel and perf are required
  before any milestone is called done.
- Verify full playability with **gamepad only** and **touch only** as an explicit checklist per screen.
