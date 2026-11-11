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

### 4.1 Grid & Projection Specs
* **Tile Grid:** Isometric projection using Godot 4 `TileMapLayer` ($32 \times 16$ px cell dimensions or scaled equivalent).
* **Texture Filtering:** Set project texture filter to **Nearest Neighbor** for sharp 16-bit pixel rendering.
* **Fog of War:** Tiles outside Carol's vision radius are shrouded in darkness. Enemies remain invisible until entering Carol's sight radius.

### 4.2 Turn Economy & Action Point (AP) Pool
Carol and enemies operate on a **4 AP Pool per turn**:

| Action | AP Cost | Technical Description |
| :--- | :--- | :--- |
| **Grid Movement** | `1 AP` / tile | Moves unit 1 tile along calculated `AStarGrid2D` path. |
| **Melee Attack (Star-Sword)** | `2 AP` | Strikes an adjacent grid tile. |
| **Ranged Weapon Attack** | `2 AP` to `3 AP` | Spawns a projectile directed at a target grid coordinate. |
| **Consumable / Energy Drink** | `1 AP` | Restores HP or adds temporary bonus AP. |

### 4.3 Accuracy & Line of Sight (LOS) Formulas
Hit accuracy is probability-based, determined by unit range and raycast obstruction:

$$HitChance = \max(30\%, BaseAccuracy - (Distance \times 5\%))$$

* **Base Melee Accuracy:** $95\%$
* **Base Ranged Accuracy:** $85\%$
* **Line of Sight (LOS):** Casts a `RayCast2D` from center-of-tile to center-of-tile. If intercepted by solid wall geometry, $HitChance = 0\%$.

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
| **Easy** | $0.8\times$ | $0.8\times$ | `8 tiles` | Save game allowed at start of every node. |
| **Medium** | $1.0\times$ | $1.0\times$ | `6 tiles` | Save game allowed at start of every node. |
| **Hard** | $1.25\times$ | $1.25\times$ | `5 tiles` | Save game allowed at start of each realm level. |
| **EXTREME!!!!!!** | $1.5\times$ | $1.5\times$ | `4 tiles` | **FULL PERMADEATH:** Player death wipes save file and resets run to Level 1. |

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

## 6. Technical Architecture & Godot Scene Hierarchy

### Directory Layout
```text
res://
├── assets/
│   └── sprites/               -> Isometric 2.5D Pixel Art PNGs
├── scenes/
│   ├── overworld/             -> OverworldMap.tscn, NodeButton.tscn
│   ├── tactical/              -> TacticalBattle.tscn, IsometricGrid.gd, Projectile.tscn
│   ├── units/                 -> CarolUnit.tscn, EnemyUnit.tscn, PrincessPenny.tscn
│   ├── items/                 -> TacticalDrop.tscn
│   └── ui/                    -> TitleScreen.tscn, TacticalHUD.tscn, SaveMenu.tscn, VictoryScreen.tscn
├── scripts/
│   ├── autoload/              -> GameState.gd, SignalBus.gd, SaveSystem.gd
│   └── resources/             -> WeaponData.gd, EnemyData.gd
└── resources/
    ├── weapons/               -> NeonSword.tres, SuperSoaker.tres, SqueakHammer.tres
    └── enemies/               -> [24 Enemy Data Tres Files]
```

---

## 7. Sequential Implementation Roadmap

### Phase 1: Overworld & Tactical Grid Core (Milestone 1)
- [ ] Implement `TitleScreen.tscn` featuring 4 difficulty selectors and Save/Load slot handlers.
- [ ] Build `OverworldMap.tscn` procedural node tree generator (15–20 branching nodes per realm).
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