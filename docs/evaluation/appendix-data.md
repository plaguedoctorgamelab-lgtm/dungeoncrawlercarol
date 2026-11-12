# Appendix: Raw Data and How to Reproduce It

Every number in this report comes from one of the commands or scripts below, run on 2026-11-12 against commit `78e1a73`. `G` means the Godot binary: `Godot_v4.7.2-stable_win64_console.exe`. Run everything from the project root.

Battle layouts are **not seeded** (01-A9), so the probe and sim numbers vary a few percent between runs. Re-run them and compare ranges, not exact values.

## A. Environment

| Item | Value | Command |
|---|---|---|
| Godot | `4.7.2.stable.official.ed1daf0bf` | `G --version` |
| Project target | `config/features=PackedStringArray("4.7", "GL Compatibility")` | `project.godot:11` |
| OS | Windows 10 Home 10.0.19045 | |
| Export templates installed | `windows_debug_x86_64.exe`, `windows_release_x86_64.exe` only | `ls %APPDATA%/Godot/export_templates/4.7.2.stable/` |

## B. Build, boot and test

| Step | Result | Command |
|---|---|---|
| Import | 9.1 s wall; 0 warning or error lines | `G --headless --path . --import` |
| Headless boot | 0.9 s wall; no output besides the banner | `G --headless --path . --quit` |
| Test suite | `152 checks, 0 failures`, `RESULT: ALL TESTS PASSED`; 6.4 s wall; 0 `WARNING` lines | `G --headless --path . --script res://scripts/tests/run_unit_tests.gd` |
| Exported `.exe` cold start (headless, quit after 2 frames) | 869 / 453 / 453 ms (3 runs) | PowerShell `Measure-Command { & builds\DungeonCrawlerCarol_V2.exe --headless --quit-after 2 }` |
| `.exe` size | 118,273,960 bytes; template alone is 109,268,480 bytes | `ls -la builds/`; template file size |
| Windows export | Succeeds (produced earlier this session; smoke-tested windowed for 180 frames, 0 errors) | `G --headless --path . --export-release "Windows Desktop" builds/DungeonCrawlerCarol_V2.exe` |
| Linux export | **Not possible:** no preset and no templates | `export_presets.cfg` has only `[preset.0]` |

## C. Repository and git

- Tracked files: 261 (`git ls-files | wc -l`)
- `.git` size: 193 MB; `releases/`: 45 MB; `assets/`: 11 MB (`du -sh .git releases assets`)
- Untracked: `docs/studio_audit_report.txt`, `scripts/tools/audit_probe.gd` (`git status --short`)

History (`git log --format='%h %ad %s' --date=iso`):
```
78e1a73 2026-11-12 07:50:42 -0500 V2 HD tactical overhaul: 1080p fullscreen, 128x64 grid, cover combat
c675a75 2026-11-11 16:56:11 -0500 Keep docs out of the game build
8efb476 2026-11-11 16:55:16 -0500 Add How to Play screen before the overworld map
9a94a0f 2026-11-11 16:15:06 -0500 Dungeon Crawler Carol: Lair of The Sea Lord - Godot 4.7 build
```

Churn by file, lines added + deleted (`git log --numstat --format='' | awk '{a[$3]+=$1+$2} END{for(f in a) print a[f], f}' | sort -rn | head -15`):
```
650 scenes/tactical/TacticalBattle.gd
409 scripts/tests/run_unit_tests.gd
328 scenes/ui/TacticalHUD.gd
310 scripts/autoload/GameState.gd
309 scenes/tactical/IsometricGrid.gd
305 docs/game_design_document.md
260 scenes/overworld/OverworldMap.gd
201 scripts/tools/build_assets.gd
196 README.md
182 scenes/tactical/{TacticalBattle.gd
144 scenes/overworld/OverworldGenerator.gd
135 docs/master_graphics_asset_manifest.md
126 scenes/units/BattleUnit.gd
124 scripts/ui/UiKit.gd
124 scripts/data/Roster.gd
```

## D. Code metrics

Lines per tracked script (`git ls-files '*.gd' | xargs wc -l | sort -rn`):
```
  3925 total
   728 scenes/tactical/TacticalBattlefield.gd
   379 scripts/tests/run_unit_tests.gd
   310 scenes/ui/TacticalHUD.gd
   293 scenes/tactical/IsometricGrid.gd
   276 scripts/autoload/GameState.gd
   263 scenes/overworld/NodeMap.gd
   144 scenes/overworld/OverworldGenerator.gd
   127 scripts/tools/build_assets.gd
   118 scripts/ui/UiKit.gd
   114 scripts/data/Roster.gd
   103 scripts/util/SpriteScaler.gd
   102 scenes/units/BattleUnit.gd
    94 scenes/ui/TitleScreen.gd
    88 scenes/ui/SaveMenu.gd
    80 scripts/tools/generate_resources.gd
    78 scenes/tactical/Projectile.gd
    78 scenes/overworld/NodeButton.gd
    73 scripts/autoload/SaveManager.gd
    71 scenes/ui/HowToPlay.gd
    66 scripts/tools/screenshots.gd
    57 scenes/tactical/GridOverlay.gd
    51 scenes/units/PrincessPenny.gd
    41 scenes/ui/VictoryScreen.gd
    39 scenes/tactical/CombatMath.gd
    34 scenes/items/TacticalDrop.gd
    27 scripts/resources/EnemyData.gd
    25 scenes/units/EnemyUnit.gd
    21 scripts/resources/ProjectileData.gd
    18 scripts/resources/WeaponData.gd
    14 scripts/autoload/SignalBus.gd
    13 scenes/units/CarolUnit.gd
```

| Metric | Value | Command |
|---|---|---|
| `.gd` / `.tscn` / `.tres` / `.png` tracked | 31 / 13 / 43 / 69 | `git ls-files '*.gd' \| wc -l` etc. |
| Functions | 240, all with a `->` return type | `git grep -hE '^(static )?func ' -- '*.gd' \| grep -vc -- '->'` → 0 |
| Functions in `TacticalBattlefield.gd` | 49 | `grep -c '^func\|^static func'` |
| Longest functions | `_test_tactical` 114 lines; `OverworldGenerator.generate` 72; `generate_resources._initialize` 65; `TitleScreen._ready` 64; `_spawn_units` 62 | awk over `^func` boundaries (counts lines until the next func) |
| TODO/FIXME/HACK/XXX | 0 | `git grep -nE "TODO\|FIXME\|HACK\|XXX" -- '*.gd' \| wc -l` |
| Signals / connects / emits | 16 / 28 / 27 | `git grep -c "^signal "` / `"\.connect("` / `"\.emit("` |
| `_process` / `_physics_process` | 1 / 0 (`Projectile.gd:60`) | `git grep -nE "func _(physics_)?process"` |
| Hard-coded `KEY_*` uses | 6 lines in 3 files | `git grep -n "KEY_" -- '*.gd'` |
| `is_action` / InputMap / joypad uses | 0 | `git grep -n "is_action\|InputMap\|JOY" -- '*.gd'` |
| Audio files / references | 0 / 0 | `git ls-files \| grep -iE "\.(ogg\|wav\|mp3)$"`; `git grep -niE "AudioStream\|AudioServer"` |
| Shaders | 0 | `git ls-files \| grep -iE "\.(gdshader\|shader)$"` |
| `ConfigFile` / settings | 0 | `git grep -n ConfigFile` |
| Hard-coded `Vector2(≥100, ≥10)` coordinates in `scenes/` | 27 | `git grep -nE "Vector2\([0-9]{3,}, [0-9]{2,}\)" -- 'scenes/**/*.gd' \| wc -l` |
| Scene depth / nodes | `TacticalBattlefield.tscn` depth 2, 13 nodes; all UI scenes are 1 node | parse `parent=` in each `.tscn` |

## E. Runtime performance (windowed 1920×1080, v-sync on)

Script: `perf_probe.gd`; source in section G. It ran from outside the repo:
`G --path . --windowed --resolution 1920x1080 --script <abs path>/perf_probe.gd`
```
STARTUP msec_since_engine_start=1964
SCENE TitleScreen            load_ms=  440.4 avg_frame_ms= 16.48 p95= 16.72 max= 33.41 draw_calls=  26 nodes=   19 objects=  1564 static_mem_MB=  34.7 vram_tex_MB=  29.1
SCENE HowToPlay              load_ms=  164.8 avg_frame_ms= 16.54 p95= 16.73 max= 16.75 draw_calls= 325 nodes=   33 objects=  1587 static_mem_MB=  35.3 vram_tex_MB=  18.4
SCENE NodeMap                load_ms=  344.9 avg_frame_ms= 16.51 p95= 16.73 max= 16.75 draw_calls= 131 nodes=   34 objects=  1658 static_mem_MB=  35.4 vram_tex_MB=  20.5
SCENE Battle realm 1         load_ms=  807.3 avg_frame_ms= 16.47 p95= 16.73 max= 16.74 draw_calls= 218 nodes=   67 objects=  1697 static_mem_MB=  38.5 vram_tex_MB=  22.3
SCENE Battle realm 2         load_ms=   69.0 avg_frame_ms= 16.48 p95= 16.73 max= 16.78 draw_calls= 224 nodes=   71 objects=  1710 static_mem_MB=  38.6 vram_tex_MB=  22.8
SCENE Battle realm 3         load_ms=   84.2 avg_frame_ms= 16.49 p95= 16.73 max= 16.75 draw_calls= 229 nodes=   76 objects=  1729 static_mem_MB=  38.7 vram_tex_MB=  23.6
SCENE Battle realm 4 boss    load_ms=   81.8 avg_frame_ms= 16.51 p95= 16.74 max= 16.77 draw_calls= 266 nodes=   82 objects=  1743 static_mem_MB=  38.7 vram_tex_MB=  25.3
ENEMY_PHASE wall_ms=250 enemies=3
SCENE VictoryScreen          load_ms=  109.4 avg_frame_ms= 16.48 p95= 16.73 max= 17.71 draw_calls=  34 nodes=   12 objects=  1616 static_mem_MB=  38.1 vram_tex_MB=  34.4
MEM static_peak_MB=54.7
```

## F. Gameplay probes

### F1. `scripts/tools/audit_probe.gd` (in the working tree, untracked)
`G --headless --path . --script res://scripts/tools/audit_probe.gd`. It runs 40 rooms and 200 maps. This is run 2; run 1, earlier the same day, found 8/1,083 mismatched tiles, 81.3% open shots and 285 tiles visible without line of sight.
```
PROBE rooms=40
PROBE reachable_cells=1094 path_len_mismatch=23 mismatch_beyond_AP=18
PROBE ranged_shots=5222 open=73.5% half=14.6% full=3.8% noLOS=8.1%
PROBE mean_hit_when_shot_possible=78.9%
PROBE fog_visible=2830 visible_without_LOS=278
PROBE ms attack_range_cells=0.12 refresh_player_view=0.35 update_fog=0.10
WPN neon_sword dmg=25 ap=2 range=1 exp_dmg_per_AP_open=10.63 half=10.63 full=10.63
WPN super_soaker dmg=34 ap=2 range=5 exp_dmg_per_AP_open=14.45 half=10.20 full=5.95
WPN squeak_hammer dmg=36 ap=2 range=1 exp_dmg_per_AP_open=15.30 half=15.30 full=15.30
WPN nailgun dmg=16 ap=2 range=7 exp_dmg_per_AP_open=6.80 half=4.80 full=2.80
MAP maps=200 avg_nodes=17.5 avg_layers=7.3 boss_not_in_last_layer=111 shortest_path_nodes=6.7 longest_path_nodes=8.2
MAP node_types { "combat": 2010, "hazard": 623, "supply": 671, "boss": 200 }
```

### F2. Auto-play balance sim (`autoplay_sim.gd`; source in section H)
`G --headless --path . --script <abs path>/autoplay_sim.gd`. 40 battles per row, `Engine.time_scale = 30`. Bot policy: drink when below 35 HP; otherwise attack the target with the best expected damage using the best weapon; otherwise step toward the nearest enemy. **It never seeks cover**, so its win rates are a floor for human players. Realm ≥ 3 runs grant the Super Soaker, and every battle starts with 1 drink.
```
SIM diff=Medium realm=1 boss=false battles=40 win_rate=100% avg_turns=4.3 avg_hp_lost=18 carol_hit_rate=83%
SIM diff=Medium realm=1 boss=true battles=40 win_rate=88% avg_turns=13.6 avg_hp_lost=32 carol_hit_rate=67%
SIM diff=Medium realm=3 boss=false battles=40 win_rate=95% avg_turns=4.6 avg_hp_lost=20 carol_hit_rate=78%
SIM diff=Medium realm=4 boss=true battles=40 win_rate=20% avg_turns=5.7 avg_hp_lost=92 carol_hit_rate=83%
SIM diff=EXTREME!!!!!! realm=1 boss=false battles=40 win_rate=70% avg_turns=8.6 avg_hp_lost=58 carol_hit_rate=76%
SIM diff=EXTREME!!!!!! realm=1 boss=true battles=40 win_rate=35% avg_turns=14.1 avg_hp_lost=71 carol_hit_rate=62%
SIM diff=EXTREME!!!!!! realm=4 boss=false battles=40 win_rate=60% avg_turns=5.5 avg_hp_lost=67 carol_hit_rate=89%
SIM diff=EXTREME!!!!!! realm=4 boss=true battles=40 win_rate=0% avg_turns=2.6 avg_hp_lost=100 carol_hit_rate=87%
SIM diff=Easy realm=4 boss=true battles=40 win_rate=48% avg_turns=9.3 avg_hp_lost=72 carol_hit_rate=73%
SIM diff=Hard realm=4 boss=true battles=40 win_rate=5% avg_turns=5.7 avg_hp_lost=92 carol_hit_rate=86%
```

### F3. Texture inventory (`assets/sprites/*.png`; header-parsed width × height; disk KB)
63 PNGs: 10.3 MB on disk, 26.0 MB as uncompressed RGBA. Import: `compress/mode=0` (lossless), `mipmaps/generate=false`, `process/fix_alpha_border=true` (for example, `assets/sprites/carol_iso.png.import:18,26,34`).

| File | Size | KB |
|---|---|---|
| algorithm_ghost.png | 197x256 | 80 |
| bureaucrat_golem.png | 469x512 | 307 |
| burnout_ceo_boss.png | 512x370 | 250 |
| carol_iso.png | 256x245 | 72 |
| carol_portrait.png | 256x245 | 72 |
| clipboard_intern.png | 170x256 | 67 |
| corporate_shark.png | 230x256 | 85 |
| cover_vending_machine.png | 255x384 | 148 |
| cover_wooden_crate.png | 253x256 | 113 |
| crunch_time_imp.png | 256x221 | 79 |
| crypto_bat.png | 256x181 | 62 |
| deep_sea_lobbyist.png | 256x166 | 70 |
| downsize_executioner.png | 256x238 | 82 |
| drone_drop_shipper.png | 256x223 | 74 |
| earth_slime_suit.png | 256x178 | 72 |
| gated_community_guard.png | 223x256 | 71 |
| hazard_spikes.png | 128x98 | 21 |
| hazard_spikes_iso.png | 126x96 | 21 |
| hustle_grindset_gargoyle.png | 256x179 | 79 |
| item_energy_drink.png | 62x128 | 20 |
| lawn_mower_drone.png | 256x200 | 82 |
| monopoly_fire_car.png | 251x256 | 79 |
| nft_monkey.png | 135x256 | 50 |
| oil_spill_blob.png | 256x202 | 77 |
| penny_portrait.png | 151x256 | 61 |
| pitch_deck_dragon.png | 256x202 | 69 |
| princess_barista_iso.png | 151x256 | 61 |
| proj_ad_popup.png | 128x73 | 17 |
| proj_amazon_box.png | 120x128 | 16 |
| proj_bug_report.png | 118x128 | 23 |
| proj_crypto_coin.png | 128x106 | 26 |
| proj_dollar_lure.png | 102x128 | 16 |
| proj_megaphone_wave.png | 128x95 | 14 |
| proj_pie_chart.png | 128x79 | 14 |
| proj_pink_slip.png | 128x104 | 20 |
| proj_star_slash.png | 128x95 | 14 |
| proj_steel_nail.png | 128x85 | 13 |
| proj_tax_receipt.png | 128x85 | 14 |
| proj_trident_beam.png | 128x76 | 10 |
| proj_vape_ring.png | 128x82 | 19 |
| proj_water_squirt.png | 128x48 | 7 |
| proj_water_stream.png | 128x75 | 10 |
| screen_title.png | 1920x1080 | 3038 |
| screen_victory.png | 1920x1080 | 3735 |
| sea_lord_boss.png | 448x512 | 318 |
| sea_men_grunt.png | 256x247 | 81 |
| tax_auditor_mole.png | 256x244 | 83 |
| tax_haven_crab.png | 256x205 | 94 |
| tile_air_floor.png | 128x73 | 13 |
| tile_air_floor_iso.png | 128x64 | 10 |
| tile_earth_floor.png | 128x83 | 15 |
| tile_earth_floor_iso.png | 128x64 | 11 |
| tile_fire_floor.png | 128x85 | 18 |
| tile_fire_floor_iso.png | 128x64 | 13 |
| tile_water_floor.png | 128x76 | 17 |
| tile_water_floor_iso.png | 128x64 | 13 |
| ui_hit_chance_badge.png | 450x134 | 68 |
| vape_cloud_elemental.png | 512x385 | 278 |
| venture_capitalist_flame.png | 238x256 | 92 |
| weapon_nailgun.png | 128x103 | 25 |
| weapon_neon_sword.png | 128x87 | 12 |
| weapon_squeak_hammer.png | 128x110 | 21 |
| weapon_water_pistol.png | 128x88 | 19 |

## G. `perf_probe.gd` source
```gdscript
extends SceneTree
## Evaluation perf probe (lives outside the repo). Measures scene load times, frame times,
## draw calls, node/object counts and memory for each main scene.
## godot --path <project> --script <abs path to this file> [-- headless]

var gs: Node
var rows: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> Dictionary:
	var times: Array[float] = []
	var draws := 0
	var last := Time.get_ticks_usec()
	for i in n:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		draws = maxi(draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	times.sort()
	var sum := 0.0
	for t in times:
		sum += t
	return {"avg": sum / n, "p95": times[int(n * 0.95)], "max": times[n - 1], "draws": draws}


func _measure(label: String, path: String) -> void:
	var t0 := Time.get_ticks_usec()
	change_scene_to_file(path)
	await process_frame
	await process_frame
	var load_ms := (Time.get_ticks_usec() - t0) / 1000.0
	if current_scene and "ready_done" in current_scene:
		var guard := 0
		while not current_scene.ready_done and guard < 300:
			await process_frame
			guard += 1
	var f := await _frames(120)
	var line := "SCENE %-22s load_ms=%7.1f avg_frame_ms=%6.2f p95=%6.2f max=%6.2f draw_calls=%4d nodes=%5d objects=%6d static_mem_MB=%6.1f vram_tex_MB=%6.1f" % [
		label, load_ms, f["avg"], f["p95"], f["max"], f["draws"],
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0]
	print(line)


func _run() -> void:
	print("STARTUP msec_since_engine_start=%d" % Time.get_ticks_msec())
	gs = root.get_node("GameState")
	root.get_node("SaveManager").base_dir = "user://eval_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://eval_saves"))
	await _measure("TitleScreen", "res://scenes/ui/TitleScreen.tscn")
	gs.new_run(1, 4242)
	await _measure("HowToPlay", "res://scenes/ui/HowToPlay.tscn")
	await _measure("NodeMap", "res://scenes/overworld/NodeMap.tscn")
	for realm in 4:
		gs.start_realm(realm)
		gs.pending_node = gs.map_data["boss_id"] if realm == 3 else gs.available_nodes()[0]
		await _measure("Battle realm %d%s" % [realm + 1, " boss" if realm == 3 else ""], "res://scenes/tactical/TacticalBattlefield.tscn")
	# Enemy phase wall time (animations at 1x speed).
	var b = current_scene
	b.forced_roll = 1.0
	var t0 := Time.get_ticks_usec()
	await b.end_player_turn()
	print("ENEMY_PHASE wall_ms=%.0f enemies=%d" % [(Time.get_ticks_usec() - t0) / 1000.0, b.enemies.size()])
	await _measure("VictoryScreen", "res://scenes/ui/VictoryScreen.tscn")
	print("MEM static_peak_MB=%.1f" % (Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0))
	quit(0)
```

## H. `autoplay_sim.gd` source
```gdscript
extends SceneTree
## Evaluation auto-play sim (outside the repo). A greedy bot plays real TacticalBattlefield
## battles through the game's own API and records win rate, turns, HP lost and misses.
## Bot policy: drink if HP < 35 and a drink is left; otherwise attack the best expected-damage
## target with the best weapon; otherwise step toward the nearest enemy; then end turn.
## It never seeks cover, so results are a floor for a careful human.

var gs: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	gs = root.get_node("GameState")
	root.get_node("SaveManager").base_dir = "user://eval_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://eval_saves"))
	Engine.time_scale = 30.0
	var configs := [
		[1, 0, false], [1, 0, true], [1, 2, false], [1, 3, true],
		[3, 0, false], [3, 0, true], [3, 3, false], [3, 3, true],
		[0, 3, true], [2, 3, true],
	]
	for cfg in configs:
		var diff: int = cfg[0]
		var realm: int = cfg[1]
		var boss: bool = cfg[2]
		var n := 40
		var wins := 0
		var turns_sum := 0
		var hp_lost_sum := 0.0
		var shots := 0
		var hits := 0
		for i in n:
			var r: Dictionary = await _battle(diff, realm, boss, 7000 + i * 13 + realm * 101 + diff)
			if r["win"]:
				wins += 1
			turns_sum += r["turns"]
			hp_lost_sum += r["hp_lost"]
			shots += r["shots"]
			hits += r["hits"]
		print("SIM diff=%s realm=%d boss=%s battles=%d win_rate=%.0f%% avg_turns=%.1f avg_hp_lost=%.0f carol_hit_rate=%.0f%%" % [
			gs.DIFFICULTY_NAMES[diff], realm + 1, str(boss), n, 100.0 * wins / n, float(turns_sum) / n, hp_lost_sum / n,
			100.0 * hits / maxi(1, shots)])
	quit(0)


func _battle(diff: int, realm: int, boss: bool, seed_value: int) -> Dictionary:
	gs.new_run(diff, seed_value)
	gs.start_realm(realm)
	if realm >= 2:
		gs.give_weapon("super_soaker")
	gs.energy_drinks = 1
	gs.pending_node = gs.map_data["boss_id"] if boss else gs.available_nodes()[0]
	change_scene_to_file("res://scenes/tactical/TacticalBattlefield.tscn")
	await process_frame
	await process_frame
	var b = current_scene
	var guard := 0
	while not b.ready_done and guard < 300:
		await process_frame
		guard += 1
	var shots := 0
	var hits := 0
	var start_hp: float = b.carol.hp
	while not b.is_ended() and b.turn_number < 40:
		var acted := true
		var safety := 0
		while acted and b.is_player_phase() and safety < 10:
			safety += 1
			acted = false
			if b.carol.hp < 35.0 and gs.energy_drinks > 0 and b.carol.ap >= gs.DRINK_AP:
				acted = b.use_drink()
				continue
			var best_e = null
			var best_w := ""
			var best_v := 0.0
			for w in gs.weapons:
				gs.equipped_weapon = w
				var wd = gs.current_weapon()
				if b.carol.ap < wd.ap_cost:
					continue
				for e in b.enemies:
					if not b.is_enemy_targetable(e):
						continue
					var v: float = b.player_hit_chance(e) * wd.damage
					if v > best_v:
						best_v = v
						best_e = e
						best_w = w
			if best_e != null:
				gs.equipped_weapon = best_w
				var hp_before: float = best_e.hp
				shots += 1
				acted = await b.player_attack(best_e)
				if best_e.hp < hp_before:
					hits += 1
				continue
			# Move one tile toward the nearest enemy.
			if b.carol.ap >= 1 and not b.enemies.is_empty():
				var target: Vector2i = b.enemies[0].cell
				var best_d := 9999
				for e in b.enemies:
					var d := CombatMath.manhattan(e.nearest_cell(b.carol.cell), b.carol.cell)
					if d < best_d:
						best_d = d
						target = e.nearest_cell(b.carol.cell)
				var step := Vector2i(-1, -1)
				var step_d := best_d
				for c in b.reachable_cells:
					if b.reachable_cells[c] != 1:
						continue
					var d := CombatMath.manhattan(c, target)
					if d < step_d:
						step_d = d
						step = c
				if step.x >= 0:
					acted = await b.player_move(step)
		if b.is_ended():
			break
		if b.is_player_phase():
			await b.end_player_turn()
		else:
			await process_frame
	var win: bool = b.is_ended() and not b.carol.is_dead()
	return {"win": win, "turns": b.turn_number, "hp_lost": start_hp - b.carol.hp, "shots": shots, "hits": hits}
```

## I. Web sources (checked 2026-11-12)
- Dungeon Crawler Carl ™ / © notice: https://arcadeheroes.com/news/press-releases/multimorphic-inc-launches-dungeon-crawler-carl-for-the-p³-pinball-platform/
- Licensed tabletop games: https://renegadegamestudios.com/blog/renegade-game-studios-announces-two-upcoming-dungeon-crawler-carl-tabletop-games/
- Peacock series and games: https://comicbookmovie.com/sci_fi/dungeon-crawler-carl-games-arrive-next-month-while-peacocks-live-action-series-gears-up-to-shoot-a230569?rc=fm
- Steam releases in 2025: https://www.gamingonlinux.com/2025/12/over-19000-games-have-released-on-steam-in-2025-with-nearly-half-seeing-fewer-than-10-reviews · https://howtomarketagame.com/2026/01/08/how-many-games-were-released-in-2025/
- Steam AI disclosure (Jan 2026): https://www.notebookcheck.net/Steam-updates-AI-disclosure-form-requiring-developers-to-report-visible-and-in-game-AI-but-not-background-tools.1206103.0.html · https://gigazine.net/gsc_news/en/20260120-steam-updates-ai-disclosure-guidelines
- Comparable 2025 releases: https://www.dekudeals.com/items/rogue-tactics · https://www.gamedeveloper.com/press-release/liberation-starts-as-valiant-tactics-launches-on-steam-today-
- Roguelite solo hit: https://www.gamesradar.com/games/roguelike/another-roguelike-success-story-has-hit-steam-d-and-d-flavored-slot-machine-slots-and-daggers-sells-100-000-copies-in-10-days-a-surreal-number-for-a-solo-dev-like-me
