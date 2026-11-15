# PLAN

An Undertale-inspired Roblox game. The player explores as **their own Roblox avatar** and starts in a **small village**, where they can build a **team of allies** (up to 3 at once): the **Noob** (their childhood friend, joins straight away) and **Elliot** (a hungry pizza delivery guy, joins once you bring him a slice of pizza from a chest). Each ally has an unusual ability that changes how encounters play (not just more damage). Later, befriended enemies can join the party too.

Source material lives in `design/`:
- `design/Roblox Undertale-Style Game MVP Plan.pdf` — the original plan (Nov 1, 2026). This file summarises it.
- `design/Game UI Proposals.html` — six UI mockups (open in a browser; it unpacks itself with JavaScript).

## Current status

- [x] Concept and MVP scope agreed
- [x] UI mockups drafted (A–F)
- [ ] Built, **waiting for a Studio Play test** (Nov 15, 2026):
  - Step 8 (part): Builderman (`src/shared/Enemies/Builderman.luau`, R15, body colours only for now) replaces the Noob in room 1; block patterns re-coloured as bricks. Still to do in step 8: enemy HP bar, proper win/lose screens
  - Step 10: village (`src/shared/Rooms/Village.luau`) south of room 1 with open doors between them; the player spawns there. `RoomBuilder` now does open doors, decorations (houses, path) and chests
  - Step 11: Talk/Open prompts (Roblox `ProximityPrompt`: E key, gamepad, tap). `src/client/Village.luau` runs recruiting and the pizza quest, `Dialogue.luau` the text box with Yes/No, `Party.luau` + `AllyFollow.luau` make the ally follow your path
  - Team (Nov 15): both allies can join; max 3 in the team (`Config.MaxTeamSize`). Recruiting a 4th asks who goes back to the village (they return to their spot and can be recruited again). Allies walk in a line behind you
  - Step 12: one ALLY command button opens a list of the team's abilities (COLA / PIZZA, with turns left while cooling down; skipped with one ally), `& Noob, Elliot` in the HUD; ability and burn logic in `BattleLogic`, numbers in `src/shared/Allies/`
- [x] Starting village with two allies (Noob, Elliot) added to the MVP (Nov 15, 2026). Steps renumbered: village and allies 10–12, rooms 2/3 now 13–14, full run 15
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
- [x] Steps 6–7:
  - Step 6: timing bar in the dialogue box (`playerAttack` hook in `src/client/Battle/init.luau`): centre = ×1.6, edges = ×0.4, no press = miss; enemy flashes red, shakes, shows the damage number, fades out when defeated (`BattleArena.showHit`)
  - Step 7: heart-in-a-box dodge phase (`DodgeBox.luau`) with keyboard, gamepad and touch-drag movement, 1 s invincibility after a hit, HP drops live; Noob has three patterns used in turn order (`Patterns.luau`: FallingBlocks, SideBlocks, BlockRows)

## MVP scope

**Done when:** a tester can start in the village, recruit an ally, walk through all three rooms, win or lose each fight, and reach the end of room 3 without any explanation.

**In:** a starting village where you build a team of up to 3 allies, three connected rooms, one player, and battles with menu, attack, dodge phase, HP, win and lose:

| Room | Enemies | Purpose |
|------|---------|---------|
| Village | none: two possible allies (**Noob**, **Elliot**) and a chest with pizza | Start of the game. Talk to people and recruit allies (Noob straight away, Elliot after the pizza quest). Both can join |
| 1 | 1 enemy: **Builderman** | Learn the basics: menu, timing bar, dodging, and your ally's ability |
| 2 | 1 stronger enemy: **Bacon girl** (assumed) | Same rules, harder: more HP/ATK/DEF and a new attack pattern |
| 3 | 2 enemies (one battle): **Headless Horseman + Korblox Deathspeaker** | Choosing a target, and dodging two enemies' attacks at once |

**Out for now:** recruiting enemies after a fight, saving, an inventory (the pizza is a single quest flag, not an item system), NPCs beyond the two allies, branching dialogue, more rooms than the village + three, multiplayer, final art. Rooms use placeholder Parts; the player is always their own avatar; enemies and allies are classic Roblox avatars (see the rosters below).

The core battle is built and tuned in room 1 first (steps 0–9). Then the village and allies (steps 10–12), then rooms 2 and 3, once that fight is fun.

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
| 8 | Stats and damage | `damage = max(1, ATK - DEF) * timingMultiplier` · rules from the earlier combat chat. Also swap room 1's enemy: **Builderman** (tutorial tuning: low HP/ATK) replaces the Noob, who becomes an ally; his patterns start as the current block patterns, re-themed as bricks | HP bars, win and lose screens, return to the room; Builderman is the room 1 fight |
| 9 | Playtest and tune | Watch the nephew play; tune bullet speed, HP, timing window; swap in their art | They can finish a fight and say what to change |
| 10 | Village | A new start room south of room 1 (`src/shared/Rooms/Village.luau`): a few placeholder houses, a path and a door north into room 1, open from the start. The player now spawns in the village. Place the Noob, Elliot and a chest as interactables | You spawn in the village, can walk around it with an R6 and an R15 avatar, and walk through the door into room 1 |
| 11 | Recruit allies | Walk up to someone or something → `!` prompt (layout D) and a TALK button / `E` (layouts E, F). A short dialogue box, no branching beyond yes/no. **Noob:** "It's me, your old friend! Can I come?" → Yes = joins. **Elliot:** "I'm sooo hungry..." until you open the chest (you get a *Pizza slice*), then "Pizza! I'll come with you!" → Yes = joins. The team holds at most 3; recruiting a 4th asks who goes back to the village. Allies follow the player in a line (simple scripted follow, anchored rig, no player movement) · allies only appear in battle | You can recruit the Noob and (after the pizza quest) Elliot; both follow you into room 1 |
| 12 | Ally in battle | The ally shows in the HUD next to `YOU` (layout A, small portrait + name) and adds one menu option with their ability (see Allies below). Ability logic lives in the ally's data module and plugs into `BattleLogic` hooks, no UI calls | Each ally's ability visibly changes how the room 1 fight plays; the fight is still winnable without it |
| 13 | Room 2: stronger enemy | Add a door from room 1 to room 2 that opens once room 1's enemy is beaten. The second enemy reuses the battle system with its own stats table (more HP/ATK/DEF) and one new attack pattern | You can walk from room 1 into room 2, and the second fight is noticeably harder but still winnable |
| 14 | Room 3: two enemies | The battle takes a list of enemies instead of one. Add target selection to the Attack/Act menu; on the enemy turn both enemies attack in the same dodge phase (patterns combined, slightly slower each). The battle is won when both are at 0 HP | Room 3 starts one battle with both enemies, you can pick who to hit, and beating one leaves the other fighting |
| 15 | Full run | Beaten enemies stay gone for the session, and doors stay open. Losing restarts you at the entrance of the current room with full HP and your ally. Reaching the end of room 3 shows a simple "The End" screen | A tester plays from the village to the end screen without help, once with each ally; tune the difficulty curve across the three fights |

## UI

Mockups in `design/Game UI Proposals.html`:

| Battle | Room / exploration |
|--------|--------------------|
| **A. Classic box (MVP)** — enemy top centre, HP bar, command row at bottom; dodge box appears mid-screen on enemy turn | **D. Top-down room, minimal HUD (MVP)** — HP and an interaction `!` |
| B. Side-view party — party left, enemies right, command panel bottom-left | E. Party trail with HUD — companions follow, dialogue bubble, `E` to talk |
| C. Touch-first (phone landscape) — big bottom buttons, on-screen MOVE stick, small centred dodge box | F. Touch-first walking (phone landscape) — MOVE stick, TALK button |

MVP uses **A + D**, plus the `TALK` button / `E` prompt and a simple ally follow (not the full party trail) from E/F for the village. Check every layout against C/F, since Roblox is heavily played on phones.

**Player avatar:** in rooms the player is their own Roblox avatar. In battle the player is still the heart in the dodge box (as in Undertale), and the `YOU 14/20` panel shows the player's avatar headshot (`Players:GetUserThumbnailAsync`) next to their name. In the party-trail layout (E), companions follow the avatar.

Rules for all layouts:
- Text at least 18 px.
- Buttons at least 44 px tall.
- Keep the bottom corners free for the mobile thumbstick.

## Enemy roster

Enemies are well-known Roblox avatars, built in code from a `HumanoidDescription` (body colours plus catalog asset IDs) via `Players:CreateHumanoidModelFromDescription`. Each enemy's data table picks its rig type (R6 or R15): e.g. the Noob as a classic blocky R6, the bundle-based characters as R15. They stand in the room and in the battle arena, so the battle camera shows the actual avatar. Look up each catalog/bundle asset ID once and keep it in the enemy's data table; if an item is ever removed from the catalog, fall back to body colours only.

| Enemy | Look | Where | Attack pattern idea (dodge phase) |
|-------|------|-------|-----------------------------------|
| **Builderman** | Hard hat, construction outfit | Room 1 (weakest) | Slow, wobbly bricks falling from the top (teaches dodging); bricks building walls across the box with one gap to slip through; a "build" sweep from the side |
| **Headless Horseman** | Headless Horseman bundle | Room 3 (with Korblox) | Flying pumpkins that bounce off the box edges |
| **Korblox Deathspeaker** | Korblox Deathspeaker bundle (skeletal leg, crown) | Room 3 (with Headless) | Bone spears thrust in from the sides on a rhythm |
| **Bacon girl** | Default-style avatar with the bacon hair | Room 2 (stronger, assumed) | Bacon strips zig-zagging across the box |
| **Shadow master** | Black ninja outfit | Later (Party slice / World) | Shuriken that fly straight, then curve toward the heart |

Room 3 pairs the two "rare" avatars as the final fight. Shadow master waits for the next phase; he's a good candidate for a recruitable enemy later, e.g. making the heart briefly invisible to bullets.

## Allies

Allies are built the same way as enemies (a `HumanoidDescription` and rig type in their own data module, e.g. `src/shared/Allies/`). The Noob's look moves from `src/shared/Enemies/Noob.luau` to an ally module (steps 8 and 11). The team holds up to **3 allies** at once (`Config.MaxTeamSize`); to recruit another, one goes back to the village. In battle, one ALLY button lists the team's abilities.

| Ally | Look | How to recruit | Battle ability (from the nephew) |
|------|------|----------------|-----------------------------------------------------|
| **Noob** | Classic yellow head and arms, blue torso, green legs (R6) | Your childhood friend. Talk to him and say yes; no quest | **Shaken cola:** shakes a cola bottle that explodes and damages **up to 2 enemies** at once. Usable any turn, no cooldown (assumed), so its damage is lower than a good timing-bar hit. Shines in room 3's two-enemy fight |
| **Elliot** | Pizza delivery guy: red cap, red shirt, black trousers (R15). Look up catalog IDs once; body colours as fallback | He's hungry. Find the *Pizza slice* in a chest in the village and give it to him | **Hot pizza:** throws a hot pizza slice at one enemy. It hurts on the turn it's thrown and again the next turn (2 rounds of burn damage). Cooldown: 3 rounds |

Using the ability is the player's action for that turn, instead of ATTACK or ACT (assumed). Damage numbers are set in each ally's data module and tuned in playtests; burn damage ticks at the start of the enemy's turn and shows as a damage number.

## Roadmap

Don't start a phase until the previous gate is met.

1. **MVP combat** (steps 0–12). Gate: a first-time tester finishes all three rooms unaided and wants to play again.
2. **Party slice.** Recruiting enemies by fighting or acting, and two or three companions with distinct abilities, using the MVP rooms. Gate: players pick different tactics depending on who is in the party.
3. **World.** More rooms beyond the village and the first three, more villagers and dialogue, secrets, the nephew's characters and art. Gate: a ten-minute playthrough with a beginning and an end.
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
- [x] ~~Who is room 1's enemy?~~ **Builderman** moves to room 1; the Noob is now an ally in the village.
- [x] ~~How many allies, and how do you get them?~~ Two in the village: the **Noob** (childhood friend, joins freely) and **Elliot** (pizza delivery guy, needs a pizza slice from a chest). Both can join: a **team of up to 3**; to recruit more, send one back to the village. One ALLY button in battle.
- [ ] Room 2's enemy now that Builderman moved to room 1: **Bacon girl** (assumed), Shadow master, or someone else?
- [x] ~~Ally abilities?~~ Noob: **Shaken cola**, explodes and damages up to 2 enemies. Elliot: **Hot pizza**, hurts one enemy for 2 rounds, cooldown 3 rounds.
- [ ] Noob's cola: really no cooldown (assumed, "at any time"), and how much damage compared to a normal attack? Does using an ability replace the player's attack that turn (assumed)?
- [ ] Village: other villagers, or just the two allies and the chest (assumed)? Does it have a name?
