# 01: Technical Audit

Scope: build and project health, programming and architecture, performance and technical visuals.
Labels: [Verified] = read in a file or seen in output · [Measured] = from a script or command (see the appendix) · [Inferred] = reasoned, not observed.

---

## 1. Build and project health

### What's good — protect it
- **Clean boot and import [Measured].**
  - `godot --headless --import` takes 9.1 s with 0 warnings or errors.
  - `godot --headless --quit` takes 0.9 s with 0 warnings or errors.
  - The exported `.exe` cold-starts headless in 0.45-0.87 s.
- **Real automated tests [Measured].** `scripts/tests/run_unit_tests.gd` runs 152 checks in 6.4 s, exits with the failure count, and boots real scenes. It covers:
  - title → How to Play → map
  - a mock battle turn
  - all 4 bosses and Penny's rescue
  - save/load and the permadeath wipe
  - the display settings
  - Few solo prototypes have this. Keep it, and run it before every commit.
- **The content pipeline is reproducible [Verified].** The pipeline steps are:
  - `scripts/data/Roster.gd` is the single source of truth.
  - `scripts/tools/generate_resources.gd` writes all 43 `.tres` files from it.
  - `scripts/tools/build_assets.gd` rebuilds every sprite from the master art.
  - `scripts/tools/screenshots.gd` renders the README shots.
- **Tidy config [Verified].**
  - The export preset excludes tests and tools (`export_presets.cfg`, `exclude_filter="scripts/tests/*, scripts/tools/*"`).
  - `docs/.gdignore` keeps the docs out of the import.
  - `.gitattributes` normalizes line endings and marks binaries.

### Problems

| # | Finding | Evidence | Severity |
|---|---|---|---|
| B1 | **Release zips are committed to git.** `releases/DungeonCrawlerCarol_V2_Windows.zip` (47 MB) has been committed twice (41 MB, then 47 MB), and `.git` is now **193 MB** after 4 commits. Every rebuild adds another ~45 MB forever. GitHub warns above 50 MB per file and blocks above 100 MB. | [Measured] `du -sh .git` → 193M; `git log --numstat` | **Foundational: cheap now, painful later** |
| B2 | **No Linux preset, and only Windows templates installed.** Your stated targets are Steam (which includes Steam Deck/Linux) and itch. | [Verified] `export_presets.cfg` has only `[preset.0]` "Windows Desktop"; `%APPDATA%/Godot/export_templates/4.7.2.stable/` holds only `windows_*` files | High for launch, trivial to fix |
| B3 | **No application icon on the `.exe`.** It ships with the default Godot icon. `project.godot:12` points at `res://icon.svg`, but the Windows `.exe` needs an `.ico`. | [Verified] `export_presets.cfg` → `application/icon=""` | Low |
| B4 | **Unused input action.** `end_turn` is defined in the input map but never read. All keys are hard-coded `KEY_*` constants (`TacticalBattlefield.gd:344-348`, `HowToPlay.gd:66`, `GameState.gd:65`). This blocks key rebinding and controller support. | [Verified] `git grep is_action` → 0 hits | Medium, and gets more expensive as input grows |
| B5 | **No CI.** The 152 tests only run when someone remembers to run them. | [Verified] no `.github/workflows/` | Low (a nice-to-have for a solo dev) |
| B6 | **Untracked leftovers in the working tree.** `docs/studio_audit_report.txt` and `scripts/tools/audit_probe.gd` come from an earlier audit session and aren't committed. | [Verified] `git status` | Trivial |

### What the git history says [Verified]
- 4 commits between 2026-11-11 16:15 and 2026-11-12 07:50, all on `main`, with no branches or tags.
- The biggest churn is in `TacticalBattle(field).gd` (≈832 lines changed across the rename), `run_unit_tests.gd` (409) and `TacticalHUD.gd` (328). That's where change concentrates, and it's where future bugs will concentrate too.
- The history shows a project built in one burst, not one that has evolved through play. Nothing in it reflects playtest feedback: no tuning commits and no "fix after playtest" commits. That's consistent with finding G1: fun is unproven.

---

## 2. Programming and architecture

### Metrics [Measured] (full tables are in the appendix)

| Metric | Value |
|---|---|
| GDScript files (tracked) | 31 files, 3,925 lines |
| Scenes / resources / PNGs | 13 `.tscn` / 43 `.tres` / 69 `.png` |
| Largest script | `scenes/tactical/TacticalBattlefield.gd`: 728 lines, 49 functions (19% of all code) |
| Next largest | `run_unit_tests.gd` 379 · `TacticalHUD.gd` 310 · `IsometricGrid.gd` 293 · `GameState.gd` 276 |
| Longest function | `_test_tactical` (114 lines), then `OverworldGenerator.generate` (72), `TitleScreen._ready` (64), `_spawn_units` (62) |
| Functions with an explicit return type | 240 of 240 (100%) |
| TODO / FIXME / HACK | 0 |
| Signals declared / `.connect(` / `.emit(` | 16 / 28 / 27 |
| `push_error` / `push_warning` / `assert` outside tools | 2 (both in `SaveManager.gd`) |
| Deepest scene tree | 2 levels (`TacticalBattlefield.tscn`, 13 nodes); every UI scene is a single root node |
| Test checks | 152 |

### What's good — protect it
- **Data-driven content [Verified].**
  - The enemy, weapon and projectile stats live in three tables in `scripts/data/Roster.gd` (lines 6-35, 38-43, 52-68).
  - They're turned into `EnemyData`, `WeaponData` and `ProjectileData` resources (`scripts/resources/`).
  - Adding a monster means adding one row and re-running the generator. That's the right foundation for content growth.
- **Static typing is consistently high [Measured].** All 240 functions declare a return type, and `class_name` is used for all data and utility types (12 classes).
- **Mostly decoupled [Verified].**
  - The battle pushes state changes up through the `SignalBus` autoload (`scripts/autoload/SignalBus.gd:4-10`).
  - The HUD calls a narrow set of battle methods (`TacticalHUD.gd:175-187`).
  - Grid maths, pathing, line of sight and fog live in `IsometricGrid.gd`. Combat maths is pure static functions in `CombatMath.gd`.
- **2×2 boss occupancy is modelled cleanly [Verified].** `BattleUnit.footprint()`, `occupies()` and `nearest_cell()` (`scenes/units/BattleUnit.gd:29-46`) handle it, with no special cases scattered through the battle code.
- **There's a save foundation [Verified].**
  - Saves are JSON (`SaveManager.gd`), with 3 slots.
  - `GameState.to_dict` / `from_dict` (`GameState.gd:224`, `:243`) and `_normalize_map` restores integer IDs after a JSON round trip.
  - Corrupt saves are handled by returning `{}` (`SaveManager.gd:42-46`).

### Problems

| # | Finding | Evidence | Prototype-normal or foundational? |
|---|---|---|---|
| A1 | **Battle "god script".** `TacticalBattlefield.gd` mixes map generation (`_build_map`, `_spawn_units`, `_place_terrain`), turn flow, input, player actions, enemy AI (`_enemy_act`, `_enemy_step`, `_boss_step`), effects and scene transitions in 728 lines. Adding abilities, overwatch or status effects will push it past 1,500 lines. | [Measured] 49 functions; churn hot spot | **Foundational, cheap to split now.** Extract `EnemyAI.gd` and `RoomGenerator.gd` (about 4-6 h). |
| A2 | **All UI is built in code.** Every UI `.tscn` is one empty root node, and the layout is hundreds of `position = Vector2(...)` literals (27 hard-coded `Vector2(≥100, ≥10)` coordinates in `scenes/`). You can't adjust the UI visually in the Godot editor, and themes and anchors can't do their job. | [Verified] `TitleScreen.gd:13-76`, `TacticalHUD.gd:53-155`, `HowToPlay.gd:13-63` | **Foundational for a solo dev.** UI iteration speed matters most in the months ahead. |
| A3 | **UI is designed at 1280×720 and scaled ×1.5.** `UiKit.fit_design` (`scripts/ui/UiKit.gd:70-78`) scales from the *ProjectSettings* size, not the live viewport. It works under `stretch/aspect="keep"` (`project.godot:26`), but at 16:10 (Steam Deck) you get letterboxing, not a layout that adapts. | [Verified] | Prototype-normal; plan to replace it when moving to editor-built UI |
| A4 | **Saves aren't atomic, and loads aren't validated.** `save_game` writes straight into the live file (`SaveManager.gd:27-37`), so a crash mid-write leaves a truncated slot. `from_dict` trusts `equipped_weapon` from JSON (`GameState.gd:250`), and an unknown ID crashes at the first `current_weapon().ap_cost`. The save `"version": 2` (`GameState.gd:226`) wasn't bumped for the V2 schema change. | [Verified] | **Foundational: cheap now, expensive once players have saves** |
| A5 | **Permadeath can be dodged.** `_defeat` wipes only `GameState.active_slot` (`TacticalBattlefield.gd:688`). Copies in other slots survive, and EXTREME only auto-saves at level start, so quitting before death and reloading avoids the wipe. | [Verified] | Design-integrity issue; about 2 h to fix |
| A6 | **Hidden coupling between autoloads.** `GameState.autosave` reaches SaveManager through `get_node_or_null("/root/SaveManager")` (`GameState.gd:156`), while SaveManager calls `GameState.to_dict()`. That's a circular dependency between autoloads. | [Verified] | Prototype-normal |
| A7 | **The HUD is untyped toward the battle.** `var battle: Node2D` (`TacticalHUD.gd:4`) is used through duck typing (`battle.enemies`, `battle.use_drink()`), and `TacticalBattlefield` has no `class_name`. Renames won't be caught by the type checker. | [Verified] | Cheap fix (15 min) |
| A8 | **Dead code.** The node `Grid/Effects` (`TacticalBattlefield.tscn:41`, `IsometricGrid.gd:20`) is unused since projectiles moved to `Objects`. `y_sort_enabled` on the battle root (`.tscn:9`) has no effect, because the sorting happens on `Grid/Objects` (`:39`). The `trash` cover kind (`IsometricGrid.gd:10`) is never placed. | [Verified] | Trivial |
| A9 | **Battles can't be reproduced.** `TacticalBattlefield._ready` calls `rng.randomize()` (`:48`), so room layouts and rolls ignore `GameState.run_seed`. Bugs in a given room can't be reproduced, there are no shareable seeds or daily runs, and reloading a save re-rolls the room. | [Verified] | **Foundational for a roguelite.** About 1 h now, while there are few call sites. |
| A10 | **Error handling is thin.** There are 2 `push_error`/`push_warning` calls outside the tools, and no `assert`s on invariants (for example, a unit standing on a solid cell). | [Measured] | Prototype-normal |

### Correctness bugs found by measurement

| # | Bug | Evidence |
|---|---|---|
| C1 | **Highlighted move tiles that can't be reached.** `IsometricGrid.reachable()` (`:218`) is an unweighted BFS, but `add_hazard()` gives spike tiles A* weight 5.0 (`:175`). `player_move` then rejects any weighted path longer than Carol's AP (`TacticalBattlefield.gd:406`), so the click silently does nothing. | [Measured] Run 1: 8/1,083 tiles. Run 2: 23/1,094 tiles with a different path length, 18 of them over the AP limit (1.6%) |
| C2 | **Shots go through a vending machine next to the shooter.** `has_los()` exempts the line-of-sight bodies next to *both* ends (`IsometricGrid.gd:240-247`), so a vending machine directly in front of the shooter doesn't block. | [Verified] code read; not separately measured |
| C3 | **Fog ignores line of sight.** `update_fog` reveals by radius only (`IsometricGrid.gd:276`), and enemy detection is distance-only (`TacticalBattlefield.gd:507`). | [Measured] 278-285 of 2,830 "visible" tiles (≈10%) have no line of sight |
| C4 | **Enemies take no spike damage.** Only Carol's step triggers spikes (`_after_carol_step`, `TacticalBattlefield.gd:421-430`), while A* makes enemies avoid spikes anyway. Spikes are a one-sided rule. | [Verified] |

### Can the architecture scale to a full game? [Inferred]
- **Content (more monsters, weapons, realms):** yes, easily, thanks to the Roster-to-resource pipeline.
- **Mechanics (abilities, statuses, overwatch, multiple heroes):** not without splitting A1 first. Carol is the only player unit, and that assumption is baked into 54 `carol.` references in the battle script.
- **Settings:** there is no settings file or menu at all (0 hits for `ConfigFile` or `volume`).
- **Localization:** there is none. All strings are inline literals. That's fine for now, but wrapping them in `tr()` early is cheap.

---

## 3. Performance and technical visuals

### Measurements [Measured] (windowed 1920×1080, v-sync on, GL Compatibility)

| Scene | Load ms | Avg frame ms | p95 ms | Draw calls | Nodes | VRAM (textures) |
|---|---|---|---|---|---|---|
| TitleScreen (first load) | 440 | 16.48 | 16.72 | 26 | 19 | 29.1 MB |
| HowToPlay | 165 | 16.54 | 16.73 | **325** | 33 | 18.4 MB |
| NodeMap | 345 | 16.51 | 16.73 | 131 | 34 | 20.5 MB |
| Battle realm 1 (first) | 807 | 16.47 | 16.73 | 218 | 67 | 22.3 MB |
| Battle realms 2-4 | 69-84 | 16.48-16.51 | 16.73-16.74 | 224-266 | 71-82 | 22.8-25.3 MB |
| VictoryScreen | 109 | 16.48 | 16.73 | 34 | 12 | 34.4 MB |

Other measurements:
- Peak static memory: 54.7 MB.
- Per-action logic is negligible: `attack_range_cells()` takes 0.12-0.20 ms, `_refresh_player_view()` 0.35 ms, and `update_fog()` 0.10 ms.

### Assessment
- **Renderer choice is right [Verified].** GL Compatibility (`project.godot:43-44`) is the safest choice for low-end PCs, older iGPUs and Steam Deck through Proton.
- **The frame budget is nowhere near its limit [Measured].** Every scene sits at v-sync with p95 ≤ 16.8 ms.
- **Draw calls [Measured].** HowToPlay's 325 draw calls for a text screen are a symptom of many outlined MSDF `Label`s. It's harmless at this count, but watch it if you build denser text UI.
- **Textures [Measured].**
  - There are 63 PNGs: 10.3 MB on disk, and 26 MB as uncompressed RGBA.
  - They're imported lossless (`compress/mode=0`) with no mipmaps (`mipmaps/generate=false`; for example, `assets/sprites/carol_iso.png.import:18,26`).
  - Sprites are stored at about 2× their display size and downscaled with linear filtering. Without mipmaps, 2× minification is acceptable but slightly aliased [Inferred]. Enable mipmaps if you ever zoom out.
- **Per-frame work [Verified].**
  - Only `Projectile._process` runs every frame (`Projectile.gd:60`). It allocates a `Sprite2D` "ghost" every 25 ms (`:66`) for trails. That's fine for 1-2 projectiles, but use `GPUParticles2D` or a pooled trail if you add volleys.
  - There's no `_physics_process` anywhere. Line of sight uses a single `RayCast2D` with `force_raycast_update()` (`IsometricGrid.gd:240-255`), which is cheap.
- **Fullscreen handling [Verified].** `window/size/mode=3` (`project.godot:24`) is borderless windowed fullscreen, which is correct for alt-tab-friendly PC play. F11 toggles it (`GameState.gd:64-75`). The game *always* boots fullscreen, though, and there's no saved preference.
- **Steam Deck risks [Inferred].**
  - The 16:10 1280×800 screen gets letterboxed by `aspect="keep"`.
  - The smallest UI text (11 px design size, ×1.5 = 16.5 px at 1080p) becomes about 11 px on the Deck's 7" screen.
  - There's no controller input at all (B4).
  - Performance will be fine.
- **Build size [Measured].** The `.exe` is 118 MB, and 109 MB of that is the Godot 4.7 release template. The game data is about 9 MB. A custom export template without 3D and unused modules could cut the download by roughly half [Inferred, general Godot knowledge].
