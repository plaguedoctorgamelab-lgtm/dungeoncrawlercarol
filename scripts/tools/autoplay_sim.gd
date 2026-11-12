extends SceneTree
## Auto-play balance sim. A greedy bot plays real TacticalBattlefield battles through the
## game's own API and records win rate, turns, HP lost and Carol's hit rate.
## godot --headless --path . --script res://scripts/tools/autoplay_sim.gd [-- <battles per row>]
## Bot policy: drink if HP < 35 and a drink is left; otherwise attack the best expected-damage
## target with the best weapon; otherwise step toward the nearest enemy; then end turn.
## It answers one telegraph (steps out of a charging boss's red danger zone) but otherwise
## never seeks cover, never Dashes or Shoves, so results are a floor for a careful human.

var gs: Node
var battles_per_row: int = 40


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	gs = root.get_node("GameState")
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		battles_per_row = maxi(1, int(args[0]))
	root.get_node("SaveManager").base_dir = "user://eval_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://eval_saves"))
	Engine.time_scale = 30.0
	var configs := [
		[1, 0, false], [1, 0, true], [1, 2, false], [1, 3, true],
		[3, 0, false], [3, 0, true], [3, 3, false], [3, 3, true],
		[0, 3, true], [2, 3, true],
	]
	var only_bosses := OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "bosses"
	for cfg in configs:
		if only_bosses and not cfg[2]:
			continue
		var diff: int = cfg[0]
		var realm: int = cfg[1]
		var boss: bool = cfg[2]
		var n := battles_per_row
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
	# Mirror the real game's guaranteed drops: the Mallet in realm 1, the Soaker by Fire.
	gs.give_weapon("squeak_hammer")
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
	b.juice_enabled = false
	var shots := 0
	var hits := 0
	var start_hp: float = b.carol.hp
	while not b.is_ended() and b.turn_number < 40:
		# Read the telegraph: step out of reach of a CHARGING boss before doing anything else.
		await _dodge_charge(b)
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


## Answer a CHARGING boss: step out of its red danger zone by the shortest move. Costs AP,
## exactly like a human reading the telegraph.
func _dodge_charge(b) -> void:
	if not b.is_player_phase():
		return
	var zone: Dictionary = b.danger_zone()
	if not zone.has(b.carol.cell):
		return
	var best := Vector2i(-1, -1)
	var best_d := 999
	for c in b.reachable_cells:
		if not zone.has(c) and b.reachable_cells[c] < best_d:
			best_d = b.reachable_cells[c]
			best = c
	if best.x >= 0:
		await b.player_move(best)
