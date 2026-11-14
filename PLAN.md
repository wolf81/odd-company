# PLAN

An Undertale-inspired Roblox game. The player explores as **their own Roblox avatar**, starts alone, defeated or befriended enemies can join the party, and each companion has an unusual ability that changes how encounters play (not just more damage).

Source material lives in `design/`:
- `design/Roblox Undertale-Style Game MVP Plan.pdf` — the original plan (Nov 1, 2026). This file summarises it.
- `design/Game UI Proposals.html` — six UI mockups (open in a browser; it unpacks itself with JavaScript).

## Current status

- [x] Concept and MVP scope agreed
- [x] UI mockups drafted (A–F)
- [ ] Open questions answered (see bottom)
- [x] Step 0 tooling: Rokit, Rojo 7.7.1, Studio plugin, `default.project.json`, git repo
- [x] Step 0 check: `rojo serve` → connect in Studio → Play shows the `client running` / `server running` messages in Output (local place: `odd-company.rbxl`, git-ignored; old leftover scripts removed)
- [ ] Step 0 remaining: publish to Roblox (published, but shows "Unavailable" — investigate: questionnaire/rating, account restrictions, devices), set Avatar type to Player Choice, give the nephew access
- [x] Step 1: room 1 from code (`src/shared/Rooms/Room1.luau`), own avatar spawns in it, no jumping, locked top-down camera with scroll/pinch zoom (`src/client/TopDownCamera.luau`)
- [x] Step 2: Noob enemy (`src/shared/Enemies/Noob.luau`) built by `EnemyBuilder`, touching it shows a temporary "battle starts" banner (`src/client/EncounterTrigger.luau`)
- [x] Steps 3–5:
  - Step 3: touching the Noob freezes the player and fades to a dark client-side arena with the Noob and battle UI layout A (`src/client/Battle/`); reversed on exit
  - Step 4: shared state machine `src/shared/Battle/BattleLogic.luau` (PlayerTurn → ResolveAction → CheckEnd → EnemyTurn → CheckEnd → Win/Lose), UI only via hooks; damage formula already in `Damage.luau`. Win removes the enemy (this session, this client); lose returns you to the room spawn
  - Step 5: ATTACK / ACT menu (`BattleMenu.luau`) with mouse, touch, keyboard (arrows/WASD, Z/Enter/Space, X/Backspace) and gamepad; ACT lists Check + the enemy's own acts
  - Placeholders until steps 6–7: attacks always hit ×1; enemies always hit for ATK − DEF

## MVP scope

**Done when:** a tester can walk through all three rooms, win or lose each fight, and reach the end of room 3 without any explanation.

**In:** three connected rooms, one player, and battles with menu, attack, dodge phase, HP, win and lose:

| Room | Enemies | Purpose |
|------|---------|---------|
| 1 | 1 enemy: **Noob** | Learn the basics: menu, timing bar, dodging |
| 2 | 1 stronger enemy: **Builderman** | Same rules, harder: more HP/ATK/DEF and a new attack pattern |
| 3 | 2 enemies (one battle): **Headless Horseman + Korblox Deathspeaker** | Choosing a target, and dodging two enemies' attacks at once |

**Out for now:** party and recruitment (stretch, step 13), saving, inventory, NPCs and dialogue, more than three rooms, multiplayer, final art. Rooms use placeholder Parts; the player is always their own avatar; enemies are classic Roblox avatars (see the roster below).

The core battle is built and tuned in room 1 first (steps 0–9). Rooms 2 and 3 come after, once that fight is fun.

## Build steps

Work top to bottom. Each step ends in something testable. Recommended option first; alternatives after `·`.

| # | Step | Approach | Done when |
|---|------|----------|-----------|
| 0 | Setup | **Decided: Rojo + VS Code + Git.** Install Rojo (pinned with Rokit) and the Rojo Studio plugin, `git init`, and add `default.project.json` mapping `src/shared` → `ReplicatedStorage/Modules`, `src/client` → `StarterPlayerScripts`, and `assets/rooms` → `Workspace/Rooms` | `rojo serve` syncs a test script into Studio, the place opens and saves, and the nephew can open it too |
| 1 | Room and movement | The player's own avatar (no custom `StarterCharacter`) with default movement and a locked top-down camera. Avatar type set to **Player Choice** in Game Settings, so both R6 and R15 avatars work · custom 4-direction/grid movement | You can walk your own avatar (tested with both an R6 and an R15 avatar) around a small room built from plain Parts; doors and gaps fit large and small avatars |
| 2 | Enemy and trigger | Visible enemy you walk into (Deltarune-style) · random encounters. The enemy is the **Noob**: a rig built from a `HumanoidDescription` in its data module, idle-animating in place | Touching the Noob starts a battle |
| 3 | Battle transition | Same place, camera points at a dark arena built from Parts; the avatar stays where it is, anchored · separate battle place | Movement freezes, camera and battle UI appear, and it reverses on exit with the avatar back where it was |
| 4 | Battle state machine | Client-only logic in ModuleScripts · server-authoritative | States run `PlayerTurn → ResolveAction → EnemyTurn → CheckEnd → Win/Lose`; enemy data lives in a table |
| 5 | Player menu | Attack + Act only · Fight/Act/Mercy · Attack/Ability/Defend | Buttons work with mouse, touch and keyboard |
| 6 | Player attack | Timing bar (better timing = more damage) · instant hit | An attack takes ~2 s and feels like gameplay |
| 7 | Enemy attack phase | Heart in a box dodging projectiles drawn as UI frames · same in 3D Parts | One pattern works, then two more; hits deal damage and grant brief invincibility |
| 8 | Stats and damage | `damage = max(1, ATK - DEF) * timingMultiplier` · rules from the earlier combat chat | HP bars, win and lose screens, return to the room |
| 9 | Playtest and tune | Watch the nephew play; tune bullet speed, HP, timing window; swap in their art | They can finish a fight and say what to change |
| 10 | Room 2: stronger enemy | Add a door from room 1 to room 2 that opens once room 1's enemy is beaten. The second enemy reuses the battle system with its own stats table (more HP/ATK/DEF) and one new attack pattern | You can walk from room 1 into room 2, and the second fight is noticeably harder but still winnable |
| 11 | Room 3: two enemies | The battle takes a list of enemies instead of one. Add target selection to the Attack/Act menu; on the enemy turn both enemies attack in the same dodge phase (patterns combined, slightly slower each). The battle is won when both are at 0 HP | Room 3 starts one battle with both enemies, you can pick who to hit, and beating one leaves the other fighting |
| 12 | Three-room run | Beaten enemies stay gone for the session, and doors stay open. Losing restarts you at the entrance of the current room with full HP. Reaching the end of room 3 shows a simple "The End" screen | A tester plays from room 1 to the end screen without help; tune the difficulty curve across the three fights |
| 13 | Stretch: first companion | After a win the enemy joins with one arena-changing ability (e.g. slime returns a projectile) | The ability visibly changes how the next fight plays |

## UI

Mockups in `design/Game UI Proposals.html`:

| Battle | Room / exploration |
|--------|--------------------|
| **A. Classic box (MVP)** — enemy top centre, HP bar, command row at bottom; dodge box appears mid-screen on enemy turn | **D. Top-down room, minimal HUD (MVP)** — HP and an interaction `!` |
| B. Side-view party — party left, enemies right, command panel bottom-left | E. Party trail with HUD — companions follow, dialogue bubble, `E` to talk |
| C. Touch-first (phone landscape) — big bottom buttons, on-screen MOVE stick, small centred dodge box | F. Touch-first walking (phone landscape) — MOVE stick, TALK button |

MVP uses **A + D**. Check every layout against C/F, since Roblox is heavily played on phones.

**Player avatar:** in rooms the player is their own Roblox avatar. In battle the player is still the heart in the dodge box (as in Undertale), and the `YOU 14/20` panel shows the player's avatar headshot (`Players:GetUserThumbnailAsync`) next to their name. In the party-trail layout (E), companions follow the avatar.

Rules for all layouts:
- Text at least 18 px.
- Buttons at least 44 px tall.
- Keep the bottom corners free for the mobile thumbstick.

## Enemy roster

Enemies are well-known Roblox avatars, built in code from a `HumanoidDescription` (body colours plus catalog asset IDs) via `Players:CreateHumanoidModelFromDescription`. Each enemy's data table picks its rig type (R6 or R15): e.g. the Noob as a classic blocky R6, the bundle-based characters as R15. They stand in the room and in the battle arena, so the battle camera shows the actual avatar. Look up each catalog/bundle asset ID once and keep it in the enemy's data table; if an item is ever removed from the catalog, fall back to body colours only.

| Enemy | Look | Where | Attack pattern idea (dodge phase) |
|-------|------|-------|-----------------------------------|
| **Noob** | Classic yellow head and arms, blue torso, green legs | Room 1 (weakest) | Slow, wobbly blocks falling from the top. Teaches dodging |
| **Builderman** | Hard hat, construction outfit | Room 2 (stronger) | Bricks building walls across the box with one gap to slip through; later, a "build" sweep from the side |
| **Headless Horseman** | Headless Horseman bundle | Room 3 (with Korblox) | Flying pumpkins that bounce off the box edges |
| **Korblox Deathspeaker** | Korblox Deathspeaker bundle (skeletal leg, crown) | Room 3 (with Headless) | Bone spears thrust in from the sides on a rhythm |
| **Bacon girl** | Default-style avatar with the bacon hair | Later (Party slice / World) | Bacon strips zig-zagging across the box |
| **Shadow master** | Black ninja outfit | Later (Party slice / World) | Shuriken that fly straight, then curve toward the heart |

Room 3 pairs the two "rare" avatars as the final fight. Bacon girl and Shadow master wait for the next phase. They're also good first companion candidates (step 13): e.g. Shadow master could make the heart briefly invisible to bullets.

## Roadmap

Don't start a phase until the previous gate is met.

1. **MVP combat** (steps 0–12). Gate: a first-time tester finishes all three rooms unaided and wants to play again.
2. **Party slice.** Recruitment by fighting or acting, and two or three companions with distinct abilities, using the three MVP rooms. Gate: players pick different tactics depending on who is in the party.
3. **World.** More rooms beyond the first three, NPCs and dialogue, secrets, the nephew's characters and art. Gate: a ten-minute playthrough with a beginning and an end.
4. **Systems.** DataStore saving, items, progression, party screen. Gate: quit and resume without losing progress.
5. **Content and polish.** Art, audio, story arc, balancing, mobile testing. Gate: playtesters outside the family can follow it without help.
6. **Release.** Playtest rounds, then publish. Decide solo vs co-op *before* this phase — it changes the client/server split of the battle code.

## Companion ability ideas

- Slime: absorbs projectiles and spits them back.
- Ghost: possesses an enemy.
- Mimic: copies the player.
- Gravity creature: reverses gravity in the arena (favours building the dodge arena in 3D Parts later).

## Open questions

- [ ] What were the combat rules from the earlier HP / attack / defence chat? Step 8 assumes `max(1, ATK - DEF)`.
- [x] ~~Build in Studio by hand, or write scripts?~~ **Rojo + Git**: code lives in this repo and syncs into Studio.
- [ ] Combat format: menu + dodging (assumed), real-time action, or hybrid?
- [ ] Share the nephew's drawings so enemy, room and companion designs start from their ideas.
- [ ] Confirm UI layout for the MVP (A + D assumed).
- [ ] Room 3: one battle against both enemies (assumed), or two separate battles in the same room?
- [ ] Enemy order: Noob → Builderman → Headless Horseman + Korblox (assumed). Swap any of them with Bacon girl or Shadow master?
- [ ] Do doors stay locked until the room's enemy is beaten (assumed), or can players walk past?
