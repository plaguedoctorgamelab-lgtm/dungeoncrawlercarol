# Dungeon Crawler Carol: Lair of The Sea Lord

A 1990s Genesis-style 2.5D isometric turn-based tactical RPG made in **Godot 4.7** (GDScript).
Carol fights through four elemental realms of corporate monsters to rescue her girlfriend,
Princess Penny, from the Sea Lord's underwater boardroom.

![Title](docs/screenshots/01_title.png)

| Overworld | Tactical battle | Final boss |
|---|---|---|
| ![Overworld](docs/screenshots/02_overworld.png) | ![Battle](docs/screenshots/03_battle_realm1.png) | ![Sea Lord](docs/screenshots/03_battle_realm4.png) |

## Play it

* **Windows:** download `releases/DungeonCrawlerCarol_V2_Windows.zip`, unzip, run `DungeonCrawlerCarol_V2.exe`.
* **From source:** open this folder in Godot 4.7 and press F5.

### Controls

| Input | Action |
|---|---|
| Left-click a highlighted tile | Move (1 AP per tile) |
| Left-click an enemy | Attack with the equipped weapon |
| `1`-`4` or weapon buttons | Switch weapon (free) |
| `H` or Drink button | RADICAL Energy Drink: +35 HP for 1 AP |
| `E` / Space / Enter or End Turn | End your turn |

Hover an enemy to see your hit chance, its HP and its flavor text.

## What's in the game

* **Title screen** with 4 difficulties (Easy, Medium, Hard, EXTREME!!!!!!) and 3 save slots.
* **Overworld:** a procedural branching node map per realm (15-20 nodes). Node types are
  Combat, Hazard (random HP loss, item, or shortcut), Supply Cache (a guaranteed weapon or drink) and Boss.
  The boss always spawns in the final 25% of nodes, and every path leads to it.
* **Tactical battles** on an isometric `TileMapLayer` grid with `AStarGrid2D` pathfinding and a 4 AP turn
  economy. Turns go Player Phase, then Enemy AI Phase.
* **Hit chance** = `max(30%, base - distance x 5%)`, with a melee base of 95% and a ranged base of 85%.
  Line of sight uses a `RayCast2D`, and vending machines block shots (0%).
* **Fog of war:** your sight radius depends on difficulty. Enemies stay hidden until you can see them, and
  an enemy that attacks from the dark is revealed.
* **Projectiles:** static sprites that fly at 400 px/s before damage resolves. Each ranged monster has its own.
* **The roster:** all 24 monsters and 4 bosses (HOA President Golem, Smug Vape Cloud, Burnout CEO Fire Demon
  and The Sea Lord), plus 4 weapons: Neon Star-Sword, Super Soaker 9000, Squeaky Mallet and Contractor Nailgun.
* **Rescue ending:** beating the Sea Lord breaks Penny's cage and plays the victory screen.
* **Saves** are JSON in `user://savegame.json` (slot 1) and `savegame_2/3.json`. Easy and Medium can save at
  every node, Hard only at the start of each realm, and EXTREME wipes the save on death and restarts at Level 1.

## Project layout

```
assets/sprites/        game-ready pixel art (+ generated 32x16 iso floor tiles)
scenes/overworld/      OverworldMap, NodeButton, OverworldGenerator
scenes/tactical/       TacticalBattle, IsometricGrid, GridOverlay, Projectile, CombatMath
scenes/units/          CarolUnit, EnemyUnit, PrincessPenny (BattleUnit base)
scenes/items/          TacticalDrop
scenes/ui/             TitleScreen, TacticalHUD, SaveMenu, VictoryScreen
scripts/autoload/      GameState, SignalBus, SaveSystem
scripts/resources/     WeaponData, EnemyData (custom Resources)
scripts/data/          Roster.gd - the stat tables everything is generated from
scripts/tests/         run_unit_tests.gd (headless)
scripts/tools/         asset pipeline, .tres generator, screenshot tool
resources/weapons/     4 weapon .tres
resources/enemies/     24 enemy .tres
docs/                  design document, art manifest, screenshots
```

## Build and test

```bash
godot --headless --import
godot --headless --script res://scripts/tests/run_unit_tests.gd
godot --headless --export-release "Windows Desktop" builds/DungeonCrawlerCarol_V2.exe
```

The test runner boots into the title screen, starts a new game, generates 100 overworld maps, plays
a mock tactical turn (move, attack, drink, enemy phase, victory), fights all 4 bosses including the Penny
rescue, and checks save/load and the permadeath wipe. There are 98 checks, and the process exits with the
number of failures.

To change monster stats, edit `scripts/data/Roster.gd` and run
`godot --headless --script res://scripts/tools/generate_resources.gd`.

## Notes and deviations from the design document

* Fast monsters (the mower, bats, imps and bug) move 2 tiles per AP. Armored tanks ignore part of incoming damage.
* Each monster attacks at most once per turn so that 4 AP enemy squads stay survivable.
* Carol deals +20% damage per realm cleared. She heals 15 HP after each fight and fully between realms.
* Crates block movement only. Vending machines block both movement and line of sight. Spike traps deal 8 damage.
* The `ui_hit_chance_badge` art has "85%" baked in, so the HUD shows the live number as text instead.
