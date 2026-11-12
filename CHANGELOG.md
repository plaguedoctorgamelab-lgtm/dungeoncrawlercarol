# Changelog

Version numbers follow `MAJOR.MINOR.PATCH`.
- The current version lives in `project.godot` (`application/config/version`).
- It's shown on the title screen and in the pause menu, and stamped into the Windows `.exe` properties.
- Every release is tagged in git as `vX.Y.Z`.

## v0.8.0 — 2026-11-12: "The Air Realm Takes Off"

All of Art Pack 3 is imported.
- **Air monsters are frame-animated:** Crypto Bro Bat, Bored JPEG Ape, Drop-Shipper Drone, 5 AM Grindset Gargoyle and Ad-Tech Ghost. Each has a 2-frame idle loop, an attack pose and a hurt flinch.
- **Smug Vape Cloud** (realm 2 boss) has six frames:
  - idle (2 frames)
  - a puffed-up neon **wind-up** on its CHARGING turn
  - a vapor-ring blast
  - hurt
  - a **defeated** sad little puff it shrinks into
- **Carol's dash and shove poses.** Every action Carol has now plays a real frame:
  - idle
  - walk
  - dash
  - sword attack
  - shoot
  - shove
  - drink
  - hit
  - dodge
  - down
  - victory
- **Air realm cover:** crypto-mining rig stacks (half cover) and glowing server racks (full cover), mixed with the crates and vending machines.
- Importer fix: a partial Carol delivery now takes its size from an upright pose (shove), not a crouch (dash), so new poses match her existing frames.
- 221 tests.

## v0.7.0 — 2026-11-12: "Slime Fix"

- **Rooms per level cut by 15%:** 26–34 rooms instead of 30–40, still about 1.7× the original 15–20. Cover stays spread out.
- **The Landlord Slime is solid again.** The old green-screen removal treated any strongly green pixel as background, so it erased most of the green slime, which played as almost fully transparent.
  - The importer now reads the background colour from the image corners (it supports both #00FF00 green and #FF00FF magenta).
  - It only removes pixels that match that colour closely *and* are connected to the image border (a flood fill), plus near-exact matches in enclosed gaps.
  - Green characters like the slime and the zombie intern now keep their colours.
  - Art Pack 2 has been re-imported with it.
- **Art Pack 3 spec** (Air realm) added: `docs/art_brief_pack3.md`. It asks for a magenta background for any green subject.

## v0.6.0 — 2026-11-12: "Earth Comes Alive"

### Art Pack 2
- **Monster frame animation** for the whole Earth realm: Landlord Slime, Karen's Turbo Mower, Unpaid Intern Zombie, Mall Cop Mercenary and Tax Auditor Mole.
  - Each monster has 2 idle frames, an attack pose and a hurt flinch.
  - Idle loops are staggered so a squad doesn't breathe in sync.
  - Monsters strike their attack pose when they attack, and flinch when hit.
- **HOA President Golem** (realm 1 boss) has six frames:
  - idle (2 frames)
  - a raised FINED gavel **wind-up frame**, shown during its CHARGING turn
  - slam attack
  - hurt
  - a **defeated** rubble-pile frame it crumbles into when beaten
- **Carol's drink and dodge poses** now play when she chugs an Energy Drink or dodges a miss.
- **Earth realm cover:** dented trash cans (half cover) and HOA privacy fences with a peeking gnome (full cover) are mixed in with the crates and vending machines.
- `import_art.gd` now also imports:
  - monster frame sets (`enemies/<id>/`), aligned on a shared foot point, with a `frames.json` per monster
  - partial Carol deliveries

### Maps and rooms
- **Twice as many rooms per level:** 30–40 nodes per realm, up from 15–20, in columns of 2–4. The boss is still alone in the last column.
- **Cover is spread out.** Rooms are split into 3×3 blocks, and each block gets at most one prop, placed so it never touches another prop, not even diagonally. Traps and espresso machines don't clump either. Measured: 0 touching props across sample rooms, which used to be clusters by design.

### Balance note
- With cover spread out, early fights are a little easier: the bot wins about 100% of Medium Earth fights in about 5 turns. But a run now has about twice as many fights, so HP and Energy Drinks wear down more over a realm. Worth a playtest before re-tuning.

- 217 tests.

## v0.5.0 — 2026-11-12: "New Art"

The first round of art made from `docs/art_brief.md` is now in the game.

- **Carol now has frame-by-frame animation**, 20 frames in all:
  - idle (3 frames, ping-pong)
  - walk (6)
  - sword attack (wind-up, swing, strike, recover)
  - shoot (aim and recoil)
  - hit (2)
  - knocked down (2)
  - victory
- The procedural motion (hops, squash, swipe trail, afterimages) still plays on top of the frames, with smaller tilts.
- Every frame is aligned on a shared foot point, so she doesn't jitter between poses. Her idle pose is also the new HUD portrait.
- **New props in true 2:1 isometric:** the wooden crate, the vending machine (now facing front-left) and the Overheated Espresso Machine. Props are now scaled to the tile width with their front corner on the tile's bottom corner, so they sit square on the grid.
- **New trap tiles:** spikes, live wire (separate art for sparking and dark, with a flicker while live) and red tape.
- `scripts/tools/import_art.gd` imports an art delivery in one step:
  - removes the green background, with soft edges and green-spill cleanup
  - crops props and traps and scales them to the grid
  - normalizes Carol's frames onto one canvas, aligned by her feet
  - re-run it on any future delivery
- The procedural trap and espresso drawings remain as a fallback if any file is missing.
- 209 tests.

## v0.4.0 — 2026-11-12: "Traps & Drama"

### New traps
Each realm gets a different mix:
- **Earth:** spikes and red tape
- **Air:** spikes and live wires
- **Fire:** live wires and red tape
- **Water:** all three

The traps:
- **Live Wire:** downed cables that **spark on every other turn**, dealing 12 damage to anyone standing on or stepping onto one while it's live. Hover text says whether it's sparking now or next turn.
- **Red Tape:** a sticky tangle that **roots** whoever steps in it. They can't move again this turn, but can still attack.
- **Overheated Espresso Machine:** a half-cover prop that **explodes** for 25 damage to Carol and 32 to monsters on the 8 surrounding tiles.
  - It goes off if anyone hits it (Carol can click it with any weapon, and it can't miss) or a monster is **shoved into it**.
  - Explosions chain into neighbouring machines.
  - Monsters with guns will **shoot a machine next to Carol**.
- Every trap hurts monsters too, and the enemy AI routes around them.
- The new traps and the espresso machine are drawn procedurally so they fit the grid exactly until real art arrives (see `docs/art_brief.md`). If `trap_espresso_machine.png` is added, it's used automatically.

### Drama
- **NEW THREAT! card:** the first time a monster type appears in a run, a big card slams in with its portrait, name, role, stats and flavor line, plus a sound sting. Click or press any key to dismiss it; it also goes away by itself after 4 s.
- Bosses always get a **BOSS FIGHT!** card.
- Monster types you've already met just get a "spotted!" log line. Met monsters are saved with the run.
- **Enemy hover card:** hovering a monster shows a portrait card with its name, role, HP, damage, range, speed, armor and what it plans to do next turn.
- New sounds: zap, red tape, explosion and a new-enemy sting.

### Art pipeline
- `docs/art_brief.md`: exact image-generator prompts for obstacles, trap tiles and Carol's frame-by-frame animation.
- `docs/art_guides/*.png`: fit-guide templates, made by `tools/make_art_guides.py`.

### Project
- The test runner now fails if fewer checks run than expected, since a crashed test used to pass silently.
- Fixed a crash-in-waiting where a queued enemy card referenced a monster that had died.
- 208 tests.

## v0.3.0 — 2026-11-12: "Telegraphs & Tunes"

This release implements the immediate recommendations from both evaluations:
- the studio post-build audit: [docs/studio_audit_report.txt](docs/studio_audit_report.txt)
- the external evaluation: [docs/evaluation/](docs/evaluation/README.md)

The rename recommendation is intentionally skipped.

### Gameplay
- **Smarter enemies** (`scenes/tactical/EnemyAI.gd`, new):
  - Ranged monsters choose the firing spot that gives them the most cover from Carol and strips Carol's cover (flanking).
  - Melee monsters take the shortest route to a tile next to her.
  - Monsters only notice Carol with line of sight, or when she's within 2 tiles.
- **Telegraphed intents.** Every monster shows what it will do next turn:
  - red **!**: it will attack you where you stand
  - cyan **>**: moving
  - grey **?**: hasn't noticed you
  - yellow **CHARGING!**: boss
  - Hovering a move tile tells you how many visible monsters could hit you there, and what cover you'd have.
- **Boss charge attacks.** Bosses spend a turn CHARGING and lock onto Carol's tile, which is marked as a **red danger zone** (the tile plus its neighbours for ranged bosses). The heavy strike (×1.3 damage) lands next turn, and only hits if Carol is still in the zone.
- **Bosses path as a 2×2 block** (a breadth-first search over free 2×2 positions), so they no longer get stuck on cover.
- **Carol's new abilities:**
  - **Dash [Q]**: 1 AP, move up to 2 tiles, and the next attack on her gets −25% to hit. Once per turn.
  - **Shove [F]**: 2 AP. Pushes an adjacent monster 1 tile, onto spikes (−15 HP) or out of cover. If it hits a wall instead, it takes a 10-damage slam.
- **Contractor Nailgun** reworked to a rapid-fire weapon: 1 AP per shot, 13 damage.
- **Cover layout.** Cover is placed as deliberate "fighting positions" (L-shaped and line-shaped clusters with at most one vending machine) instead of scattered props.
- **Spike traps hurt monsters too** (15 damage).
- **Balance**, re-tuned with the auto-play sim:
  - Squads start at 3 monsters.
  - Carol gains +15 max HP per realm cleared (100 / 115 / 130 / 145).
  - HOA Golem: 200 HP / 32 damage.
  - The Sea Lord: 340 HP / 44 damage.
  - EXTREME sight is raised from 3 to 4.
- **Squeaky Foam Mallet guaranteed before the first boss.** Every second-column node in realm 1 is a supply cache, and realm 1's first cache always gives the Mallet.
- **The boss always sits alone in the final column of the map.** It is never mid-map with paths looping back to it.

### Fixes
- Highlighted move tiles near spikes could ignore the click, because the BFS range didn't match the weighted A* route. Movement now uses one Dijkstra plan for both. Measured mismatch went from 8–23 tiles per 40 rooms to **0**.
- Shooting through a vending machine next to the shooter. Line of sight now uses XCOM-style step-out: you can lean around cover from an open side tile, but not through a machine with no open side.
- Fog of war and enemy detection ignored line of sight. "Visible" tiles behind cover went from about 10% to **0**.
- A monster that attacked from the fog vanished again before Carol's turn. It now stays revealed through Carol's next turn.
- Battle rooms are now **seeded from the run**, so the same run and node always build the same room. This makes bugs reproducible and stops reload re-rolling.

### Saves and permadeath
- **Atomic saves.** Saves are written to `.tmp`, the old save is kept as `.bak` until the swap succeeds, and loads fall back to `.bak` if the main file is damaged.
- **Load validation.** Unknown weapon IDs in a save are dropped instead of crashing. The save format is now version 3, and it still reads version 2.
- **EXTREME auto-saves after every node.** Quitting mid-fight counts as a permadeath when you load.
- **Death on EXTREME wipes every slot holding that run.**

### Presentation
- **Carol animations.** These are procedural, built from her single sprite:
  - idle breathing
  - hop-walk with squash and stretch
  - facing her target
  - dash afterimages
  - attack wind-up, strike and neon sword-swipe
  - gun recoil
  - shove
  - hurt flinch
  - dodge sidestep
  - drink chug with bubbles
  - death fall
  - victory jumps
- **Hit juice:**
  - impact squash on any unit
  - monster death pop and spin
  - camera shake (can be turned off)
  - hit-stop on big hits
- **Audio**, all original and synthesized by `tools/synth_audio.py` (pure Python, nothing downloaded):
  - 23 sound effects
  - 6 looping chiptune tracks (title, Earth, Air, Fire, Water, boss)
  - victory and defeat jingles
- **Pause menu** (Esc on the map and in battle):
  - music and SFX volume
  - screen shake toggle
  - fullscreen
  - quit to title
  - the version number
- Settings are saved to `user://settings.cfg`.
- HUD: Dash and Shove buttons, with a right-click cancel. The How to Play screen is updated.

### Project
- Version numbering added: `0.3.0`, with the `.exe` file and product version set to `0.3.0.0`.
- `scripts/tools/autoplay_sim.gd`: the balance sim is now in the repo as a regression tool.
- `scripts/tools/audit_probe.gd` checks pathing consistency, cover and fog.
- The test suite grew from 152 to **190** checks.
- Release zips are no longer committed to git (see "Play it" in the README).

## v0.2.0 — 2026-11-12: V2 HD overhaul
- 1920×1080 fullscreen, HD sprites with SpriteScaler, 128×64 isometric grid, XCOM cover hit chances, 2×2 bosses, 15 tweened projectiles, How to Play screen.

## v0.1.0 — 2026-11-11: First playable
- The Godot 4.7 build from the design document: node map, tactical battles, 24 monsters, 4 bosses, saves, and Penny's rescue.
