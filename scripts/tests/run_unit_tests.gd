extends SceneTree
## Headless test runner (GDD section 8).
## godot --headless --script res://scripts/tests/run_unit_tests.gd
## Exits with the number of failed checks (0 = all passed).

var failures: int = 0
var checks: int = 0
var gs: Node
var save: Node


func _initialize() -> void:
	_run.call_deferred()


func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("  PASS  ", label)
	else:
		failures += 1
		printerr("  FAIL  ", label)


func _run() -> void:
	Engine.time_scale = 8.0
	gs = root.get_node("GameState")
	save = root.get_node("SaveManager")
	save.base_dir = "user://test_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves"))

	print("== HD display settings ==")
	_test_display()
	print("== Resources ==")
	_test_resources()
	print("== Combat math ==")
	_test_math()
	print("== Overworld generation ==")
	_test_overworld()
	print("== Title screen boot ==")
	await _test_title()
	print("== Overworld scene ==")
	await _test_overworld_scene()
	print("== Mock tactical turn ==")
	await _test_tactical()
	print("== Boss / rescue ==")
	await _test_final_boss()
	print("== Save system ==")
	_test_save()
	print("== Victory screen ==")
	await _test_victory()

	Engine.time_scale = 1.0
	print("\n%d checks, %d failures" % [checks, failures])
	print("RESULT: %s" % ("ALL TESTS PASSED" if failures == 0 else "FAILED"))
	quit(failures)


func _test_display() -> void:
	check(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1920 and int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 1080, "viewport is 1920x1080")
	check(int(ProjectSettings.get_setting("display/window/size/mode")) == 3, "boots fullscreen (mode 3)")
	check(String(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items" and String(ProjectSettings.get_setting("display/window/stretch/aspect")) == "keep", "stretch canvas_items / keep")
	check(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")) == 1, "linear texture filtering")
	check(gs.has_method("toggle_fullscreen"), "F11 fullscreen toggle in GameState")
	check(IsometricGrid.CELL == Vector2i(128, 64), "128x64 isometric tiles")
	# SpriteScaler: a raw 512x512 texture is normalized to each footprint.
	var img := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.create_from_image(img)
	var spr := Sprite2D.new()
	spr.texture = tex
	var drawn := SpriteScaler.fit(spr, SpriteScaler.UNIT)
	check(drawn.is_equal_approx(Vector2(128, 128)), "512px sprite scales to a 128x128 unit footprint")
	drawn = SpriteScaler.fit(spr, SpriteScaler.BOSS)
	check(drawn.is_equal_approx(Vector2(256, 256)), "512px sprite scales to a 256x256 boss footprint")
	drawn = SpriteScaler.fit(spr, SpriteScaler.PROJECTILE)
	check(drawn.is_equal_approx(Vector2(56, 56)), "512px sprite scales to a 56x56 projectile")
	spr.free()
	check(SpriteScaler.texture("definitely_missing_sprite") != null, "missing PNG falls back to a placeholder")
	var real: Texture2D = SpriteScaler.texture("carol_iso")
	check(real != null and real.get_width() >= 128, "HD sprites imported (carol %dpx)" % (real.get_width() if real else 0))


func _test_resources() -> void:
	var roster: GDScript = load("res://scripts/data/Roster.gd")
	check(roster.ENEMIES.size() == 24, "roster has 24 monsters")
	var bosses := 0
	for e in roster.ENEMIES:
		var d: EnemyData = load("res://resources/enemies/%s.tres" % e["id"])
		check(d != null and d.sprite_texture != null and d.max_hp == e["hp"], "enemy resource %s" % e["id"])
		if d and d.is_ranged:
			check(d.projectile_texture != null, "  %s has projectile art" % e["id"])
		if e["boss"]:
			bosses += 1
	check(bosses == 4, "4 realm bosses")
	for f in ["NeonSword", "SuperSoaker", "SqueakHammer", "Nailgun"]:
		var w: WeaponData = load("res://resources/weapons/%s.tres" % f)
		check(w != null and w.icon != null and w.projectile != null and w.ap_cost == 2, "weapon resource " + f + " (2 AP)")
	check(roster.PROJECTILES.size() == 15, "15 projectile definitions")
	var motions := {}
	for pd in roster.PROJECTILES:
		var p: ProjectileData = load("res://resources/projectiles/%s.tres" % pd["id"])
		check(p != null and p.texture != null and p.speed > 0.0, "projectile resource %s" % pd["id"])
		if p:
			motions[p.motion] = true
	check(motions.size() >= 4, "projectiles use %d motion styles" % motions.size())
	for e in roster.ENEMIES:
		var d: EnemyData = load("res://resources/enemies/%s.tres" % e["id"])
		if d.is_ranged and d.projectile == null:
			check(false, "%s missing ProjectileData" % e["id"])


func _test_math() -> void:
	check(is_equal_approx(CombatMath.hit_chance(CombatMath.COVER_NONE), 0.85), "open ground 85%")
	check(is_equal_approx(CombatMath.hit_chance(CombatMath.COVER_HALF), 0.60), "half cover 60%")
	check(is_equal_approx(CombatMath.hit_chance(CombatMath.COVER_FULL), 0.35), "full cover 35%")
	check(CombatMath.hit_chance(CombatMath.COVER_NONE, false) == 0.0, "no LOS = 0%")
	check(CombatMath.badge_text(0.6) == "60% HIT", "badge text reads 60% HIT")
	var mults := []
	for row in gs.DIFFICULTY_TABLE:
		mults.append(row["hp"])
	check(mults == [0.8, 1.0, 1.3, 1.6], "difficulty HP/DMG multipliers %s" % str(mults))
	check(gs.DIFFICULTY_TABLE[3]["permadeath"] and gs.DIFFICULTY_TABLE[3]["sight"] < gs.DIFFICULTY_TABLE[1]["sight"], "EXTREME: permadeath + tight fog")


func _test_overworld() -> void:
	for realm in 4:
		for s in 25:
			var m: Dictionary = OverworldGenerator.generate(1000 + s * 17 + realm, realm)
			var n: int = m["nodes"].size()
			var boss: int = m["boss_id"]
			var ok := n >= 15 and n <= 20 and boss >= int(ceil(n * 0.75)) and boss < n
			ok = ok and OverworldGenerator.reachable_from_start(m).has(boss)
			ok = ok and OverworldGenerator.boss_always_reachable(m)
			if not ok or s == 0:
				check(ok, "realm %d seed %d: %d nodes, boss at node %d" % [realm, s, n, boss + 1])


func _test_title() -> void:
	change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
	await process_frame
	await process_frame
	var title := current_scene
	check(title != null and title.name == "TitleScreen", "boots into TitleScreen")
	check(title.find_children("Difficulty*", "Button", true, false).size() == 4, "4 difficulty selectors")
	title.selected_difficulty = 1
	title.start_new_game()
	await process_frame
	await process_frame
	check(current_scene.name == "HowToPlay", "New Game shows the How to Play screen")
	check(current_scene.find_child("Sections", true, false).get_child_count() == 5, "instructions have 5 sections")
	current_scene.continue_to_map()
	await process_frame
	await process_frame
	check(current_scene.name == "NodeMap", "How to Play continues to the overworld")
	check(gs.map_data["nodes"].size() >= 15, "overworld generated with %d nodes" % gs.map_data["nodes"].size())


func _test_overworld_scene() -> void:
	var map := current_scene
	var avail: Array[int] = gs.available_nodes()
	check(avail.size() >= 2, "layer-0 nodes are selectable")
	# Force a supply node to test event resolution.
	var target: int = gs.map_data["nodes"][avail[0]]["edges"][0]
	gs.complete_node(avail[0])
	gs.map_data["nodes"][target]["type"] = "supply"
	var drinks_before: int = gs.energy_drinks
	var weapons_before: int = gs.weapons.size()
	map.refresh()
	map.choose_node(target)
	check(gs.energy_drinks > drinks_before or gs.weapons.size() > weapons_before, "supply cache gives loot")
	map.close_popup()
	await process_frame


func _start_battle(realm: int, boss: bool) -> Node:
	gs.new_run(1, 4242)
	gs.start_realm(realm)
	var node_id: int = gs.map_data["boss_id"] if boss else gs.available_nodes()[0]
	gs.pending_node = node_id
	change_scene_to_file("res://scenes/tactical/TacticalBattlefield.tscn")
	await process_frame
	var battle := current_scene
	var guard := 0
	while not battle.ready_done and guard < 200:
		await process_frame
		guard += 1
	return battle


func _test_tactical() -> void:
	var battle := await _start_battle(0, false)
	check(battle.name == "TacticalBattlefield", "tactical scene loaded")
	check(battle.is_player_phase(), "player phase starts")
	check(battle.carol.ap == 4, "Carol has 4 AP")
	check(battle.enemies.size() >= 2, "enemy squad spawned (%d)" % battle.enemies.size())
	var tiles: int = battle.grid.ground.get_used_cells().size()
	check(battle.grid.width >= 10 and battle.grid.width <= 12 and tiles == battle.grid.width * battle.grid.height, "%dx%d TileMapLayer floor" % [battle.grid.width, battle.grid.height])
	check(battle.camera.zoom == Vector2.ONE and battle.y_sort_enabled, "fixed 1:1 camera, y-sorted battlefield")
	var top: Vector2 = battle.grid.cell_to_world(Vector2i(0, 0))
	var bottom: Vector2 = battle.grid.cell_to_world(Vector2i(battle.grid.width - 1, battle.grid.height - 1))
	var left: Vector2 = battle.grid.cell_to_world(Vector2i(0, battle.grid.height - 1))
	var right: Vector2 = battle.grid.cell_to_world(Vector2i(battle.grid.width - 1, 0))
	check(right.x - left.x + 128 <= 1920 and bottom.y - top.y + 64 <= 1080 - 230, "room fits the 1920x1080 view between the HUD bars")
	var csprite: Sprite2D = battle.carol.sprite
	var csize: Vector2 = csprite.texture.get_size() * csprite.scale
	check(csize.x <= 128.5 and csize.y <= 128.5 and maxf(csize.x, csize.y) >= 127.5, "Carol drawn at a 128px footprint")
	check(battle.grid.is_cell_visible(battle.carol.cell), "fog: Carol's tile is visible")
	var far := Vector2i(battle.grid.width - 1, 0)
	check(not battle.grid.is_cell_visible(far), "fog: far corner hidden at sight %d" % gs.sight_radius())

	# LOS raycast: put a vending machine between two cells and test.
	var a := Vector2i(3, 1)
	var b := Vector2i(7, 1)
	var mid := Vector2i(5, 1)
	for c in [a, b, mid]:
		if battle.grid.blockers.has(c):
			battle._remove_last_blocker(c)
	await physics_frame
	var clear_before: bool = battle.grid.has_los(a, b)
	battle.grid.add_blocker(mid, "vending", UiKit.sprite("cover_vending_machine"), true)
	await physics_frame
	await physics_frame
	check(clear_before and not battle.grid.has_los(a, b), "RayCast2D LOS blocked by vending machine")
	check(battle.attack_chance(a, b, true) == 0.0, "blocked shot = 0% hit")
	battle._remove_last_blocker(mid)
	await physics_frame
	# Cover next to the target, on the attacker's side.
	var t := Vector2i(7, 5)
	var shooter := Vector2i(3, 5)
	var side := Vector2i(6, 5)
	var back := Vector2i(8, 5)
	for c in [t, shooter, side, back, Vector2i(5, 5), Vector2i(4, 5)]:
		if battle.grid.blockers.has(c):
			battle._remove_last_blocker(c)
	await physics_frame
	check(is_equal_approx(battle.attack_chance(shooter, t, true), 0.85), "open shot 85%")
	battle.grid.add_blocker(side, "crate", UiKit.sprite("cover_wooden_crate"), false)
	check(is_equal_approx(battle.attack_chance(shooter, t, true), 0.60), "crate = half cover 60%")
	battle._remove_last_blocker(side)
	battle.grid.add_blocker(side, "vending", UiKit.sprite("cover_vending_machine"), true)
	await physics_frame
	await physics_frame
	check(is_equal_approx(battle.attack_chance(shooter, t, true), 0.35), "vending machine = full cover 35%")
	battle._remove_last_blocker(side)
	battle.grid.add_blocker(back, "vending", UiKit.sprite("cover_vending_machine"), true)
	await physics_frame
	check(is_equal_approx(battle.attack_chance(shooter, t, true), 0.85), "flanked: cover on the far side doesn't help")
	battle._remove_last_blocker(back)
	await physics_frame
	battle._refresh_player_view()
	check(not battle.overlay.move_cells.is_empty(), "reachable tiles highlighted (cyan)")
	check(not battle.overlay.range_cells.is_empty(), "attack range highlighted (pink)")

	# Move Carol one step.
	var start: Vector2i = battle.carol.cell
	var dest := Vector2i(-1, -1)
	for c in battle.reachable_cells:
		if battle.reachable_cells[c] == 1:
			dest = c
			break
	var moved: bool = await battle.player_move(dest)
	check(moved and battle.carol.cell == dest and battle.carol.ap == 3, "move 1 tile costs 1 AP")

	# Teleport an enemy next to Carol and hit it with the sword (forced hit).
	var e = battle.enemies[0]
	var adj := Vector2i(-1, -1)
	for n in battle.grid.neighbors(battle.carol.cell):
		if battle.grid.is_walkable(n) and battle.enemy_at(n) == null:
			adj = n
			break
	e.place(adj, battle.grid.cell_to_world(adj))
	battle._update_fog()
	battle.forced_roll = 0.0
	gs.equipped_weapon = "neon_sword"
	var hp_before: float = e.hp
	var attacked: bool = await battle.player_attack(e)
	check(attacked and e.hp < hp_before, "star-sword melee hit deals damage (%d -> %d)" % [hp_before, e.hp])
	check(battle.carol.ap == 1, "melee costs 2 AP")
	var second: bool = await battle.player_attack(e)
	check(not second or e.is_dead(), "can't attack with 1 AP")
	gs.energy_drinks = 1
	check(not battle.use_drink(), "energy drink needs 2 AP")

	# End turn -> enemy phase -> back to player.
	battle.forced_roll = 1.0 # enemies always miss
	await battle.end_player_turn()
	check(battle.is_player_phase() and battle.turn_number == 2, "enemy phase ran and turn 2 started")
	check(battle.carol.ap == 4, "AP refilled")
	check(battle.use_drink() and battle.carol.ap == 2, "energy drink costs 2 AP")

	# Kill everything -> victory -> back to map.
	battle.forced_roll = 0.0
	for en in battle.enemies.duplicate():
		en.take_damage(9999)
	await process_frame
	check(battle.is_ended(), "battle ends when squad is gone")
	check(gs.visited.has(battle.node_id), "node marked complete")
	check(battle.hud.result_buttons().size() > 0, "victory result panel shown")
	battle.hud.result_buttons()[0].pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.name == "NodeMap", "returned to overworld")


func _test_final_boss() -> void:
	for realm in 4:
		var battle := await _start_battle(realm, true)
		var boss = battle.enemies[0]
		check(boss.data.is_boss and boss.data.enemy_id == Roster.boss_for_realm(realm), "realm %d boss: %s" % [realm + 1, boss.display_name])
		var bsize: Vector2 = boss.sprite.texture.get_size() * boss.sprite.scale
		check(boss.footprint().size() == 4 and maxf(bsize.x, bsize.y) >= 255.0, "boss covers 2x2 tiles at 256px")
		check(battle.enemy_at(boss.cell + Vector2i(1, 1)) == boss, "any boss tile targets the boss")
		if realm == 2:
			check(gs.weapons.has("super_soaker"), "Super Soaker 9000 owned by the Fire level")
		if realm < 3:
			for en in battle.enemies.duplicate():
				en.take_damage(9999)
			await process_frame
			battle.hud.result_buttons()[0].pressed.emit()
			await process_frame
			await process_frame
			check(gs.realm == realm + 1 and current_scene.name == "NodeMap", "boss %d clears realm -> realm %d" % [realm + 1, realm + 2])
		else:
			check(battle.penny != null and battle.penny.caged, "Princess Penny caged in the boardroom")
			for en in battle.enemies.duplicate():
				en.take_damage(9999)
			var guard := 0
			while battle.hud.result_buttons().is_empty() and guard < 400:
				await process_frame
				guard += 1
			check(not battle.penny.caged, "Sea Lord defeat breaks Penny's cage")
			battle.hud.result_buttons()[0].pressed.emit()
			await process_frame
			await process_frame
			check(current_scene.name == "VictoryScreen", "victory screen shown")


func _test_save() -> void:
	gs.new_run(0, 99)
	gs.complete_node(gs.available_nodes()[0])
	gs.carol_hp = 42.0
	check(save.save_game(1), "save to slot 1")
	check(FileAccess.file_exists("user://test_saves/savegame.json"), "savegame.json written")
	var nodes_before: int = gs.map_data["nodes"].size()
	gs.new_run(2, 5)
	check(save.load_game(1), "load slot 1")
	check(gs.carol_hp == 42.0 and gs.difficulty == 0 and gs.map_data["nodes"].size() == nodes_before, "loaded state matches")
	check(typeof(gs.map_data["boss_id"]) == TYPE_INT, "map ids restored as ints")
	# Save rules
	gs.difficulty = 2
	gs.current_node = -1
	gs.visited.clear()
	check(gs.can_save_now(), "Hard: save allowed at realm start")
	gs.complete_node(0)
	check(not gs.can_save_now(), "Hard: save blocked mid-realm")
	gs.difficulty = 1
	check(gs.can_save_now(), "Medium: save allowed at every node")
	save.wipe_save(1)
	gs.active_slot = 1
	check(gs.autosave(false) and save.has_save(1), "Medium auto-saves at the start of a room")
	save.wipe_save(1)
	gs.difficulty = 2
	check(not gs.autosave(false) and not save.has_save(1), "Hard skips room auto-saves")
	check(gs.autosave(true) and save.has_save(1), "Hard auto-saves at level start")
	save.wipe_save(1)
	# EXTREME permadeath wipe
	gs.new_run(3, 7)
	save.save_game(2)
	check(save.has_save(2), "EXTREME save exists")
	save.wipe_save(2)
	check(not save.has_save(2), "permadeath wipes the save file")
	save.wipe_save(1)


func _test_victory() -> void:
	change_scene_to_file("res://scenes/ui/VictoryScreen.tscn")
	await process_frame
	await process_frame
	check(current_scene.name == "VictoryScreen", "victory screen loads standalone")
