# Contributing

Solo project, but held to production standards so it reads as one on a resume.

## Setup

```bash
rokit install     # pinned tools
just install      # wally install + sourcemap + type injection
```

## Workflow

- Work on a branch; keep `main` green (it's public and CI-gated).
- Live-sync: `just serve` (Rojo) + `just watch` (sourcemap) in two terminals, connect the Studio
  plugin.
- Before pushing: `just check` (format check + lint + analyze).

## Standards

- `--!strict` on every Luau file. Type your data; `ItemDefs` has an exported `type ItemDef`.
- Format with StyLua (`just fmt`). Tabs, width 100, double quotes. Vide paren style is preserved
  as-written (`call_parentheses = "Input"`) — don't reformat paren style either direction.
- Pass Selene and `luau-lsp analyze` with zero warnings.
- Respect the golden rules in [`../CLAUDE.md`](../CLAUDE.md): server-authoritative, pure `shared`,
  ByteNet for gameplay, session-locked persistence, idempotent steals, Trove cleanup, instance caps.

## Commits

- Conventional-ish, imperative present tense: `feat: add roll pity system`, `fix: dedup steal txId`.
- Keep commits scoped; a content addition (item/rarity/building) should be a near one-file diff in
  `src/shared/defs/`.

## Adding content

New item / rarity / building = a diff in `src/shared/defs/`. If it needs more than the def entry plus
one behavior module, the abstraction is wrong — raise it before merging.

## Tests

- Pure logic in `src/shared` gets a Jest spec (`*.spec.luau`). Keep game math side-effect-free so it's
  testable off-engine.
- In-engine integration tests via `run-in-roblox` are a later milestone (see `ROADMAP.md`).
