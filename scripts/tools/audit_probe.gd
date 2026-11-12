extends SceneTree
## Audit probe: measures pathing consistency, refresh cost, cover distribution, fog-vs-range
## gaps, balance numbers and overworld pacing. Prints a plain-text report.
## godot --headless --script res://scripts/tools/audit_probe.gd

var gs: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	gs = root.get_node("GameState")
	root.get_node("SaveManager").base_dir = "user://audit_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://audit_saves"))
	Engine.time_scale = 8.0
	await _battles()
	_balance()
	_overworld()
	quit(0)


func _battles() -> void:
	var rooms := 0
	var reach_total := 0
	var reach_mismatch := 0
	var mismatch_over_ap := 0
	var cover_counts := [0, 0, 0, 0] # open, half, full, no-LOS
	var fog_seen_no_los := 0
	var fog_seen := 0
	var t_range := 0.0
	var t_refresh := 0.0
	var t_fog := 0.0
	var samples := 0
	for i in 40:
		gs.new_run(1, 9000 + i)
		gs.start_realm(i % 4)
		gs.pending_node = gs.available_nodes()[0]
		change_scene_to_file("res://scenes/tactical/TacticalBattlefield.tscn")
		await process_frame
		while current_scene == null or current_scene.name != "TacticalBattlefield":
			await process_frame
		var b = current_scene
		var guard := 0
		while not b.ready_done and guard < 200:
			await process_frame
			guard += 1
		await physics_frame
		rooms += 1
		var prev_scene = b
		var g = b.grid
		# 1) BFS reachable vs weighted A* path length.
		for c in b.reachable_cells:
			reach_total += 1
			var d: int = b.reachable_cells[c]
			var path: Array = g.move_path(b.carol.cell, c, b.carol.ap, b.occupied_cells(b.carol))
			if path.size() - 1 != d:
				reach_mismatch += 1
				if path.size() - 1 > b.carol.ap:
					mismatch_over_ap += 1
		# 2) Cover distribution: ranged shots from every walkable cell to every enemy within 7 tiles.
		for c in g.all_cells():
			if not g.is_walkable(c):
				continue
			for e in b.enemies:
				var t: Vector2i = e.nearest_cell(c)
				if CombatMath.distance(c, t) > 7.0 or c == t:
					continue
				if not g.has_los(c, t):
					cover_counts[3] += 1
				else:
					cover_counts[g.cover_between(c, t)] += 1
		# 3) Fog: cells shown as visible that the ray says are not in LOS.
		for c in g.visible_cells:
			fog_seen += 1
			if not g.has_los(b.carol.cell, c):
				fog_seen_no_los += 1
		# 4) Timing.
		var t0 := Time.get_ticks_usec()
		b.attack_range_cells()
		t_range += (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		b._refresh_player_view()
		t_refresh += (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		b._update_fog()
		t_fog += (Time.get_ticks_usec() - t0) / 1000.0
		samples += 1
	print("PROBE rooms=%d" % rooms)
	print("PROBE reachable_cells=%d path_len_mismatch=%d mismatch_beyond_AP=%d" % [reach_total, reach_mismatch, mismatch_over_ap])
	var tot := 0
	for v in cover_counts:
		tot += v
	print("PROBE ranged_shots=%d open=%.1f%% half=%.1f%% full=%.1f%% noLOS=%.1f%%" % [tot, 100.0 * cover_counts[0] / tot, 100.0 * cover_counts[1] / tot, 100.0 * cover_counts[2] / tot, 100.0 * cover_counts[3] / tot])
	var avg: float = (0.85 * cover_counts[0] + 0.60 * cover_counts[1] + 0.35 * cover_counts[2]) / float(tot - cover_counts[3])
	print("PROBE mean_hit_when_shot_possible=%.1f%%" % (avg * 100.0))
	print("PROBE fog_visible=%d visible_without_LOS=%d" % [fog_seen, fog_seen_no_los])
	print("PROBE ms attack_range_cells=%.2f refresh_player_view=%.2f update_fog=%.2f" % [t_range / samples, t_refresh / samples, t_fog / samples])


func _balance() -> void:
	var weapons := {}
	for w in Roster.WEAPONS:
		weapons[w["id"]] = w
	for diff in 4:
		var row: Dictionary = gs.DIFFICULTY_TABLE[diff]
		for realm in 4:
			var mult := 1.0 + 0.2 * realm
			var pool := Roster.enemies_for_realm(realm, false)
			var hp_sum := 0.0
			var dmg_sum := 0.0
			var ranged := 0
			var outranges := 0
			for id in pool:
				for e in Roster.ENEMIES:
					if e["id"] == id:
						hp_sum += e["hp"] * row["hp"]
						dmg_sum += e["dmg"] * row["dmg"]
						if e["proj"] != "":
							ranged += 1
							if int(e["range"]) > int(row["sight"]):
								outranges += 1
			var boss_id := Roster.boss_for_realm(realm)
			var boss: Dictionary = {}
			for e in Roster.ENEMIES:
				if e["id"] == boss_id:
					boss = e
			var boss_hp: float = boss["hp"] * row["hp"]
			var boss_dmg: float = boss["dmg"] * row["dmg"]
			var best := "nailgun" if realm < 2 else "super_soaker"
			var wdmg: float = weapons[best]["dmg"] * mult
			print("BAL diff=%s realm=%d avg_enemy_hp=%.0f avg_enemy_dmg=%.1f boss_hp=%.0f boss_hit=%.0f carol_hits_to_die_vs_boss=%d best_ranged=%s dmg=%.0f boss_shots_open=%.1f boss_shots_full=%.1f sword_hits_avg_enemy=%.1f ranged_enemies_outranging_sight=%d/%d" % [
				gs.DIFFICULTY_NAMES[diff], realm + 1, hp_sum / pool.size(), dmg_sum / pool.size(), boss_hp, boss_dmg,
				int(ceil(100.0 / boss_dmg)), best, wdmg, boss_hp / (wdmg * 0.85), boss_hp / (wdmg * 0.35),
				(hp_sum / pool.size()) / (25.0 * mult), outranges, ranged])
	for w in Roster.WEAPONS:
		print("WPN %s dmg=%.0f ap=%d range=%d exp_dmg_per_AP_open=%.2f half=%.2f full=%.2f" % [w["id"], w["dmg"], w["ap"], w["range"],
			w["dmg"] * 0.85 / w["ap"], w["dmg"] * (0.85 if not w["ranged"] else 0.60) / w["ap"], w["dmg"] * (0.85 if not w["ranged"] else 0.35) / w["ap"]])


func _overworld() -> void:
	var n := 0
	var nodes_sum := 0
	var layers_sum := 0
	var boss_not_last := 0
	var shortest_sum := 0
	var longest_sum := 0
	var types := {"combat": 0, "hazard": 0, "supply": 0, "boss": 0}
	for realm in 4:
		for s in 50:
			var m: Dictionary = OverworldGenerator.generate(500 + s * 31 + realm, realm)
			n += 1
			nodes_sum += m["nodes"].size()
			layers_sum += int(m["layer_count"])
			var boss: int = m["boss_id"]
			if int(m["nodes"][boss]["layer"]) != int(m["layer_count"]) - 1:
				boss_not_last += 1
			for node in m["nodes"]:
				types[node["type"]] += 1
			# Shortest / longest node count from layer 0 to the boss (BFS / DFS).
			var best := 999
			var worst := 0
			for start in m["nodes"]:
				if int(start["layer"]) != 0:
					continue
				var r := _path_lengths(m, int(start["id"]), boss)
				best = mini(best, r.x)
				worst = maxi(worst, r.y)
			shortest_sum += best
			longest_sum += worst
	print("MAP maps=%d avg_nodes=%.1f avg_layers=%.1f boss_not_in_last_layer=%d shortest_path_nodes=%.1f longest_path_nodes=%.1f" % [n, float(nodes_sum) / n, float(layers_sum) / n, boss_not_last, float(shortest_sum) / n, float(longest_sum) / n])
	print("MAP node_types %s" % str(types))


func _path_lengths(m: Dictionary, from: int, to: int) -> Vector2i:
	var memo := {}
	return _dfs(m, from, to, memo)


func _dfs(m: Dictionary, cur: int, to: int, memo: Dictionary) -> Vector2i:
	if cur == to:
		return Vector2i(1, 1)
	if memo.has(cur):
		return memo[cur]
	var best := 999
	var worst := -999
	for e in m["nodes"][cur]["edges"]:
		var r := _dfs(m, int(e), to, memo)
		if r.x < 999:
			best = mini(best, r.x + 1)
			worst = maxi(worst, r.y + 1)
	var out := Vector2i(best, worst if worst > 0 else 0)
	memo[cur] = out
	return out
