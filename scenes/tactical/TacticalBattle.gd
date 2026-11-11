extends Node2D
## Tactical isometric battle: map generation, turn manager (Player Phase -> Enemy AI Phase),
## attacks with projectiles and hit-chance rolls, fog of war, victory/defeat flow.

signal player_turn_started
signal enemy_phase_finished
signal battle_ended(victory: bool)

const CAROL_SCENE := preload("res://scenes/units/CarolUnit.tscn")
const ENEMY_SCENE := preload("res://scenes/units/EnemyUnit.tscn")
const PENNY_SCENE := preload("res://scenes/units/PrincessPenny.tscn")
const DROP_SCENE := preload("res://scenes/items/TacticalDrop.tscn")
const PROJECTILE_SCENE := preload("res://scenes/tactical/Projectile.tscn")

enum Phase { SETUP, PLAYER, BUSY, ENEMY, ENDED }

const SPIKE_DAMAGE := 8.0
const DROP_CHANCE := 0.3

@onready var grid: IsometricGrid = $Grid
@onready var overlay: Node2D = $Grid/Overlay
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD

var phase: int = Phase.SETUP
var carol: CarolUnit
var enemies: Array[EnemyUnit] = []
var drops: Array[Node2D] = []
var penny: Node2D
var node_id: int = -1
var is_boss_battle: bool = false
var turn_number: int = 0
var rng := RandomNumberGenerator.new()
var reachable_cells: Dictionary = {}
var hovered_cell := Vector2i(-1, -1)
## Tests set this to 0.0 (always hit) or 1.0 (always miss). Negative = random.
var forced_roll: float = -1.0
var ready_done: bool = false


func _ready() -> void:
	rng.randomize()
	node_id = GameState.pending_node
	is_boss_battle = node_id >= 0 and not GameState.map_data.is_empty() and GameState.is_boss_node(node_id)
	overlay.grid = grid
	_build_map()
	_spawn_units()
	camera.position = grid.center_world() + Vector2(0, 6)
	camera.zoom = Vector2(2.4, 2.4) if grid.width <= 12 else Vector2(2.2, 2.2)
	hud.bind(self)
	_update_fog()
	var realm_name: String = Roster.REALM_NAMES[GameState.realm]
	if is_boss_battle:
		var boss := enemies[0]
		SignalBus.say("BOSS: %s - \"%s\"" % [boss.display_name, boss.data.flavor_text], UiKit.YELLOW)
	else:
		SignalBus.say("%s ambush! Smarmy squad incoming." % realm_name, UiKit.PINK)
	# Let the physics server register the LOS colliders before the first raycast.
	await get_tree().physics_frame
	await get_tree().physics_frame
	ready_done = true
	start_player_turn()


# ------------------------------------------------------------------ setup

func _build_map() -> void:
	var size := 13 if is_boss_battle else 12
	var floor_tex: Texture2D = load("res://assets/sprites/%s_iso.png" % Roster.REALM_FLOORS[GameState.realm])
	grid.build(size, size, floor_tex)


func _carol_start() -> Vector2i:
	return Vector2i(1, grid.height / 2)


func _spawn_units() -> void:
	var start := _carol_start()
	# Pick enemy roster first so we can reserve their spawn cells.
	var ids: Array[String] = []
	if is_boss_battle:
		ids.append(Roster.boss_for_realm(GameState.realm))
		var pool := Roster.enemies_for_realm(GameState.realm, false)
		for i in 2:
			ids.append(pool[rng.randi_range(0, pool.size() - 1)])
	else:
		var pool := Roster.enemies_for_realm(GameState.realm, false)
		var layer := 0
		if node_id >= 0 and not GameState.map_data.is_empty():
			layer = int(GameState.map_data["nodes"][node_id]["layer"])
		var count := 2 + (1 if layer >= 2 else 0) + (1 if layer >= 5 else 0)
		if GameState.difficulty == GameState.Difficulty.EASY:
			count = maxi(2, count - 1)
		for i in mini(count, 4):
			ids.append(pool[rng.randi_range(0, pool.size() - 1)])

	var reserved: Array[Vector2i] = [start]
	var spawn_cells: Array[Vector2i] = []
	var penny_cell := Vector2i(-1, -1)
	if is_boss_battle and GameState.realm == GameState.REALM_COUNT - 1:
		penny_cell = Vector2i(grid.width - 1, grid.height / 2)
		reserved.append(penny_cell)
	for i in ids.size():
		var c: Vector2i
		if i == 0 and is_boss_battle:
			c = Vector2i(grid.width - 3, grid.height / 2)
		else:
			c = _random_cell(grid.width - 4, grid.width - 1, reserved)
		spawn_cells.append(c)
		reserved.append(c)

	if penny_cell.x >= 0:
		grid.add_blocker(penny_cell, "cage", null, false)
	_place_terrain(reserved, start)

	carol = CAROL_SCENE.instantiate()
	grid.objects.add_child(carol)
	carol.place(start, grid.cell_to_world(start))

	for i in ids.size():
		var e: EnemyUnit = ENEMY_SCENE.instantiate()
		grid.objects.add_child(e)
		e.setup(GameState.enemy_data(ids[i]), GameState.enemy_hp_scale())
		e.place(spawn_cells[i], grid.cell_to_world(spawn_cells[i]))
		e.died.connect(_on_enemy_died)
		if e.data.is_boss:
			e.alerted = true
		enemies.append(e)

	if penny_cell.x >= 0:
		penny = PENNY_SCENE.instantiate()
		grid.objects.add_child(penny)
		penny.cell = penny_cell
		penny.position = grid.cell_to_world(penny_cell)


func _random_cell(min_x: int, max_x: int, avoid: Array[Vector2i]) -> Vector2i:
	for attempt in 200:
		var c := Vector2i(rng.randi_range(min_x, max_x), rng.randi_range(0, grid.height - 1))
		if not avoid.has(c) and grid.is_walkable(c):
			return c
	for c in grid.all_cells():
		if not avoid.has(c) and grid.is_walkable(c):
			return c
	return Vector2i.ZERO


## Cover objects and spike traps, keeping every walkable tile connected.
func _place_terrain(reserved: Array[Vector2i], start: Vector2i) -> void:
	var crate: Texture2D = UiKit.sprite("cover_wooden_crate")
	var vending: Texture2D = UiKit.sprite("cover_vending_machine")
	var spikes: Texture2D = UiKit.sprite("hazard_spikes_iso")
	var wanted := rng.randi_range(12, 17)
	var placed := 0
	var tries := 0
	while placed < wanted and tries < 300:
		tries += 1
		var c := Vector2i(rng.randi_range(0, grid.width - 1), rng.randi_range(0, grid.height - 1))
		if reserved.has(c) or grid.blockers.has(c) or CombatMath.manhattan(c, start) <= 1:
			continue
		var is_vending := rng.randf() < 0.4
		grid.add_blocker(c, "vending" if is_vending else "crate", vending if is_vending else crate, is_vending)
		if grid.connected_count(start) != grid.walkable_count():
			# Undo: would cut the map in two.
			_remove_last_blocker(c)
			continue
		placed += 1
	var spike_count := rng.randi_range(3, 6)
	var s := 0
	tries = 0
	while s < spike_count and tries < 200:
		tries += 1
		var c := Vector2i(rng.randi_range(2, grid.width - 2), rng.randi_range(0, grid.height - 1))
		if reserved.has(c) or grid.blockers.has(c) or grid.hazards.has(c):
			continue
		grid.add_hazard(c, spikes)
		s += 1


func _remove_last_blocker(c: Vector2i) -> void:
	grid.remove_blocker(c)
	# Also drop the LOS body if one was created for this cell.
	for child in grid.get_children():
		if child is StaticBody2D and grid.world_to_cell(child.position) == c:
			child.queue_free()
			child.collision_layer = 0


# ------------------------------------------------------------------ queries

func occupied_cells(except: Node2D = null) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if carol and carol != except:
		out.append(carol.cell)
	for e in enemies:
		if e != except and not e.is_dead():
			out.append(e.cell)
	return out


func enemy_at(c: Vector2i) -> EnemyUnit:
	for e in enemies:
		if e.cell == c and not e.is_dead():
			return e
	return null


func is_enemy_targetable(e: EnemyUnit) -> bool:
	return e != null and not e.is_dead() and (grid.is_cell_visible(e.cell) or e.revealed_until >= turn_number)


func attack_chance(from: Vector2i, to: Vector2i, ranged: bool) -> float:
	var los := grid.has_los(from, to) if ranged else true
	return CombatMath.hit_chance(ranged, CombatMath.distance(from, to), los)


func in_weapon_range(w: WeaponData, from: Vector2i, to: Vector2i) -> bool:
	if not w.is_ranged:
		return CombatMath.manhattan(from, to) == 1
	return CombatMath.distance(from, to) <= w.max_range_tiles + 0.01


## Hit chance Carol has against an enemy with the equipped weapon (0 if out of range).
func player_hit_chance(e: EnemyUnit) -> float:
	var w := GameState.current_weapon()
	if not in_weapon_range(w, carol.cell, e.cell):
		return 0.0
	return attack_chance(carol.cell, e.cell, w.is_ranged)


func is_ended() -> bool:
	return phase == Phase.ENDED


func is_player_phase() -> bool:
	return phase == Phase.PLAYER


func _roll() -> float:
	return forced_roll if forced_roll >= 0.0 else rng.randf()


# ------------------------------------------------------------------ turn flow

func start_player_turn() -> void:
	if phase == Phase.ENDED:
		return
	turn_number += 1
	carol.ap = carol.max_ap
	phase = Phase.PLAYER
	SignalBus.phase_changed.emit("PLAYER PHASE - TURN %d" % turn_number)
	_refresh_player_view()
	player_turn_started.emit()


func end_player_turn() -> void:
	if phase != Phase.PLAYER:
		return
	phase = Phase.ENEMY
	overlay.clear_all()
	hud.update_all()
	SignalBus.phase_changed.emit("ENEMY PHASE")
	await _enemy_phase()
	if phase != Phase.ENDED:
		start_player_turn()


func _refresh_player_view() -> void:
	reachable_cells = grid.reachable(carol.cell, carol.ap, occupied_cells(carol)) if phase == Phase.PLAYER else {}
	overlay.move_cells = reachable_cells
	overlay.targets.clear()
	if phase == Phase.PLAYER:
		for e in enemies:
			if is_enemy_targetable(e):
				var chance := player_hit_chance(e)
				overlay.targets[e.cell] = UiKit.RED if chance > 0.0 and carol.ap >= GameState.current_weapon().ap_cost else Color(1, 0.4, 0.8, 0.5)
	_update_hover()
	hud.update_all()


func _update_fog() -> void:
	grid.update_fog(carol.cell, GameState.sight_radius())
	for e in enemies:
		e.visible = is_enemy_targetable(e)
	for d in drops:
		if is_instance_valid(d):
			d.visible = grid.explored.has(d.cell)


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.PLAYER:
		return
	if event is InputEventMouseMotion:
		hovered_cell = grid.world_to_cell(get_global_mouse_position())
		_update_hover()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_cell(grid.world_to_cell(get_global_mouse_position()))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4:
				equip_index(event.keycode - KEY_1)
			KEY_H:
				use_drink()
			KEY_E, KEY_SPACE, KEY_ENTER:
				end_player_turn()


func _update_hover() -> void:
	overlay.hover_cell = hovered_cell
	overlay.path.clear()
	var info := ""
	var e := enemy_at(hovered_cell)
	if is_enemy_targetable(e):
		var w := GameState.current_weapon()
		var chance := player_hit_chance(e)
		var why := ""
		if not in_weapon_range(w, carol.cell, e.cell):
			why = " (out of range)"
		elif chance <= 0.0:
			why = " (no line of sight)"
		elif carol.ap < w.ap_cost:
			why = " (need %d AP)" % w.ap_cost
		SignalBus.hit_preview.emit(chance, "%s  HP %d/%d%s" % [e.display_name, int(e.hp), int(e.max_hp), why])
		info = "%s - %s\n\"%s\"" % [e.display_name, e.data.role, e.data.flavor_text]
	else:
		SignalBus.hit_preview.emit(-1.0, "")
		if reachable_cells.has(hovered_cell):
			overlay.path = grid.find_path(carol.cell, hovered_cell, occupied_cells(carol))
			info = "Move here: %d AP%s" % [reachable_cells[hovered_cell], "  (SPIKES! -%d HP)" % int(SPIKE_DAMAGE) if grid.hazards.has(hovered_cell) else ""]
	hud.set_hover_info(info)
	overlay.queue_redraw()


func click_cell(c: Vector2i) -> void:
	if phase != Phase.PLAYER:
		return
	var e := enemy_at(c)
	if is_enemy_targetable(e):
		await player_attack(e)
	elif reachable_cells.has(c):
		await player_move(c)


func equip_index(i: int) -> void:
	if i >= 0 and i < GameState.weapons.size():
		GameState.equipped_weapon = GameState.weapons[i]
		SignalBus.say("Equipped %s." % GameState.current_weapon().display_name, UiKit.TEAL)
		SignalBus.inventory_changed.emit()
		if phase == Phase.PLAYER:
			_refresh_player_view()


# ------------------------------------------------------------------ player actions

func player_move(target: Vector2i) -> bool:
	if phase != Phase.PLAYER or not reachable_cells.has(target):
		return false
	var path := grid.find_path(carol.cell, target, occupied_cells(carol))
	if path.size() < 2 or path[path.size() - 1] != target or path.size() - 1 > carol.ap:
		return false
	phase = Phase.BUSY
	overlay.clear_all()
	for i in range(1, path.size()):
		await carol.step_to(path[i], grid.cell_to_world(path[i]))
		carol.ap -= 1
		_after_carol_step()
		if phase == Phase.ENDED:
			return true
	phase = Phase.PLAYER
	_refresh_player_view()
	return true


func _after_carol_step() -> void:
	_update_fog()
	SignalBus.ap_changed.emit(carol.ap, carol.max_ap)
	for d in drops.duplicate():
		if is_instance_valid(d) and d.cell == carol.cell:
			drops.erase(d)
			SignalBus.say(d.collect(), UiKit.GREEN)
			SignalBus.inventory_changed.emit()
	if grid.hazards.has(carol.cell):
		_damage_carol(SPIKE_DAMAGE, "Spike trap! Carol takes %d damage." % int(SPIKE_DAMAGE))


func player_attack(e: EnemyUnit) -> bool:
	if phase != Phase.PLAYER or not is_enemy_targetable(e):
		return false
	var w := GameState.current_weapon()
	if carol.ap < w.ap_cost:
		SignalBus.say("Not enough AP for the %s (needs %d)." % [w.display_name, w.ap_cost], UiKit.RED)
		return false
	if not in_weapon_range(w, carol.cell, e.cell):
		SignalBus.say("%s is out of range." % e.display_name, UiKit.RED)
		return false
	var chance := attack_chance(carol.cell, e.cell, w.is_ranged)
	if chance <= 0.0:
		SignalBus.say("No line of sight - something solid is in the way!", UiKit.RED)
		return false
	phase = Phase.BUSY
	overlay.clear_all()
	carol.ap -= w.ap_cost
	SignalBus.ap_changed.emit(carol.ap, carol.max_ap)
	if not w.is_ranged:
		carol.lunge(e.position)
	await _fire(carol, e, w.projectile_texture, w.projectile_tint)
	if _roll() < chance:
		var dmg := w.damage * GameState.carol_damage_mult() * rng.randf_range(0.9, 1.1) * (1.0 - e.data.damage_reduction)
		_popup(e, "-%d" % int(dmg), UiKit.YELLOW)
		SignalBus.say("%s hits %s for %d! (%d%%)" % [w.display_name, e.display_name, int(dmg), int(chance * 100)], Color.WHITE)
		e.take_damage(dmg)
	else:
		_popup(e, "MISS!", Color("#bbbbbb"))
		SignalBus.say("Carol misses %s. (%d%% chance)" % [e.display_name, int(chance * 100)], Color("#bbbbbb"))
	if phase == Phase.BUSY:
		phase = Phase.PLAYER
		_refresh_player_view()
	return true


func use_drink() -> bool:
	if phase != Phase.PLAYER:
		return false
	if GameState.energy_drinks <= 0:
		SignalBus.say("No Energy Drinks left!", UiKit.RED)
		return false
	if carol.ap < 1:
		SignalBus.say("Need 1 AP to chug a drink.", UiKit.RED)
		return false
	GameState.energy_drinks -= 1
	carol.ap -= 1
	carol.heal(GameState.DRINK_HEAL)
	GameState.carol_hp = carol.hp
	_popup(carol, "+%d" % int(GameState.DRINK_HEAL), UiKit.GREEN)
	SignalBus.say("RADICAL! Carol chugs an Energy Drink (+%d HP)." % int(GameState.DRINK_HEAL), UiKit.GREEN)
	SignalBus.hp_changed.emit(carol.hp, carol.max_hp)
	SignalBus.inventory_changed.emit()
	_refresh_player_view()
	return true


# ------------------------------------------------------------------ enemy AI

func _enemy_phase() -> void:
	for e in enemies.duplicate():
		if phase == Phase.ENDED:
			return
		if e.is_dead():
			continue
		await _enemy_act(e)
		if carol.is_dead():
			return
	enemy_phase_finished.emit()


func _enemy_act(e: EnemyUnit) -> void:
	e.ap = e.max_ap
	if not e.alerted:
		if CombatMath.distance(e.cell, carol.cell) <= e.data.sight_radius_tiles:
			e.alerted = true
			if e.visible:
				SignalBus.say("%s spotted Carol!" % e.display_name, UiKit.PINK)
		else:
			return
	var attacked := false
	var guard := 0
	while e.ap > 0 and guard < 12 and phase != Phase.ENDED:
		guard += 1
		if not attacked and e.ap >= 2 and enemy_can_attack(e):
			await _enemy_attack(e)
			e.ap -= 2
			attacked = true
			if carol.is_dead():
				return
			continue
		if attacked:
			break
		var moved := await _enemy_step(e)
		e.ap -= 1
		if not moved:
			break


func enemy_can_attack(e: EnemyUnit) -> bool:
	if not e.data.is_ranged:
		return CombatMath.manhattan(e.cell, carol.cell) == 1
	return CombatMath.distance(e.cell, carol.cell) <= e.data.attack_range_tiles + 0.01 and grid.has_los(e.cell, carol.cell)


## Moves up to `tiles_per_ap` tiles toward Carol. Returns true if the unit moved.
func _enemy_step(e: EnemyUnit) -> bool:
	var moved := false
	for k in maxi(1, e.data.tiles_per_ap):
		if k > 0 and enemy_can_attack(e):
			break
		var path := grid.find_path(e.cell, carol.cell, occupied_cells(e))
		if path.size() < 2:
			break
		var next: Vector2i = path[1]
		if next == carol.cell or occupied_cells(e).has(next):
			break
		var seen := grid.is_cell_visible(e.cell) or grid.is_cell_visible(next)
		e.visible = seen
		await e.step_to(next, grid.cell_to_world(next), seen)
		moved = true
		e.visible = is_enemy_targetable(e)
	return moved


func _enemy_attack(e: EnemyUnit) -> void:
	var was_hidden := not e.visible
	e.visible = true
	e.revealed_until = turn_number
	if was_hidden:
		SignalBus.say("An attack from the darkness! It's %s!" % e.display_name, UiKit.PINK)
	var chance := attack_chance(e.cell, carol.cell, e.data.is_ranged)
	if e.data.is_ranged and e.data.projectile_texture:
		await _fire(e, carol, e.data.projectile_texture, Color.WHITE)
	else:
		await e.lunge(carol.position)
	if _roll() < chance:
		var dmg := e.attack_damage() * rng.randf_range(0.9, 1.1)
		_damage_carol(dmg, "%s hits Carol for %d! (%d%%)" % [e.display_name, int(dmg), int(chance * 100)])
	else:
		_popup(carol, "MISS!", Color("#bbbbbb"))
		SignalBus.say("%s misses! (%d%% chance)" % [e.display_name, int(chance * 100)], Color("#bbbbbb"))


func _damage_carol(dmg: float, text: String) -> void:
	carol.take_damage(dmg)
	GameState.carol_hp = carol.hp
	_popup(carol, "-%d" % int(dmg), UiKit.RED)
	SignalBus.say(text, UiKit.RED)
	SignalBus.hp_changed.emit(carol.hp, carol.max_hp)
	if carol.is_dead():
		_defeat()


# ------------------------------------------------------------------ effects

func _fire(from: Node2D, to: Node2D, tex: Texture2D, tint: Color) -> void:
	if tex == null:
		return
	var p: Sprite2D = PROJECTILE_SCENE.instantiate()
	grid.effects.add_child(p)
	await p.launch(from.position + Vector2(0, -12), to.position + Vector2(0, -12), tex, tint)


func _popup(unit: Node2D, text: String, color: Color) -> void:
	var screen := get_viewport().get_canvas_transform() * (unit.position + Vector2(0, -30))
	hud.popup_text(screen, text, color)


# ------------------------------------------------------------------ outcomes

func _on_enemy_died(u: BattleUnit) -> void:
	var e := u as EnemyUnit
	enemies.erase(e)
	GameState.enemies_defeated += 1
	SignalBus.say("%s has been DOWNSIZED!" % e.display_name, UiKit.YELLOW)
	if not e.data.is_boss and rng.randf() < DROP_CHANCE:
		var d: Node2D = DROP_SCENE.instantiate()
		grid.objects.add_child(d)
		d.setup(e.cell, grid.cell_to_world(e.cell))
		drops.append(d)
	var tw := e.create_tween()
	tw.tween_property(e, "modulate:a", 0.0, 0.3)
	tw.tween_callback(e.queue_free)
	if enemies.is_empty():
		_victory()


func _victory() -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	overlay.clear_all()
	for d in drops:
		if is_instance_valid(d):
			SignalBus.say(d.collect(), UiKit.GREEN)
	drops.clear()
	GameState.battles_won += 1
	GameState.carol_hp = carol.hp
	battle_ended.emit(true)
	SignalBus.battle_finished.emit(true)
	if is_boss_battle and GameState.realm == GameState.REALM_COUNT - 1:
		SignalBus.say("The Sea Lord is defeated! The cage is cracking!", UiKit.PINK)
		if penny:
			await penny.break_cage()
		hud.show_result("PRINCESS PENNY RESCUED!", "The Sea Lord's boardroom cage shatters. Penny high-fives Carol and fires up a REAL espresso machine.", [["VICTORY!", _go_victory]])
	elif is_boss_battle:
		var next := GameState.realm + 1
		hud.show_result("REALM CLEARED!", "%s is free of smarmy management. Next stop: %s.\nCarol is fully healed and hits harder." % [Roster.REALM_NAMES[GameState.realm], Roster.REALM_NAMES[next]], [["ONWARD!", _go_next_realm]])
	else:
		GameState.heal(GameState.VICTORY_HEAL)
		if node_id >= 0:
			GameState.complete_node(node_id)
		hud.show_result("SQUAD SQUASHED!", "Carol catches her breath (+%d HP)." % int(GameState.VICTORY_HEAL), [["BACK TO MAP", _go_overworld]])


func _defeat() -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	overlay.clear_all()
	GameState.carol_hp = 0.0
	battle_ended.emit(false)
	SignalBus.battle_finished.emit(false)
	if GameState.is_permadeath():
		SaveSystem.wipe_save(GameState.active_slot)
		hud.show_result("PERMADEATH!", "Carol got permanently downsized. Your EXTREME save file has been wiped.\nThe run restarts at Level 1.", [["RESTART AT LEVEL 1", _restart_run], ["TITLE SCREEN", _go_title]])
	else:
		var buttons: Array = []
		if SaveSystem.has_save(GameState.active_slot):
			buttons.append(["LOAD LAST SAVE", _load_last])
		buttons.append(["TITLE SCREEN", _go_title])
		hud.show_result("CAROL GOT DOWNSIZED", "The corporate monsters win this round...", buttons)


func _go_overworld() -> void:
	get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")


func _go_next_realm() -> void:
	GameState.start_realm(GameState.realm + 1)
	GameState.overworld_banner = "%s - %s" % [Roster.REALM_NAMES[GameState.realm], Roster.REALM_SUBTITLES[GameState.realm]]
	_go_overworld()


func _go_victory() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/VictoryScreen.tscn")


func _go_title() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")


func _restart_run() -> void:
	GameState.new_run(GameState.difficulty)
	GameState.overworld_banner = "PERMADEATH reset. Back to Level 1. Good luck."
	_go_overworld()


func _load_last() -> void:
	if SaveSystem.load_game(GameState.active_slot):
		_go_overworld()
	else:
		_go_title()
