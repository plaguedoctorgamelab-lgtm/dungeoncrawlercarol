class_name TacticalBattlefield
extends Node2D
## XCOM-style isometric tactical battle on a 128x64 grid under a fixed Camera2D: map
## generation, turn manager (Player Phase -> Enemy AI Phase), 4 AP economy, cover-based
## hit chances, Carol's abilities (Dash, Shove), telegraphed enemy intents, tweened
## projectiles, fog of war, juice (hit-stop, shake, sound) and victory/defeat flow.
## Enemy decision-making lives in EnemyAI.gd.

signal player_turn_started
signal enemy_phase_finished
signal battle_ended(victory: bool)

const CAROL_SCENE := preload("res://scenes/units/CarolUnit.tscn")
const ENEMY_SCENE := preload("res://scenes/units/EnemyUnit.tscn")
const PENNY_SCENE := preload("res://scenes/units/PrincessPenny.tscn")
const DROP_SCENE := preload("res://scenes/items/TacticalDrop.tscn")
const PROJECTILE_SCENE := preload("res://scenes/tactical/Projectile.tscn")
const ENEMY_AI := preload("res://scenes/tactical/EnemyAI.gd")

enum Phase { SETUP, PLAYER, BUSY, ENEMY, ENDED }

const SPIKE_DAMAGE := 8.0
## Spikes hurt monsters more (they get shoved onto them on purpose).
const ENEMY_SPIKE_DAMAGE := 15.0
## Damage when a shoved monster slams into something solid.
const SLAM_DAMAGE := 10.0
## A boss's telegraphed (charged) strike hits this much harder than a normal attack.
const BOSS_STRIKE_MULT := 1.3
## Dash makes the next enemy attack on Carol this much less likely to hit.
const DASH_EVADE := 0.25
const DROP_CHANCE := 0.3
## Room sizes (tiles). Regular rooms are 10x10 to 12x12; boss rooms are 12x12.
const ROOM_MIN := 10
const ROOM_MAX := 12
## Shifts the fixed camera so tall sprites in the back row clear the top HUD bar.
const CAMERA_NUDGE := Vector2(0, -36)

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
## EnemyAI.gd instance (untyped so its methods resolve at runtime).
var ai
var reachable_cells: Dictionary = {}
var hovered_cell := Vector2i(-1, -1)
## "" (normal), "dash" or "shove": what the next click does.
var mode: String = ""
var dash_used: bool = false
## Tests set this to 0.0 (always hit) or 1.0 (always miss). Negative = random.
var forced_roll: float = -1.0
var ready_done: bool = false
## Tests and the auto-play sim turn hit-stop off so time_scale stays predictable.
var juice_enabled: bool = true
var _hitstop_active: bool = false


func _ready() -> void:
	node_id = GameState.pending_node
	# Seeded from the run, so the same run + node always builds the same room.
	rng.seed = GameState.battle_seed(node_id)
	is_boss_battle = node_id >= 0 and not GameState.map_data.is_empty() and GameState.is_boss_node(node_id)
	overlay.grid = grid
	ai = ENEMY_AI.new(self)
	_build_map()
	_spawn_units()
	# Fixed, non-moving camera: the whole 10x10-12x12 room fits the 1920x1080 view at 1:1.
	camera.position = grid.center_world() + CAMERA_NUDGE
	camera.zoom = Vector2.ONE
	hud.bind(self)
	GameState.begin_battle(node_id)
	_update_fog()
	var realm_name: String = Roster.REALM_NAMES[GameState.realm]
	if is_boss_battle:
		var boss := enemies[0]
		SignalBus.say("BOSS: %s - \"%s\"" % [boss.display_name, boss.data.flavor_text], UiKit.YELLOW)
		AudioManager.play_music("boss")
		AudioManager.play_sfx("boss_intro")
	else:
		SignalBus.say("%s ambush! Smarmy squad incoming." % realm_name, UiKit.PINK)
		AudioManager.play_music(AudioManager.realm_track(GameState.realm))
	# Let the physics server register the LOS colliders before the first raycast.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_update_fog()
	ready_done = true
	start_player_turn()


# ------------------------------------------------------------------ setup

func _build_map() -> void:
	var size := ROOM_MAX if is_boss_battle else rng.randi_range(ROOM_MIN, ROOM_MAX)
	var floor_tex: Texture2D = SpriteScaler.texture("%s_iso" % Roster.REALM_FLOORS[GameState.realm], "tile")
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
		var count := 3 + (1 if layer >= 4 else 0)
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
			# 2x2 boss: anchor cell plus the three cells right/below it.
			c = Vector2i(grid.width - 4, grid.height / 2 - 1)
			for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				reserved.append(c + d)
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
		e.place(spawn_cells[i], unit_world(e, spawn_cells[i]))
		e.died.connect(_on_enemy_died)
		if e.data.is_boss:
			e.alerted = true
		enemies.append(e)
	carol.face(enemies[0].position)

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


## Cover is laid out as deliberate "fighting positions": small L- and line-shaped clusters
## of crates and vending machines across the middle of the room, plus a few loose props,
## so both sides regularly have cover to fight from. Every walkable tile stays connected.
func _place_terrain(reserved: Array[Vector2i], start: Vector2i) -> void:
	var crate: Texture2D = SpriteScaler.texture("cover_wooden_crate", "cover")
	var vending: Texture2D = SpriteScaler.texture("cover_vending_machine", "cover")
	var spikes: Texture2D = SpriteScaler.texture("hazard_spikes_iso", "item")
	var shapes: Array = [
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(0, 0), Vector2i(0, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	]
	var clusters := 4 + (1 if grid.width >= 12 else 0)
	var tries := 0
	var made := 0
	while made < clusters and tries < 120:
		tries += 1
		var anchor := Vector2i(rng.randi_range(2, grid.width - 4), rng.randi_range(1, grid.height - 3))
		var shape: Array = shapes[rng.randi_range(0, shapes.size() - 1)]
		var placed_any := false
		for k in shape.size():
			var c: Vector2i = anchor + shape[k]
			# One vending machine (full cover) per cluster at most; the rest are crates.
			var is_vending: bool = k == 0 and rng.randf() < 0.55
			if _try_blocker(c, is_vending, reserved, start, crate, vending):
				placed_any = true
		if placed_any:
			made += 1
	var loose := rng.randi_range(2, 4)
	tries = 0
	while loose > 0 and tries < 100:
		tries += 1
		var c := Vector2i(rng.randi_range(0, grid.width - 1), rng.randi_range(0, grid.height - 1))
		if _try_blocker(c, rng.randf() < 0.3, reserved, start, crate, vending):
			loose -= 1
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


func _try_blocker(c: Vector2i, is_vending: bool, reserved: Array[Vector2i], start: Vector2i, crate: Texture2D, vending: Texture2D) -> bool:
	if not grid.in_bounds(c) or reserved.has(c) or grid.blockers.has(c) or CombatMath.manhattan(c, start) <= 1:
		return false
	grid.add_blocker(c, "vending" if is_vending else "crate", vending if is_vending else crate, is_vending)
	if grid.connected_count(start) != grid.walkable_count():
		_remove_last_blocker(c)
		return false
	return true


func _remove_last_blocker(c: Vector2i) -> void:
	grid.remove_blocker(c)


# ------------------------------------------------------------------ queries

## World position of a unit anchored at `c` (the middle of its footprint).
func unit_world(u: BattleUnit, c: Vector2i) -> Vector2:
	var last := c + Vector2i(u.size_cells - 1, u.size_cells - 1)
	return (grid.cell_to_world(c) + grid.cell_to_world(last)) / 2.0


func occupied_cells(except: Node2D = null) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if carol and carol != except:
		out.append(carol.cell)
	for e in enemies:
		if e != except and not e.is_dead():
			out.append_array(e.footprint())
	return out


func enemy_at(c: Vector2i) -> EnemyUnit:
	for e in enemies:
		if e.occupies(c) and not e.is_dead():
			return e
	return null


func is_enemy_targetable(e: EnemyUnit) -> bool:
	if e == null or e.is_dead():
		return false
	if e.revealed_until >= turn_number:
		return true
	for c in e.footprint():
		if grid.is_cell_visible(c):
			return true
	return false


## Cover the target gets against a shot (melee ignores cover).
func attack_cover(from: Vector2i, to: Vector2i, ranged: bool) -> int:
	return grid.cover_between(from, to) if ranged else CombatMath.COVER_NONE


func attack_chance(from: Vector2i, to: Vector2i, ranged: bool) -> float:
	var los := grid.has_los(from, to) if ranged else true
	return CombatMath.hit_chance(attack_cover(from, to, ranged), los)


func in_weapon_range(w: WeaponData, from: Vector2i, to: Vector2i) -> bool:
	if not w.is_ranged:
		return CombatMath.manhattan(from, to) == 1
	return CombatMath.distance(from, to) <= w.max_range_tiles + 0.01


## Hit chance Carol has against an enemy with the equipped weapon (0 if out of range).
func player_hit_chance(e: EnemyUnit) -> float:
	var w := GameState.current_weapon()
	var t := e.nearest_cell(carol.cell)
	if not in_weapon_range(w, carol.cell, t):
		return 0.0
	return attack_chance(carol.cell, t, w.is_ranged)


## Cells the equipped weapon can reach from Carol's tile (drawn in neon pink).
func attack_range_cells() -> Dictionary:
	var out := {}
	var w := GameState.current_weapon()
	for c in grid.all_cells():
		if c == carol.cell or not in_weapon_range(w, carol.cell, c):
			continue
		if w.is_ranged and not grid.has_los(carol.cell, c):
			continue
		out[c] = true
	return out


## Tiles that charging bosses will strike next turn.
func danger_zone() -> Dictionary:
	var out := {}
	for e in enemies:
		if not e.is_dead():
			for c in e.strike_zone():
				out[c] = true
	return out


## Visible, alerted enemies that could hit Carol if she ended her turn on `cell`.
func threats_at(cell: Vector2i) -> Array[EnemyUnit]:
	var out: Array[EnemyUnit] = []
	for e in enemies:
		if e.is_dead() or not e.alerted or not is_enemy_targetable(e):
			continue
		if ai.threatens(e, cell):
			out.append(e)
	return out


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
	dash_used = false
	mode = ""
	phase = Phase.PLAYER
	SignalBus.phase_changed.emit("PLAYER PHASE - TURN %d" % turn_number)
	AudioManager.play_sfx("turn_player")
	_refresh_player_view()
	player_turn_started.emit()


func end_player_turn() -> void:
	if phase != Phase.PLAYER:
		return
	phase = Phase.ENEMY
	mode = ""
	overlay.clear_all()
	hud.update_all()
	SignalBus.phase_changed.emit("ENEMY PHASE")
	AudioManager.play_sfx("turn_enemy")
	await _enemy_phase()
	if phase != Phase.ENDED:
		start_player_turn()


func _refresh_player_view() -> void:
	var player := phase == Phase.PLAYER
	if player and mode == "dash":
		reachable_cells = grid.reachable(carol.cell, GameState.DASH_TILES, occupied_cells(carol))
	elif player:
		reachable_cells = grid.reachable(carol.cell, carol.ap, occupied_cells(carol))
	else:
		reachable_cells = {}
	overlay.move_cells = reachable_cells if mode != "shove" else {}
	overlay.danger_cells = danger_zone()
	overlay.dash_mode = mode == "dash"
	overlay.targets.clear()
	overlay.range_cells = attack_range_cells() if player and mode == "" and carol.ap >= GameState.current_weapon().ap_cost else {}
	if player:
		for e in enemies:
			if not is_enemy_targetable(e):
				continue
			var col: Color
			if mode == "shove":
				col = UiKit.YELLOW if can_shove(e) else Color(1, 0.9, 0.2, 0.25)
			else:
				var chance := player_hit_chance(e)
				col = UiKit.PINK if chance > 0.0 and carol.ap >= GameState.current_weapon().ap_cost else Color(1, 0.4, 0.8, 0.4)
			for c in e.footprint():
				overlay.targets[c] = col
	_update_intents()
	_update_hover()
	hud.update_all()


## Each enemy shows what it will do next turn: attack Carol where she stands, move,
## charge (bosses), or nothing yet (hasn't noticed her).
func _update_intents() -> void:
	for e in enemies:
		if e.is_dead():
			continue
		if e.charged:
			e.intent = "charge"
		elif not e.alerted:
			e.intent = "unaware"
		elif ai.threatens(e, carol.cell):
			e.intent = "attack"
		else:
			e.intent = "move"
		e.queue_redraw()


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
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if mode != "":
			set_mode("")
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4:
				equip_index(event.keycode - KEY_1)
			KEY_H:
				use_drink()
			KEY_Q:
				set_mode("" if mode == "dash" else "dash")
			KEY_F:
				set_mode("" if mode == "shove" else "shove")
			KEY_ESCAPE:
				if mode != "":
					set_mode("")
					get_viewport().set_input_as_handled()
			KEY_E, KEY_SPACE, KEY_ENTER:
				end_player_turn()


func set_mode(m: String) -> bool:
	if phase != Phase.PLAYER:
		return false
	if m == "dash":
		if dash_used:
			SignalBus.say("Dash already used this turn.", UiKit.RED)
			return false
		if carol.ap < GameState.DASH_AP:
			SignalBus.say("Need %d AP to Dash." % GameState.DASH_AP, UiKit.RED)
			return false
		SignalBus.say("DASH: click a tile up to %d away (1 AP). Next enemy attack on Carol gets -25%%. Right-click to cancel." % GameState.DASH_TILES, UiKit.TEAL)
	elif m == "shove":
		if carol.ap < GameState.SHOVE_AP:
			SignalBus.say("Need %d AP to Shove." % GameState.SHOVE_AP, UiKit.RED)
			return false
		SignalBus.say("SHOVE: click a monster next to Carol (2 AP). Push it onto spikes or out of cover! Right-click to cancel.", UiKit.YELLOW)
	mode = m
	AudioManager.play_sfx("ui_click")
	_refresh_player_view()
	return true


func _update_hover() -> void:
	overlay.hover_cell = hovered_cell
	overlay.path.clear()
	var info := ""
	var e := enemy_at(hovered_cell)
	if is_enemy_targetable(e):
		if mode == "shove":
			SignalBus.hit_preview.emit(-1.0, "")
			info = "Shove %s%s" % [e.display_name, "" if can_shove(e) else " - must be next to Carol (bosses can't be shoved)"]
		else:
			var w := GameState.current_weapon()
			var t := e.nearest_cell(carol.cell)
			var chance := player_hit_chance(e)
			var why := ""
			if not in_weapon_range(w, carol.cell, t):
				why = "OUT OF RANGE"
			elif chance <= 0.0:
				why = "NO LINE OF SIGHT"
			else:
				why = "MELEE" if not w.is_ranged else CombatMath.COVER_NAMES[attack_cover(carol.cell, t, true)]
				if carol.ap < w.ap_cost:
					why += " - need %d AP" % w.ap_cost
			SignalBus.hit_preview.emit(chance, "%s  HP %d/%d  [%s]" % [e.display_name, int(e.hp), int(e.max_hp), why])
			info = "%s - %s\nNext turn: %s\n\"%s\"" % [e.display_name, e.data.role, EnemyUnit.INTENT_TEXT.get(e.intent, ""), e.data.flavor_text]
	else:
		SignalBus.hit_preview.emit(-1.0, "")
		if reachable_cells.has(hovered_cell) and mode != "shove":
			overlay.path = grid.move_path(carol.cell, hovered_cell, GameState.DASH_TILES if mode == "dash" else carol.ap, occupied_cells(carol))
			var cost: int = GameState.DASH_AP if mode == "dash" else reachable_cells[hovered_cell]
			var threats := threats_at(hovered_cell)
			var danger := "Safe from the monsters you can see." if threats.is_empty() else "DANGER: %d monster%s can hit you here." % [threats.size(), "" if threats.size() == 1 else "s"]
			if danger_zone().has(hovered_cell):
				danger = "RED ZONE: a charging boss strikes this tile next turn!  " + danger
			var best_cover := 0
			for t in threats:
				if t.data.is_ranged:
					best_cover = maxi(best_cover, grid.cover_between(t.nearest_cell(hovered_cell), hovered_cell))
			if not threats.is_empty():
				danger += "  Your cover: %s." % CombatMath.COVER_NAMES[best_cover]
			info = "%s here: %d AP%s\n%s" % ["Dash" if mode == "dash" else "Move", cost, "  (SPIKES! -%d HP)" % int(SPIKE_DAMAGE) if grid.hazards.has(hovered_cell) else "", danger]
	hud.set_hover_info(info)
	overlay.queue_redraw()


func click_cell(c: Vector2i) -> void:
	if phase != Phase.PLAYER:
		return
	var e := enemy_at(c)
	if mode == "shove":
		if e != null and is_enemy_targetable(e):
			await player_shove(e)
		return
	if mode == "dash":
		if reachable_cells.has(c):
			await player_dash(c)
		return
	if is_enemy_targetable(e):
		await player_attack(e)
	elif reachable_cells.has(c):
		await player_move(c)


func equip_index(i: int) -> void:
	if i >= 0 and i < GameState.weapons.size():
		GameState.equipped_weapon = GameState.weapons[i]
		SignalBus.say("Equipped %s." % GameState.current_weapon().display_name, UiKit.TEAL)
		SignalBus.inventory_changed.emit()
		AudioManager.play_sfx("ui_click")
		if phase == Phase.PLAYER:
			_refresh_player_view()


# ------------------------------------------------------------------ player actions

func player_move(target: Vector2i) -> bool:
	if phase != Phase.PLAYER or mode != "" or not reachable_cells.has(target):
		return false
	var path := grid.move_path(carol.cell, target, carol.ap, occupied_cells(carol))
	if path.size() < 2 or path[path.size() - 1] != target or path.size() - 1 > carol.ap:
		return false
	phase = Phase.BUSY
	overlay.clear_all()
	for i in range(1, path.size()):
		AudioManager.play_sfx("step")
		await carol.step_to(path[i], grid.cell_to_world(path[i]))
		carol.ap -= 1
		_after_carol_step()
		if phase == Phase.ENDED:
			return true
	phase = Phase.PLAYER
	_refresh_player_view()
	return true


## Dash: once per turn, 1 AP to move up to 2 tiles. The next enemy attack on Carol gets -25%.
func player_dash(target: Vector2i) -> bool:
	if phase != Phase.PLAYER or dash_used or carol.ap < GameState.DASH_AP:
		return false
	var path := grid.move_path(carol.cell, target, GameState.DASH_TILES, occupied_cells(carol))
	if path.size() < 2 or path[path.size() - 1] != target:
		return false
	phase = Phase.BUSY
	mode = ""
	overlay.clear_all()
	dash_used = true
	carol.ap -= GameState.DASH_AP
	carol.evasive = true
	AudioManager.play_sfx("dash")
	for i in range(1, path.size()):
		await carol.dash_to(path[i], grid.cell_to_world(path[i]))
		_after_carol_step()
		if phase == Phase.ENDED:
			return true
	SignalBus.say("Carol DASHES! The next attack on her is 25% less likely to hit.", UiKit.TEAL)
	phase = Phase.PLAYER
	_refresh_player_view()
	return true


func can_shove(e: EnemyUnit) -> bool:
	return e != null and not e.is_dead() and e.size_cells == 1 and CombatMath.manhattan(e.cell, carol.cell) == 1 and carol.ap >= GameState.SHOVE_AP


## Shove: 2 AP, push an adjacent (non-boss) monster one tile straight away from Carol.
## Spikes deal 15, slamming into something solid deals 10, and it loses any cover it had.
func player_shove(e: EnemyUnit) -> bool:
	if phase != Phase.PLAYER or not can_shove(e):
		return false
	phase = Phase.BUSY
	mode = ""
	overlay.clear_all()
	carol.ap -= GameState.SHOVE_AP
	SignalBus.ap_changed.emit(carol.ap, carol.max_ap)
	await carol.play_shove(e.position)
	var dir := e.cell - carol.cell
	var dest := e.cell + dir
	var blocked := not grid.is_walkable(dest) or occupied_cells(e).has(dest)
	if blocked:
		AudioManager.play_sfx("slam")
		var dmg := SLAM_DAMAGE * GameState.carol_damage_mult()
		_popup(e, "SLAM -%d" % int(dmg), UiKit.YELLOW)
		SignalBus.say("Carol slams %s into the wall for %d!" % [e.display_name, int(dmg)], UiKit.YELLOW)
		await e.lunge(grid.cell_to_world(dest))
		shake(6.0)
		e.take_damage(dmg)
	else:
		AudioManager.play_sfx("shove")
		await e.step_to(dest, grid.cell_to_world(dest))
		SignalBus.say("Carol shoves %s back!" % e.display_name, UiKit.YELLOW)
		await enemy_stepped(e, ENEMY_SPIKE_DAMAGE)
	if phase == Phase.BUSY:
		phase = Phase.PLAYER
		_refresh_player_view()
	return true


func _after_carol_step() -> void:
	_update_fog()
	SignalBus.ap_changed.emit(carol.ap, carol.max_ap)
	for d in drops.duplicate():
		if is_instance_valid(d) and d.cell == carol.cell:
			drops.erase(d)
			AudioManager.play_sfx("pickup")
			SignalBus.say(d.collect(), UiKit.GREEN)
			SignalBus.inventory_changed.emit()
	if grid.hazards.has(carol.cell):
		AudioManager.play_sfx("spikes")
		_damage_carol(SPIKE_DAMAGE, "Spike trap! Carol takes %d damage." % int(SPIKE_DAMAGE), carol.position)


## Called after an enemy steps (or is shoved) onto a tile: spike traps hurt monsters too.
func enemy_stepped(e: EnemyUnit, spike_damage: float = ENEMY_SPIKE_DAMAGE) -> void:
	if e.is_dead() or not grid.hazards.has(e.cell):
		return
	AudioManager.play_sfx("spikes")
	if e.visible:
		_popup(e, "-%d" % int(spike_damage), UiKit.YELLOW)
		SignalBus.say("%s lands on the spikes! -%d HP" % [e.display_name, int(spike_damage)], UiKit.YELLOW)
	e.take_damage(spike_damage)


func player_attack(e: EnemyUnit) -> bool:
	if phase != Phase.PLAYER or not is_enemy_targetable(e):
		return false
	var w := GameState.current_weapon()
	if carol.ap < w.ap_cost:
		SignalBus.say("Not enough AP for the %s (needs %d)." % [w.display_name, w.ap_cost], UiKit.RED)
		return false
	var t := e.nearest_cell(carol.cell)
	if not in_weapon_range(w, carol.cell, t):
		SignalBus.say("%s is out of range." % e.display_name, UiKit.RED)
		return false
	var chance := attack_chance(carol.cell, t, w.is_ranged)
	if chance <= 0.0:
		SignalBus.say("No line of sight - something solid is in the way!", UiKit.RED)
		return false
	phase = Phase.BUSY
	overlay.clear_all()
	carol.ap -= w.ap_cost
	SignalBus.ap_changed.emit(carol.ap, carol.max_ap)
	AudioManager.play_sfx(_weapon_sfx(w))
	await carol.play_attack(e.position, not w.is_ranged)
	await _fire(carol, e, w.projectile, w.projectile_tint)
	if _roll() < chance:
		var dmg := w.damage * GameState.carol_damage_mult() * rng.randf_range(0.9, 1.1) * (1.0 - e.data.damage_reduction)
		_popup(e, "-%d" % int(dmg), UiKit.YELLOW)
		SignalBus.say("%s hits %s for %d! (%d%%)" % [w.display_name, e.display_name, int(dmg), int(chance * 100)], Color.WHITE)
		AudioManager.play_sfx("hit")
		shake(4.0 if w.is_ranged else 7.0)
		hitstop(0.07)
		e.take_damage(dmg)
	else:
		AudioManager.play_sfx("miss")
		_popup(e, "MISS!", Color("#bbbbbb"))
		SignalBus.say("Carol misses %s. (%d%% chance)" % [e.display_name, int(chance * 100)], Color("#bbbbbb"))
	if phase == Phase.BUSY:
		phase = Phase.PLAYER
		_refresh_player_view()
	return true


func _weapon_sfx(w: WeaponData) -> String:
	match w.weapon_id:
		"super_soaker":
			return "shoot_water"
		"nailgun":
			return "shoot_nail"
		"squeak_hammer":
			return "squeak"
		_:
			return "swing"


func use_drink() -> bool:
	if phase != Phase.PLAYER:
		return false
	if GameState.energy_drinks <= 0:
		SignalBus.say("No Energy Drinks left!", UiKit.RED)
		return false
	if carol.ap < GameState.DRINK_AP:
		SignalBus.say("Need %d AP to chug a drink." % GameState.DRINK_AP, UiKit.RED)
		return false
	GameState.energy_drinks -= 1
	carol.ap -= GameState.DRINK_AP
	carol.heal(GameState.DRINK_HEAL)
	GameState.carol_hp = carol.hp
	AudioManager.play_sfx("drink")
	carol.play_drink()
	_popup(carol, "+%d" % int(GameState.DRINK_HEAL), UiKit.GREEN)
	SignalBus.say("RADICAL! Carol chugs an Energy Drink (+%d HP)." % int(GameState.DRINK_HEAL), UiKit.GREEN)
	SignalBus.hp_changed.emit(carol.hp, carol.max_hp)
	SignalBus.inventory_changed.emit()
	_refresh_player_view()
	return true


# ------------------------------------------------------------------ enemy phase

func _enemy_phase() -> void:
	for e in enemies.duplicate():
		if phase == Phase.ENDED:
			return
		if e.is_dead():
			continue
		await ai.act(e)
		if carol.is_dead():
			return
	enemy_phase_finished.emit()


## Used by the enemy AI to resolve one attack on Carol.
func enemy_attack(e: EnemyUnit) -> void:
	var was_hidden := not e.visible
	e.visible = true
	# Stays visible through Carol's next turn so she can answer it.
	e.revealed_until = turn_number + 1
	if was_hidden:
		SignalBus.say("An attack from the darkness! It's %s!" % e.display_name, UiKit.PINK)
	var from := e.nearest_cell(carol.cell)
	var chance := attack_chance(from, carol.cell, e.data.is_ranged)
	var evaded := carol.evasive
	if evaded:
		chance = maxf(0.05, chance - DASH_EVADE)
		carol.evasive = false
	carol.face(e.position)
	if e.data.is_ranged:
		AudioManager.play_sfx("enemy_shoot")
		await _fire(e, carol, e.data.projectile, Color.WHITE)
	else:
		AudioManager.play_sfx("enemy_swing")
		await e.lunge(carol.position)
	if _roll() < chance:
		var dmg := e.attack_damage() * rng.randf_range(0.9, 1.1)
		if e.data.is_boss:
			dmg *= BOSS_STRIKE_MULT
			hitstop(0.12)
		_damage_carol(dmg, "%s hits Carol for %d! (%d%%)" % [e.display_name, int(dmg), int(chance * 100)], e.position)
	else:
		AudioManager.play_sfx("miss")
		_popup(carol, "DODGED!" if evaded else "MISS!", Color("#bbbbbb"))
		carol.play_dodge(e.position)
		SignalBus.say("%s misses! (%d%% chance%s)" % [e.display_name, int(chance * 100), ", dash bonus" if evaded else ""], Color("#bbbbbb"))


func _damage_carol(dmg: float, text: String, from_pos: Vector2) -> void:
	carol.take_damage(dmg)
	GameState.carol_hp = carol.hp
	AudioManager.play_sfx("carol_hurt")
	shake(9.0)
	_popup(carol, "-%d" % int(dmg), UiKit.RED)
	SignalBus.say(text, UiKit.RED)
	SignalBus.hp_changed.emit(carol.hp, carol.max_hp)
	if carol.is_dead():
		_defeat()
	else:
		carol.play_hurt(from_pos)


# ------------------------------------------------------------------ effects

## Tweened projectile in the y-sorted Objects layer so it depth-sorts with units and props.
func _fire(from: Node2D, to: Node2D, data: ProjectileData, tint: Color) -> void:
	var p: Sprite2D = PROJECTILE_SCENE.instantiate()
	grid.objects.add_child(p)
	await p.launch(from.position, to.position, data, tint)


func _popup(unit: Node2D, text: String, color: Color) -> void:
	var lift: float = 150.0 * (unit.size_cells if unit is BattleUnit else 1)
	var screen := get_viewport().get_canvas_transform() * (unit.position + Vector2(0, -lift))
	hud.popup_text(screen, text, color)


## Brief freeze-frame on big hits so they land with weight.
func hitstop(seconds: float) -> void:
	if not juice_enabled or _hitstop_active or not is_inside_tree():
		return
	_hitstop_active = true
	var prev := Engine.time_scale
	Engine.time_scale = prev * 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = prev
	_hitstop_active = false


## Camera shake (the HUD stays still because it lives on its own CanvasLayer).
func shake(strength: float) -> void:
	if not juice_enabled or not is_inside_tree() or not AudioManager.screen_shake:
		return
	var tw := create_tween()
	for i in 6:
		var k := strength * (1.0 - i / 6.0)
		tw.tween_property(camera, "offset", Vector2(rng.randf_range(-k, k), rng.randf_range(-k, k)), 0.03)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.04)


# ------------------------------------------------------------------ outcomes

func _on_enemy_died(u: BattleUnit) -> void:
	var e := u as EnemyUnit
	enemies.erase(e)
	GameState.enemies_defeated += 1
	SignalBus.say("%s has been DOWNSIZED!" % e.display_name, UiKit.YELLOW)
	AudioManager.play_sfx("enemy_death")
	if not e.data.is_boss and rng.randf() < DROP_CHANCE:
		var d: Node2D = DROP_SCENE.instantiate()
		grid.objects.add_child(d)
		d.setup(e.cell, grid.cell_to_world(e.cell))
		drops.append(d)
	e.play_death()
	if enemies.is_empty():
		_victory()


func _victory() -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	mode = ""
	overlay.clear_all()
	for d in drops:
		if is_instance_valid(d):
			SignalBus.say(d.collect(), UiKit.GREEN)
	drops.clear()
	GameState.battles_won += 1
	GameState.carol_hp = carol.hp
	battle_ended.emit(true)
	SignalBus.battle_finished.emit(true)
	AudioManager.play_music("victory", false)
	carol.play_victory()
	if is_boss_battle and GameState.realm == GameState.REALM_COUNT - 1:
		SignalBus.say("The Sea Lord is defeated! The cage is cracking!", UiKit.PINK)
		if penny:
			AudioManager.play_sfx("cage_break")
			await penny.break_cage()
		GameState.battle_in_progress = -1
		hud.show_result("PRINCESS PENNY RESCUED!", "The Sea Lord's boardroom cage shatters. Penny high-fives Carol and fires up a REAL espresso machine.", [["VICTORY!", _go_victory]])
	elif is_boss_battle:
		var next := GameState.realm + 1
		GameState.battle_in_progress = -1
		hud.show_result("REALM CLEARED!", "%s is free of smarmy management. Next stop: %s.\nCarol is fully healed, gains +%d max HP and hits harder." % [Roster.REALM_NAMES[GameState.realm], Roster.REALM_NAMES[next], int(GameState.CAROL_HP_PER_REALM)], [["ONWARD!", _go_next_realm]])
	else:
		GameState.heal(GameState.VICTORY_HEAL)
		if node_id >= 0:
			GameState.complete_node(node_id)
		hud.show_result("SQUAD SQUASHED!", "Carol catches her breath (+%d HP)." % int(GameState.VICTORY_HEAL), [["BACK TO MAP", _go_overworld]])


func _defeat() -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	mode = ""
	overlay.clear_all()
	GameState.carol_hp = 0.0
	battle_ended.emit(false)
	SignalBus.battle_finished.emit(false)
	AudioManager.play_music("defeat", false)
	carol.play_death()
	if GameState.is_permadeath():
		# Wipe every slot holding this run, so a copy in another slot can't dodge it.
		SaveManager.wipe_run(GameState.run_seed)
		SaveManager.wipe_save(GameState.active_slot)
		GameState.battle_in_progress = -1
		hud.show_result("PERMADEATH!", "Carol got permanently downsized. Every save of this EXTREME run has been wiped.\nThe run restarts at Level 1.", [["RESTART AT LEVEL 1", _restart_run], ["TITLE SCREEN", _go_title]])
	else:
		var buttons: Array = []
		if SaveManager.has_save(GameState.active_slot):
			buttons.append(["LOAD LAST SAVE", _load_last])
		buttons.append(["TITLE SCREEN", _go_title])
		hud.show_result("CAROL GOT DOWNSIZED", "The corporate monsters win this round...", buttons)


func _go_overworld() -> void:
	get_tree().change_scene_to_file("res://scenes/overworld/NodeMap.tscn")


func _go_next_realm() -> void:
	GameState.start_realm(GameState.realm + 1)
	GameState.overworld_banner = "%s - %s" % [Roster.REALM_NAMES[GameState.realm], Roster.REALM_SUBTITLES[GameState.realm]]
	if GameState.realm_gift != "":
		GameState.overworld_banner += "\n" + GameState.realm_gift
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
	if SaveManager.load_game(GameState.active_slot):
		_go_overworld()
	else:
		_go_title()
