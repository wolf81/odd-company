# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

An Undertale-inspired Roblox game, built together with a young co-designer (the owner's nephew). See `PLAN.md` for scope, build steps and open questions; `design/` holds the source plan (PDF) and UI mockups (HTML bundle — open in a browser).

## How to work

- **Follow `PLAN.md` in order.** Build the current step only; each step must end in something testable in Studio. Don't pull in out-of-scope features (saving, inventory, multiplayer, more than the three MVP rooms) before their roadmap phase.
- **Update `PLAN.md`** when a step is done or a decision is made: tick it off and replace assumptions with the answer.
- **Don't decide open questions silently.** If work depends on one (see the end of `PLAN.md`), ask, or go with the documented assumption and say so.
- **Placeholder art for rooms** until the nephew's drawings arrive: plain Parts, Frames and simple colours.
- **Enemies are classic Roblox avatars** (Noob, Builderman, Headless Horseman, Korblox Deathspeaker, later Bacon girl and Shadow master; see the roster in `PLAN.md`). Build them in code from a `HumanoidDescription` stored in each enemy's data table, using `Players:CreateHumanoidModelFromDescription` with the rig type (R6 or R15) also set in that table. Don't hand-build rigs in Studio. Enemy rigs are anchored or scripted; they don't use player movement.
- **The player is their own Roblox avatar.** Don't add a `StarterCharacter` or replace or restyle the character. Both **R6 and R15** avatars are allowed (Game Settings: Player Choice), so code must work with any rig type, size, shape and accessories: use the `Humanoid` and `HumanoidRootPart` only, never named body parts (`Torso` vs `UpperTorso`, etc.) or fixed heights. Test movement, triggers and doors with one R6 and one R15 avatar. In battle the player is shown as the heart in the dodge box plus their avatar headshot in the HUD.
- **Keep it readable.** A beginner should be able to follow the code. Prefer short, well-named functions and comments that say *why*, over clever abstractions.

## Code conventions (Luau)

- Language: Luau, with `--!strict` at the top of new modules where practical.
- Layout (from the plan):
  - `ReplicatedStorage/Modules/` — shared ModuleScripts (battle state machine, enemy data, damage formula).
  - `StarterPlayerScripts/` — client entry points (camera, movement, battle UI).
  - `Workspace/Rooms/Room1`, `Room2`, `Room3` — room geometry, doors and enemy triggers.
- Game data (enemy stats, attack patterns, tuning numbers) lives in plain tables in their own modules, not inline in logic, so it's easy to tweak during playtests.
- Battle states: `PlayerTurn → ResolveAction → EnemyTurn → CheckEnd → Win | Lose`. Keep transitions in one place.
- A battle takes a **list** of enemies from the start, even though rooms 1 and 2 have only one. Room 3 needs two, and this avoids a rewrite at step 11.
- MVP battle logic is client-only. Keep it in ModuleScripts with no direct UI calls, so it can move server-side later if co-op is chosen.
- Use `Players.LocalPlayer`, `task.wait`/`task.spawn` (not `wait`/`spawn`), and `game:GetService(...)`.

## UI rules

- MVP layouts: **A** (battle, classic box) and **D** (room, minimal HUD).
- Text ≥ 18 px, buttons ≥ 44 px tall, bottom corners free for the mobile thumbstick.
- All input must work with mouse, touch and keyboard. Check against the touch layouts (C, F).

## Tooling

**Rojo + VS Code + Git.** All code lives in this repo as files; Rojo syncs it into Roblox Studio.

- `default.project.json` defines how folders map into the game:
  - `src/shared/` → `ReplicatedStorage/Modules` (ModuleScripts, `*.luau`)
  - `src/client/` → `StarterPlayer/StarterPlayerScripts/Client` (LocalScripts, `*.client.luau`; `Main.client.luau` is the entry point)
  - `src/server/` → `ServerScriptService/Server` (Scripts, `*.server.luau`, only when something needs the server)
  - `assets/rooms/` → `Workspace/Rooms` (room geometry as `.rbxm` model files). This folder has `$ignoreUnknownInstances: true` so Rojo never deletes rooms built in Studio that aren't saved to disk yet. Keep it that way.
- Setup on a new machine: `winget install Rojo.Rokit`, then `rokit install` in the repo (installs the pinned Rojo), then `rojo plugin install` (Studio plugin). Recommended VS Code extensions are in `.vscode/extensions.json`.
- Check the project before handing off: `rojo build -o build/test.rbxl` must succeed. For luau-lsp type info, run `rojo sourcemap -o sourcemap.json` (git-ignored).
- Develop: run `rojo serve`, then connect from the Rojo plugin in Studio. Edit code in the repo, never in Studio, or Rojo will overwrite it.
- Room geometry is built by hand in Studio, then saved back as `.rbxm` into `assets/rooms/` (right-click → Save to File) so it's versioned.
- Tool versions are pinned in `rokit.toml`. Don't commit `.rbxl` place files or editor clutter.
- Before saying a step is done, check it actually runs in Studio (Play test). Static review of Luau isn't enough.
