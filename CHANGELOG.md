# Changelog

Version numbers follow `MAJOR.MINOR.PATCH`.
- The current version lives in `project.godot` (`application/config/version`).
- It's shown on the title screen and in the pause menu, and stamped into the Windows `.exe` properties.
- Every release is tagged in git as `vX.Y.Z`.

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
