# PLAN

An Undertale-inspired Roblox game with a Pokémon-like world. The player explores an **open world** as **their own Roblox avatar** (random fights off the roads, some enemies blocking the way) and starts in a **small village**, where they can build a **team of allies** (up to 3 at once): the **Noob** (their childhood friend, joins straight away) and **Elliot** (a hungry pizza delivery guy, joins once you bring him a slice of pizza from a chest). Each ally has an unusual ability that changes how encounters play (not just more damage). Later, befriended enemies can join the party too.

Source material lives in `design/`:
- `design/Roblox Undertale-Style Game MVP Plan.pdf` — the original plan (Nov 1, 2026). This file summarises it.
- `design/Game UI Proposals.html` — six UI mockups (open in a browser; it unpacks itself with JavaScript).

## Current status

- [x] Concept and MVP scope agreed
- [x] UI mockups drafted (A–F)
- [ ] Built, **waiting for a Studio Play test** (Nov 15, 2026):
  - Step 8 (part): Builderman (`src/shared/Enemies/Builderman.luau`, R15, body colours only for now) replaces the Noob in room 1; block patterns re-coloured as bricks. Still to do in step 8: enemy HP bar, proper win/lose screens
  - Step 10 (rooms since replaced by the world): village (`src/shared/Rooms/Village.luau`) south of room 1 with open doors between them; the player spawns there. `RoomBuilder` now does open doors, decorations (houses, path) and chests
  - Step 11: Talk/Open prompts (Roblox `ProximityPrompt`: E key, gamepad, tap). `src/client/Village.luau` runs recruiting and the pizza quest, `Dialogue.luau` the text box with Yes/No, `Party.luau` + `AllyFollow.luau` make the ally follow your path
  - Team (Nov 15): both allies can join; max 3 in the team (`Config.MaxTeamSize`). Recruiting a 4th asks who goes back to the village (they return to their spot and can be recruited again). Allies walk in a line behind you
  - Step 12: one ALLY command button opens a list of the team's abilities (COLA / PIZZA, with turns left while cooling down; skipped with one ally), `& Noob, Elliot` in the HUD; ability and burn logic in `BattleLogic`, numbers in `src/shared/Allies/`
- [ ] Built, **waiting for a Studio Play test** (Nov 15, 2026, second batch):
  - Builderman tougher: HP 30, ATK 5
  - Two-enemy battle pulled forward from step 14 (rooms since replaced by the world): `src/shared/Rooms/Room2.luau` (north of room 1) has **two Buildermans** (placeholders) in one encounter `Group`; touching either starts one battle against both ("Builderman A/B", side by side in the arena, different patterns at 0.75 speed). Room 1's north door opens once Builderman is beaten (`OpensWhenCleared`, the step 13 door rule)
  - Turn clarity: command buttons are grey unless you can pick one; a blinking ▼ shows when a message waits for a confirm (battle and village)
  - Village prettier, still plain Parts: materials (grass, cobblestone, brick, slate, wood), cottages with doors/windows/stepped roofs/chimneys, trees, bushes, flower beds, glowing lamp posts, a well, a village square
- [ ] Built, **waiting for a Studio Play test** (Nov 15, 2026, third batch): **rooms replaced by an open world** (the nephew's wish)
  - `src/shared/World/`: map in `init.luau`, villages `StartVillage.luau` + `Hamlet.luau`, prop helpers `Props.luau`, area questions `Areas.luau`; built by `src/server/WorldBuilder.luau` with **Terrain** (grass, dirt roads, water, rock) plus Parts (houses, trees, bridge, fences)
  - 320 × 400 studs: start village (south) → road north → river with one bridge (**Builderman** blocks it) → meadows with a side road to the **Hamlet** (second village) → rocky ridge with one gap (**two Buildermans** guard it) → pine forest (north)
  - Borders: cliffs north, low cliffs south (so the camera never loses you), **sea with a beach** east, **thick forest** west; invisible walls on every edge and along the river banks
  - **Random fights** anywhere except roads and villages (`src/client/RandomEncounters.luau`; `Config.RandomEncounter*`: 5% per 4 studs, 40-stud grace after a fight). Pools in `World.DefaultPool` / `World.Zones` (the forest has more pairs). "* A wild Bacon girl appears!"
  - **Bacon girl** added as a wild enemy (body colours only for now; patterns BaconZigzag, BaconSweep)
  - Losing sends you back to the **last village you visited** (`src/client/Checkpoint.luau`)
  - Removed: `src/shared/Rooms/`, `RoomBuilder`, doors that open when a room is cleared
- [ ] Built, **waiting for a Studio Play test** (Nov 15, 2026, fourth batch): **gold and a sword shop**
  - Damage retuned: player ATK 6 → 4; COLA 3 → 5 per enemy, PIZZA 5 → 8 (and 8 burn)
  - Winning gives **gold** by chance: each enemy's `Reward` (GoldChance, GoldMin–GoldMax) in its data file; Builderman 75% of 4–9, Bacon girl 60% of 1–5. Can be 0 ("No gold this time.")
  - **Market stall** in the start village (`Props.stall`, sign + prompt in `WorldBuilder`) sells swords from `src/shared/Items/Weapons.luau`: **Iron sword**, ATK +3, 25 gold. You start with a Stick (+0)
  - **Bandages** (`src/shared/Items/Supplies.luau`): 6 gold, heal 8 HP, carry up to 9; also sold at the stall. New **ITEM** battle button (ATTACK, ACT, ITEM, ALLY); using one takes your turn. HP still resets to full at each fight start (decided Nov 15)
  - **Loot chests** with 5–15 random gold at four spots off the roads (`World.LootChests`), same chest look
  - Gold, sword and bandages in `src/client/Progress.luau` (this session only, no saving); top-right HUD shows them (`src/client/Hud.luau`)
  - Ground fix: everything is stood on the measured terrain surface (`src/shared/World/Ground.luau`), after waiting for new terrain to be hittable
  - Chest restyled: plank body, metal bands, gold lock, stepped lid that swings open
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

**Done when:** a tester can start in the village, recruit allies, cross the world (random fights on the way), beat the bridge and forest-gate fights, and reach the forest without any explanation.

**In:** one open world (see the map in `src/shared/World/init.luau`), one player, and battles with menu, attack, dodge phase, HP, win and lose:

| Place | Enemies | Purpose |
|-------|---------|---------|
| Start village | none: two possible allies (**Noob**, **Elliot**) and a chest with pizza | Start of the game. Talk to people and recruit allies (Noob straight away, Elliot after the pizza quest). Safe: no random fights |
| Meadows (south of the river) | random: **Builderman**, **Bacon girl** | Learn the basics: menu, timing bar, dodging, your allies' abilities |
| Bridge | fixed: **Builderman** blocks it | The only way north: a fight you can't skip |
| Hamlet (east, side road) | none | A second safe village; losing after you've visited it restarts you here |
| Ridge gap (forest gate) | fixed: **two Buildermans** in one battle | Choosing a target, and dodging two enemies' attacks at once |
| Forest (north) | random, harder: mostly pairs | The end of the MVP world |

**Also in:** gold from fights and loot chests, and a shop that sells a better sword and bandages (used in battle).

**Out for now:** experience and levels, recruiting enemies after a fight, saving, an inventory beyond your sword (the pizza is a single quest flag), NPCs beyond the two allies, branching dialogue, running from fights, multiplayer, final art. The ground is Roblox Terrain and props are plain Parts; the player is always their own avatar; enemies and allies are classic Roblox avatars (see the rosters below).

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
| 10 | Village | Start village with houses and a gate; the player spawns there. Place the Noob, Elliot and a chest as interactables | You spawn in the village and can walk around it with an R6 and an R15 avatar |
| 11 | Recruit allies | Walk up to someone or something → `!` prompt (layout D) and a TALK button / `E` (layouts E, F). A short dialogue box, no branching beyond yes/no. **Noob:** "It's me, your old friend! Can I come?" → Yes = joins. **Elliot:** "I'm sooo hungry..." until you open the chest (you get a *Pizza slice*), then "Pizza! I'll come with you!" → Yes = joins. The team holds at most 3; recruiting a 4th asks who goes back to the village. Allies follow the player in a line (simple scripted follow, anchored rig, no player movement) · allies only appear in battle | You can recruit the Noob and (after the pizza quest) Elliot; both follow you out of the village |
| 12 | Ally in battle | The team shows in the HUD next to `YOU` (layout A) and one ALLY menu option lists their abilities (see Allies below). Ability logic lives in the ally's data module and plugs into `BattleLogic` hooks, no UI calls | Each ally's ability visibly changes how a fight plays; fights are still winnable without them |
| 13 | Open world | Replace the rooms with one world built from code (Terrain + Parts): villages, roads, river + bridge, ridge + gap, forest; borders of cliffs, sea and forest with invisible walls. Fixed enemies block the bridge and the gap | You can walk from the start village to the forest, can't leave the map or swim the river, and must beat the bridge fight to cross |
| 14 | Random fights and two-enemy battles | Random fights anywhere except roads and villages, picked from weighted pools per zone; wild enemies shown from templates. Battles take a list of enemies: target selection, both attack in one dodge phase (each pattern at 0.75 speed). Losing restarts you at the last village visited | Random fights happen at a pace that feels fun, not annoying; the forest gate is one battle against two Buildermans |
| 15 | Full run | Beaten fixed enemies stay gone for the session. Reaching the forest shows a simple "The End" screen | A tester plays from the village to the end screen without help, once with each ally; tune encounter rate and difficulty |

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
| **Headless Horseman** | Headless Horseman bundle | Later: forest gate guard (with Korblox)? | Flying pumpkins that bounce off the box edges |
| **Korblox Deathspeaker** | Korblox Deathspeaker bundle (skeletal leg, crown) | Later: forest gate guard (with Headless)? | Bone spears thrust in from the sides on a rhythm |
| **Bacon girl** | Default-style avatar with the bacon hair (hair asset ID still to look up) | Random fights everywhere | Bacon strips zig-zagging and bouncing (BaconZigzag), wiggling strips sweeping in from the sides (BaconSweep) |
| **Shadow master** | Black ninja outfit | Later (Party slice / World) | Shuriken that fly straight, then curve toward the heart |

The two "rare" avatars could replace the Buildermans at the forest gate as the big fight. Shadow master waits for the next phase; he's a good candidate for a recruitable enemy later, e.g. making the heart briefly invisible to bullets.

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
- [ ] Enemy order: Noob → Builderman → Headless Horseman + Korblox (assumed). Swap any of them with Bacon girl or Shadow master?
- [x] ~~Who is the first enemy?~~ **Builderman**; the Noob is now an ally in the village.
- [x] ~~How many allies, and how do you get them?~~ Two in the village: the **Noob** (childhood friend, joins freely) and **Elliot** (pizza delivery guy, needs a pizza slice from a chest). Both can join: a **team of up to 3**; to recruit more, send one back to the village. One ALLY button in battle.
- [x] ~~Rooms or open world?~~ **Open world** with villages, random fights off the roads (Pokémon-like) and fixed enemies blocking passages; borders of cliffs, sea and forest.
- [ ] Which enemies guard the bridge and the forest gate in the end (Headless Horseman + Korblox for the gate, as planned)? Names for the villages, the river and the forest?
- [ ] Running away from random fights (a RUN button, like Pokémon)?
- [ ] More things in the shop (better swords, healing items, armour)? Prices? Experience/levels were dropped for now (Nov 15).
- [x] ~~Ally abilities?~~ Noob: **Shaken cola**, explodes and damages up to 2 enemies. Elliot: **Hot pizza**, hurts one enemy for 2 rounds, cooldown 3 rounds.
- [ ] Noob's cola: really no cooldown (assumed, "at any time"), and how much damage compared to a normal attack? Does using an ability replace the player's attack that turn (assumed)?
- [ ] Village: other villagers, or just the two allies and the chest (assumed)? Does it have a name?
