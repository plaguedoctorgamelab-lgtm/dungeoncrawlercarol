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
	save = root.get_node("SaveSystem")
	save.base_dir = "user://test_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves"))

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
		check(w != null and w.icon != null and w.projectile_texture != null, "weapon resource " + f)


func _test_math() -> void:
	check(is_equal_approx(CombatMath.hit_chance(true, 0.0, true), 0.85), "ranged base 85%")
	check(is_equal_approx(CombatMath.hit_chance(false, 1.0, true), 0.90), "melee adjacent 90%")
	check(is_equal_approx(CombatMath.hit_chance(true, 4.0, true), 0.65), "ranged 4 tiles = 65%")
	check(is_equal_approx(CombatMath.hit_chance(true, 20.0, true), 0.30), "30% floor")
	check(CombatMath.hit_chance(true, 2.0, false) == 0.0, "no LOS = 0%")


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
	check(current_scene.name == "OverworldMap", "New Game opens the overworld")
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
	change_scene_to_file("res://scenes/tactical/TacticalBattle.tscn")
	await process_frame
	var battle := current_scene
	var guard := 0
	while not battle.ready_done and guard < 200:
		await process_frame
		guard += 1
	return battle


func _test_tactical() -> void:
	var battle := await _start_battle(0, false)
	check(battle.name == "TacticalBattle", "tactical scene loaded")
	check(battle.is_player_phase(), "player phase starts")
	check(battle.carol.ap == 4, "Carol has 4 AP")
	check(battle.enemies.size() >= 2, "enemy squad spawned (%d)" % battle.enemies.size())
	check(battle.grid.ground.get_used_cells().size() == 144, "12x12 TileMapLayer floor")
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
	check(battle.use_drink() or gs.energy_drinks == 0, "energy drink usable for 1 AP")

	# End turn -> enemy phase -> back to player.
	battle.forced_roll = 1.0 # enemies always miss
	await battle.end_player_turn()
	check(battle.is_player_phase() and battle.turn_number == 2, "enemy phase ran and turn 2 started")
	check(battle.carol.ap == 4, "AP refilled")

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
	check(current_scene.name == "OverworldMap", "returned to overworld")


func _test_final_boss() -> void:
	for realm in 4:
		var battle := await _start_battle(realm, true)
		var boss = battle.enemies[0]
		check(boss.data.is_boss and boss.data.enemy_id == Roster.boss_for_realm(realm), "realm %d boss: %s" % [realm + 1, boss.display_name])
		if realm < 3:
			for en in battle.enemies.duplicate():
				en.take_damage(9999)
			await process_frame
			battle.hud.result_buttons()[0].pressed.emit()
			await process_frame
			await process_frame
			check(gs.realm == realm + 1 and current_scene.name == "OverworldMap", "boss %d clears realm -> realm %d" % [realm + 1, realm + 2])
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
