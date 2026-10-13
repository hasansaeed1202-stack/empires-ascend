# Coding and scene conventions

## GDScript

- Use `snake_case` for files, variables, functions, signals, and input actions.
- Use `PascalCase` for named classes, nodes that represent roles, and enums.
- Add static types to public interfaces and non-obvious local values.
- Keep scripts focused on one responsibility and prefer composition to deep
  inheritance.
- Use comments to explain contracts and decisions, not line-by-line mechanics.

## Scenes and ownership

- Give a scene one clear root role; child nodes implement that role.
- The node that creates a runtime object owns and frees it unless ownership is
  explicitly transferred.
- Feature scenes may depend on autoload interfaces. Autoloads must not depend on
  concrete gameplay or UI scenes.
- Store reusable tuning and definitions in custom Resources in future milestones.

## Signals

- Use signals to publish completed state changes across feature boundaries.
- Include the old and new value when consumers need deterministic updates.
- Connect within the owning scene where possible and disconnect externally owned
  callables when their lifecycle is shorter than the emitter's.

## Git workflow

- Branch names: `feature/<ticket>-short-description` or
  `fix/<ticket>-short-description`.
- Commit messages use an imperative summary and keep each commit scoped to one
  coherent change.
- Never commit `.godot/`, imported caches, export output, or local editor files.
- Run the smoke test and relevant scene checks before requesting review.
