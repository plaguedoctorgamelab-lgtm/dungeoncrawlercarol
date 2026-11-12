# Dungeon Crawler Carol: Lair of The Sea Lord - Game Design Document (V2)

## 1. Executive Summary & High Concept

* **Elevator Pitch:** *Dungeon Crawler Carol: Lair of The Sea Lord* is an irreverent, 1990s Sega Genesis-inspired 2.5D isometric turn-based tactical RPG in the spirit of *XCOM* meets *Zombies Ate My Neighbors*. Players guide Carol through 4 elemental realms of branching overworld node maps to rescue her girlfriend—Princess Penny, a kick-ass, tattooed, pink-haired barista who was kidnapped by the Sea Lord to force-power his corporate espresso machine. Carol battles through 24 smarmy, corporate, fascist cartoon monsters using neon magic star-swords, Super Soakers, and squeaky foam mallets.

* **Genre:** 2.5D Isometric Turn-Based Tactical RPG (XCOM-Lite)
* **Target Engine:** Godot 4.x (GDScript)
* **Target Platform:** PC Desktop (Windows 10/11)
* **Visual Vibe & Aesthetic:** Vibrant 1990s 16-bit arcade pixel art with bright neon palettes, 30-degree isometric angle projection, sharp black outlines, and irreverent 12-year-old geek boy humor. Zero real-world firearms—all attacks utilize toy blasters, magic slashes, energy blasts, or goofy flying projectiles.

---

## 2. Scope Boundaries & Non-Goals

*The AI agent MUST NOT implement any feature on this list unless explicitly instructed.*

* [ ] **No Real-Time Action Combat:** Combat is strictly turn-based with an Action Point (AP) pool per turn.
* [ ] **No Camera Rotation or Free Movement:** The isometric 2.5D camera remains fixed at a diagonal top-down perspective ($30^{\circ}$ angle projection).
* [ ] **No Multi-Tier Cover Grid Penalty:** Accuracy is calculated purely via range, Line of Sight (LOS), and unit hit stats without dynamic cover penalty calculations.
* [ ] **No Sprite Animations:** All units, projectiles, and environmental objects use static 1-frame isometric pixel art sprites.
* [ ] **No 3D Models or Custom Shaders:** Built strictly using 2D Canvas layers, `TileMapLayer`, and `Sprite2D` nodes.

---

## 3. Story, Level Progression & Overworld System

### 3.1 Narrative Premise
The evil Sea Lord has kidnapped Princess Penny—a badass barista princess with neon-pink hair and sleeve tattoos—to corner the global market on corporate drip coffee and eliminate artisan espresso. Carol must traverse four elemental realms to storm the Sea Lord's boardroom cage and rescue her girlfriend.

### 3.2 The 4 Elemental Realms
1. **Level 1: Earth Realm** – Corporate Suburbs & HOA Dungeons
2. **Level 2: Air Realm** – Cloud-High Vaping Towers & Crypto Mines
3. **Level 3: Fire Realm** – Venture Capitalist Lava Mansions
4. **Level 4: Water Realm (Lair of The Sea Lord)** – Submerged Underwater Boardroom

### 3.3 Overworld Node Map Navigation
* **Node Count:** 15–20 branching nodes per level (resembling a *Slay the Spire* style tree map).
* **Node Types:**
  * **Combat Node:** Triggers a tactical isometric grid battle against level-appropriate smarmy enemy squads.
  * **Hazard Node:** Quick-click risk event (loss of HP, item reward, or shortcut path).
  * **Supply Cache Node:** Guarantees a weapon or health consumable drop.
  * **Level Boss Node:** Spawns randomly within the **final 25% of nodes** on the map (nodes 12 to 15+).
* **Level Clear Condition:** Defeating the Level Boss instantly concludes the level. Defeating the final boss (The Sea Lord) on Level 4 breaks Princess Penny's cage, triggering the victory splash screen.

---

## 4. Tactical Combat Mechanics, Math Formulas & Projectiles

### 4.0 V2 HD Display Spec (1920x1080 Fullscreen)
The V1 32x16 grid rendered too small on modern monitors. V2 renders everything at Full HD:

| Setting | Value |
| :--- | :--- |
| Viewport | `1920 x 1080`, `display/window/size/mode = 3` (fullscreen on boot) |
| Stretch | `canvas_items`, aspect `keep` |
| Texture filter | `Linear` (`default_texture_filter = 1`) for crisp high-res cartoon art |
| Fullscreen toggle | `F11` (handled in `GameState.gd`, `DisplayServer.window_set_mode()`) |
| UI | Laid out on a 1280x720 design grid and scaled x1.5; MSDF fonts keep text sharp |

**Battlefield footprints** (applied by `scripts/util/SpriteScaler.gd`, which reads each texture's size and scales it uniformly, bottom-center anchored to the tile center):

| Entity | On-screen footprint |
| :--- | :--- |
| Carol, Princess Penny, regular enemies (1x1 tile) | `128 x 128 px` |
| Level bosses (2x2 tiles) | `256 x 256 px` |
| Half cover (crates) | `128 x 128 px` |
| Full cover (vending machines) | `128 x 192 px` |
| Projectiles and pickup drops | `56 x 56 px` |

Missing PNGs fall back to procedural placeholder textures, so the project always boots with zero missing-resource errors.

### 4.1 Grid & Projection Specs
* **Tile Grid:** Isometric `TileMapLayer` (`TILE_SHAPE_ISOMETRIC`, diamond-down layout) with **`tile_size = Vector2i(128, 64)`**.
* **Room size:** `10x10` to `12x12` tiles (boss rooms `12x12`). The whole room fits the centre of the 1920x1080 screen under a **fixed, non-moving `Camera2D`** at zoom 1, with margins for the HUD bars.
* **Depth sorting:** `y_sort_enabled = true` on the battlefield root and on the Objects layer, so units, cover props and projectiles sort correctly in 2.5D.
* **Texture Filtering:** Linear (V2). The V1 Nearest Neighbor setting was for 32x32 pixel sprites.
* **Fog of War:** Tiles outside Carol's vision radius are shrouded in darkness. Enemies remain invisible until entering Carol's sight radius.

### 4.2 Turn Economy & Action Point (AP) Pool
Carol and enemies operate on a **4 AP Pool per turn**:

| Action | AP Cost | Technical Description |
| :--- | :--- | :--- |
| **Grid Movement** | `1 AP` / tile | Moves unit 1 tile along calculated `AStarGrid2D` path. |
| **Melee Attack (Star-Sword)** | `2 AP` | Strikes an adjacent grid tile. |
| **Ranged Weapon Attack** | `2 AP` | Spawns a tweened projectile directed at a target grid coordinate. |
| **Special / Consumable (Radical Energy Drink)** | `2 AP` (specials `2-3 AP`) | Restores 35 HP. |

### 4.3 Accuracy & Line of Sight (LOS) Formulas
V2 uses XCOM-style cover. The hit chance depends on the cover the target has against the attacker:

| Target's cover | Hit chance |
| :--- | :--- |
| Open ground (no cover) | `85%` |
| Half cover (crates, trash cans) | `60%` (-25%) |
| Full cover (vending machines, walls) | `35%` (-50%) |
| No line of sight | `0%` (can't shoot) |

* **Cover rule:** a cover object on a tile next to the target, on the side facing the attacker. Cover on the far side does nothing (flanking).
* **Line of Sight (LOS):** Casts a `RayCast2D` from center-of-tile to center-of-tile against full-cover blockers. Cover hugging the shooter or the target gives cover instead of blocking the shot.
* **Melee** hits an adjacent tile and ignores cover (85%).
* **HUD badge:** hovering an enemy shows a floating neon badge (`85% HIT`, `60% HIT`, `35% HIT`).
* Enemies use the same rules against Carol.

### 4.4 Projectile & Visual Attack Effect System
When a ranged attack is executed, a static `Sprite2D` projectile travels along a linear path from the attacker to the target cell at a fixed speed of $400.0$ pixels/second before triggering damage resolution.

| Projectile ID | Associated Attacker / Weapon | Sprite Visual Description |
| :--- | :--- | :--- |
| `proj_star_slash` | **Neon Star-Sword** | Crescent-shaped glowing neon-pink energy wave with star sparkles. |
| `proj_water_stream` | **Super Soaker 9000** | Stream of neon-blue water droplets with cartoon splash droplets. |
| `proj_steel_nail` | **Contractor Nailgun** | Industrial yellow-gold metal nail with speed lines. |
| `proj_tax_receipt` | **Tax Auditor Mole** | Unspooling long paper tax receipt. |
| `proj_megaphone_wave` | **Mall Cop Mercenary** | Concentric yellow soundwave rings. |
| `proj_crypto_coin` | **Crypto Bro Bat** | Spinning glowing golden crypto coin. |
| `proj_amazon_box` | **Drop-Shipper Drone** | Falling brown cardboard box with red question marks. |
| `proj_ad_popup` | **Ad-Tech Ghost** | Glitchy red pop-up advertisement banner reading "BUY NOW!". |
| `proj_vape_ring` | **Smug Vape Cloud (Boss)** | Thick purple-pink smoke doughnut ring. |
| `proj_bug_report` | **Crunch Time Imp** | Sheet of paper on fire with a black beetle icon. |
| `proj_pie_chart` | **Slide-Deck Mini-Dragon** | Spinning 3D pie chart with glowing green/orange slices. |
| `proj_pink_slip` | **Layoff Executioner / CEO** | Burning pink termination slip paper. |
| `proj_water_squirt` | **Sea Men Grunt** | Three small cartoon water drops squirting forward. |
| `proj_dollar_lure` | **Anglerfish Lobbyist** | Floating green dollar bill attached to a fishing hook. |
| `proj_trident_beam` | **The Sea Lord (Final Boss)** | Thick glowing golden energy beam shot from trident. |

### 4.5 Master Entity & Character Roster

| Level / Category | Entity Name | Class / Role | Max HP | AP / Turn | Base Damage | Sight Radius |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Hero** | **Carol** | Player Unit | `100.0` | `4 AP` | Variable | Based on Difficulty |
| **Objective NPC** | **Princess Penny** | Tattooed Barista Princess | N/A | N/A | Rescue Objective | Rescued in Level 4 |
| **Level 1: Earth** | **Landlord Slime** | Melee Swarm | `35.0` | `4 AP` | `10.0` | `6 tiles` |
| | **Karen's Turbo Mower** | Fast Charger | `45.0` | `4 AP` | `14.0` | `7 tiles` |
| | **Unpaid Intern Zombie** | Swarm Melee | `25.0` | `4 AP` | `8.0` | `5 tiles` |
| | **Mall Cop Mercenary** | Ranged Shooter | `40.0` | `4 AP` | `12.0` | `8 tiles` |
| | **Tax Auditor Mole** | Ground Disruptor | `30.0` | `4 AP` | `9.0` | `6 tiles` |
| | **HOA President Golem** | **LEVEL 1 BOSS** | `160.0` | `4 AP` | `24.0` | `8 tiles` |
| **Level 2: Air** | **Crypto Bro Bat** | Fast Flier | `30.0` | `4 AP` | `11.0` | `7 tiles` |
| | **Bored JPEG Ape** | Melee Brawler | `50.0` | `4 AP` | `15.0` | `6 tiles` |
| | **Drop-Shipper Drone** | Ranged Aerial | `35.0` | `4 AP` | `13.0` | `8 tiles` |
| | **5 AM Grindset Gargoyle** | Heavy Tank | `60.0` | `4 AP` | `18.0` | `5 tiles` |
| | **Ad-Tech Ghost** | Debuffer / Ghost | `40.0` | `4 AP` | `10.0` | `7 tiles` |
| | **Smug Vape Cloud** | **LEVEL 2 BOSS** | `180.0` | `4 AP` | `26.0` | `9 tiles` |
| **Level 3: Fire** | **VC Flame Imp** | Fast Melee | `40.0` | `4 AP` | `14.0` | `7 tiles` |
| | **Crunch Time Imp** | Ranged Caster | `45.0` | `4 AP` | `16.0` | `8 tiles` |
| | **Slide-Deck Mini-Dragon** | Area Fire Shooter | `55.0` | `4 AP` | `18.0` | `6 tiles` |
| | **Layoff Executioner** | Heavy Melee | `75.0` | `4 AP` | `22.0` | `5 tiles` |
| | **Corporate Top-Hat Bug** | Fast Disruptor | `50.0` | `4 AP` | `15.0` | `7 tiles` |
| | **Burnout CEO Fire Demon** | **LEVEL 3 BOSS** | `220.0` | `4 AP` | `32.0` | `9 tiles` |
| **Level 4: Water** | **Sea Men Grunt** | Swarm Melee | `50.0` | `4 AP` | `16.0` | `7 tiles` |
| | **Corporate Loan Shark** | Heavy Melee | `80.0` | `4 AP` | `24.0` | `6 tiles` |
| | **Deregulation Tar Blob** | Hazard Tank | `90.0` | `4 AP` | `20.0` | `5 tiles` |
| | **Offshore Shell Crab** | Armored Tank | `70.0` | `4 AP` | `18.0` | `6 tiles` |
| | **Anglerfish Lobbyist** | Ranged / Lure | `60.0` | `4 AP` | `22.0` | `8 tiles` |
| | **The Sea Lord** | **FINAL BOSS** | `300.0` | `4 AP` | `40.0` | `10 tiles` |

### 4.6 Difficulty Matrix & Save Rules

| Difficulty Tier | Enemy HP Scaling | Enemy DMG Scaling | Fog of War Sight Radius | Save & Permadeath Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Easy** | $0.8\times$ | $0.8\times$ | `8 tiles` (wide) | Auto-save at the start of every room. |
| **Medium** | $1.0\times$ | $1.0\times$ | `6 tiles` (standard) | Auto-save at the start of every room. |
| **Hard** | $1.3\times$ | $1.3\times$ | `5 tiles` (reduced) | Auto-save only at level start. |
| **EXTREME!!!!!!** | $1.6\times$ | $1.6\times$ | `3 tiles` (tight) | **FULL PERMADEATH:** Player death deletes the run save and resets to Level 1. |

---

## 5. Data Schemas (Custom Resources)

### 5.1 `WeaponData.gd` (`Resource`)
```gdscript
class_name WeaponData
extends Resource

@export var weapon_id: String = ""
@export var display_name: String = ""
@export var damage: float = 20.0
@export var ap_cost: int = 2
@export var is_ranged: bool = false
@export var max_range_tiles: int = 1
@export var projectile_texture: Texture2D
@export var icon: Texture2D
```

### 5.2 `EnemyData.gd` (`Resource`)
```gdscript
class_name EnemyData
extends Resource

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 40.0
@export var ap_pool: int = 4
@export var base_damage: float = 12.0
@export var sight_radius_tiles: int = 6
@export var is_ranged: bool = false
@export var projectile_texture: Texture2D
@export var sprite_texture: Texture2D
```

---

### 5.3 `ProjectileData.gd` (`Resource`) - V2
```gdscript
class_name ProjectileData
extends Resource

@export var projectile_id: String = ""
@export var display_name: String = ""
@export var texture: Texture2D
@export var speed: float = 1100.0          # px/s in isometric screen space
@export_enum("straight", "arc", "spin", "wobble", "beam") var motion: String = "straight"
@export var arc_height: float = 0.0        # lob height for "arc"
@export var spin_turns: float = 0.0        # turns per second
@export var tint: Color = Color.WHITE
@export var trail_color: Color = Color(1, 1, 1, 0)  # afterimage trail (alpha 0 = none)
@export var footprint: Vector2 = Vector2(56, 56)
```
`WeaponData` and `EnemyData` each reference a `ProjectileData` (`projectile`). There are 15 tweened projectiles / attack effects in `resources/projectiles/`: Neon Star Slash, Super Soaker Water Jet, Steel Nail, Megaphone Shout, Flying Tax Receipt, Crypto Coin, Drop-Shipped Box, Spam Pop-Up Ad, Vape Ring, Bug Report, Flaming Pie Chart, Pink Slip Eviction Notice, Sea Water Squirt, Dollar Lure and the CEO Trident Beam.

## 6. Technical Architecture & Godot Scene Hierarchy

### Directory Layout
```text
res://
├── assets/
│   └── sprites/               -> Isometric 2.5D Pixel Art PNGs
├── scenes/
│   ├── overworld/             -> NodeMap.tscn, NodeButton.tscn
│   ├── tactical/              -> TacticalBattlefield.tscn, IsometricGrid.gd, Projectile.tscn
│   ├── units/                 -> CarolUnit.tscn, EnemyUnit.tscn, PrincessPenny.tscn
│   ├── items/                 -> TacticalDrop.tscn
│   └── ui/                    -> TitleScreen.tscn, TacticalHUD.tscn, SaveMenu.tscn, VictoryScreen.tscn
├── scripts/
│   ├── autoload/              -> GameState.gd, SignalBus.gd, SaveManager.gd
│   └── resources/             -> WeaponData.gd, EnemyData.gd
└── resources/
    ├── weapons/               -> NeonSword.tres, SuperSoaker.tres, SqueakHammer.tres
    └── enemies/               -> [24 Enemy Data Tres Files]
```

---

## 7. Sequential Implementation Roadmap

### Phase 1: Overworld & Tactical Grid Core (Milestone 1)
- [ ] Implement `TitleScreen.tscn` featuring 4 difficulty selectors and Save/Load slot handlers.
- [ ] Build `NodeMap.tscn` procedural node tree generator (15–20 branching nodes per realm).
- [ ] Construct `IsometricGrid.gd` with Godot 4 `TileMapLayer` and `AStarGrid2D` pathfinding.
- [ ] Implement Carol's 4 AP turn pool and grid movement logic.

### Phase 2: Combat, Line of Sight & Projectiles (Milestone 2)
- [ ] Implement Fog of War tile shroud based on active difficulty sight radius.
- [ ] Build turn manager (Player Phase -> Enemy AI Phase).
- [ ] Implement `Projectile.tscn` linear travel and hit detection logic.
- [ ] Implement percentage hit chance formula with `RayCast2D` Line of Sight checks.
- [ ] Instantiate `WeaponData.gd` and `EnemyData.gd` resource files for all 24 monsters.

### Phase 3: Bosses, Rescue Sequence & Automated Build (Milestone 3)
- [ ] Build 4 Realm Boss entities (HOA Golem, Vape Cloud, CEO Fire Demon, Sea Lord).
- [ ] Implement `PrincessPenny.tscn` cage unlock trigger and `VictoryScreen.tscn` ending sequence.
- [ ] Implement JSON Save System (`user://savegame.json`) with EXTREME permadeath file wipe logic.
- [ ] Execute headless build verification test.

---

## 8. Automated Test & Build Directives
* **Headless Test Command:** `godot --headless --script res://scripts/tests/run_unit_tests.gd`
* **Headless Build Command:** `godot --headless --export-release "Windows Desktop" builds/DungeonCrawlerCarol_V2.exe`
* **Completion Criteria:** Milestone is marked COMPLETE only when the engine boots headlessly into the Title Screen, generates node overworlds, and completes a mock tactical turn without script errors or unhandled exceptions.