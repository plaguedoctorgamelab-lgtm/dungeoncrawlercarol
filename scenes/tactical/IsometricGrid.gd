class_name IsometricGrid
extends Node2D
## Isometric battlefield: 128x64 TileMapLayer floor, AStarGrid2D pathing, RayCast2D line of
## sight, XCOM-style cover, and a fog-of-war TileMapLayer.

enum Cover { NONE, HALF, FULL }

const CELL := Vector2i(128, 64)
## Cover value of each blocker kind (crates and trash cans = half, vending machines = full).
const COVER_OF := {"crate": Cover.HALF, "trash": Cover.HALF, "espresso": Cover.HALF, "vending": Cover.FULL, "fence": Cover.FULL, "rig": Cover.HALF, "rack": Cover.FULL, "cage": Cover.NONE}
const TRAP_DECAL := preload("res://scenes/tactical/TrapDecal.gd")
const ESPRESSO := preload("res://scenes/tactical/EspressoMachine.gd")
## Human-readable trap names for hover text.
const TRAP_NAMES := {"spikes": "SPIKE TRAP", "wire": "LIVE WIRE", "tape": "RED TAPE"}
const FOG_UNEXPLORED := Vector2i(0, 0)
const FOG_EXPLORED := Vector2i(1, 0)
const LOS_LAYER := 1

@onready var ground: TileMapLayer = $Ground
@onready var decals: Node2D = $Decals
@onready var overlay: Node2D = $Overlay
@onready var objects: Node2D = $Objects
@onready var fog: TileMapLayer = $Fog
@onready var effects: Node2D = $Effects
@onready var los_ray: RayCast2D = $LosRay

var width: int = 12
var height: int = 12
var astar := AStarGrid2D.new()
## cell -> kind ("crate", "vending", "cage")
var blockers: Dictionary = {}
## cell -> Sprite2D for cover objects
var blocker_sprites: Dictionary = {}
## cell -> StaticBody2D used by the LOS raycast (full cover only)
var los_bodies: Dictionary = {}
## cell -> trap kind: "spikes", "wire" (live wire, sparks on alternating turns) or "tape"
## (red tape: roots whoever steps in it for the rest of their turn)
var hazards: Dictionary = {}
## cell -> TrapDecal node for wire / tape traps
var trap_nodes: Dictionary = {}
## Live wires spark on alternating turns (see TacticalBattlefield.start_player_turn).
var wires_active: bool = false
var explored: Dictionary = {}
var visible_cells: Dictionary = {}


func build(w: int, h: int, floor_tex: Texture2D) -> void:
	width = w
	height = h
	ground.tile_set = _make_tileset(floor_tex)
	fog.tile_set = _make_fog_tileset()
	for y in h:
		for x in w:
			ground.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
			fog.set_cell(Vector2i(x, y), 0, FOG_UNEXPLORED)
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	los_ray.collision_mask = LOS_LAYER
	los_ray.collide_with_areas = false
	los_ray.collide_with_bodies = true
	los_ray.enabled = false


func _make_tileset(tex: Texture2D) -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = CELL
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(tex.get_width(), tex.get_height())
	src.create_tile(Vector2i.ZERO)
	ts.add_source(src, 0)
	return ts


func _make_fog_tileset() -> TileSet:
	var img := Image.create(CELL.x * 2, CELL.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in CELL.y:
		for x in CELL.x:
			var d := absf(x + 0.5 - CELL.x / 2.0) / (CELL.x / 2.0) + absf(y + 0.5 - CELL.y / 2.0) / (CELL.y / 2.0)
			if d <= 1.08:
				img.set_pixel(x, y, Color(0.02, 0.0, 0.06, 1.0))
				img.set_pixel(x + CELL.x, y, Color(0.02, 0.0, 0.08, 0.55))
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = CELL
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = CELL
	src.create_tile(FOG_UNEXPLORED)
	src.create_tile(FOG_EXPLORED)
	ts.add_source(src, 0)
	return ts


# ------------------------------------------------------------------ coordinates

func cell_to_world(c: Vector2i) -> Vector2:
	return ground.map_to_local(c)


func world_to_cell(p: Vector2) -> Vector2i:
	return ground.local_to_map(ground.to_local(p))


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and not blockers.has(c)


func center_world() -> Vector2:
	return (cell_to_world(Vector2i(0, 0)) + cell_to_world(Vector2i(width - 1, height - 1))) / 2.0


func all_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in height:
		for x in width:
			out.append(Vector2i(x, y))
	return out


func neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = c + d
		if in_bounds(n):
			out.append(n)
	return out


# ------------------------------------------------------------------ terrain

func add_blocker(c: Vector2i, kind: String, tex: Texture2D, blocks_los: bool) -> void:
	blockers[c] = kind
	astar.set_point_solid(c, true)
	if tex:
		var s := Sprite2D.new()
		s.texture = tex
		s.position = cell_to_world(c)
		# Props are drawn in true 2:1 isometric (docs/art_brief.md), so their base spans the
		# tile and their front corner sits on the tile's bottom corner.
		SpriteScaler.fit_iso(s, 128.0, 32.0)
		s.name = "%s_%d_%d" % [kind, c.x, c.y]
		objects.add_child(s)
		blocker_sprites[c] = s
	if blocks_los:
		var body := StaticBody2D.new()
		body.collision_layer = LOS_LAYER
		body.collision_mask = 0
		body.position = cell_to_world(c)
		var poly := CollisionPolygon2D.new()
		var hx := CELL.x * 0.44
		var hy := CELL.y * 0.44
		poly.polygon = PackedVector2Array([Vector2(0, -hy), Vector2(hx, 0), Vector2(0, hy), Vector2(-hx, 0)])
		body.add_child(poly)
		add_child(body)
		los_bodies[c] = body


func remove_blocker(c: Vector2i) -> void:
	blockers.erase(c)
	astar.set_point_solid(c, false)
	if blocker_sprites.has(c):
		blocker_sprites[c].queue_free()
		blocker_sprites.erase(c)
	if los_bodies.has(c):
		var body: StaticBody2D = los_bodies[c]
		body.collision_layer = 0
		body.queue_free()
		los_bodies.erase(c)


func add_hazard(c: Vector2i, tex: Texture2D, kind: String = "spikes") -> void:
	hazards[c] = kind
	astar.set_point_weight_scale(c, 5.0)
	if kind == "spikes":
		var s := Sprite2D.new()
		s.texture = tex
		s.position = cell_to_world(c)
		SpriteScaler.fit_decal(s, 124.0, 4.0)
		decals.add_child(s)
		return
	var d: Node2D = TRAP_DECAL.new()
	d.kind = kind
	d.position = cell_to_world(c)
	d.active = wires_active
	decals.add_child(d)
	trap_nodes[c] = d


func trap_kind(c: Vector2i) -> String:
	return String(hazards.get(c, ""))


## True if stepping on `c` right now would hurt (spikes always, wires only while sparking).
func trap_hurts(c: Vector2i) -> bool:
	var k := trap_kind(c)
	return k == "spikes" or (k == "wire" and wires_active)


func set_wires_active(on: bool) -> void:
	wires_active = on
	for c in trap_nodes:
		if trap_kind(c) == "wire":
			trap_nodes[c].set_active(on)


## Overheated Espresso Machine: a half-cover blocker that explodes when hit.
func add_espresso(c: Vector2i) -> void:
	add_blocker(c, "espresso", null, false)
	var m: Sprite2D = ESPRESSO.new()
	m.position = cell_to_world(c)
	m.name = "espresso_%d_%d" % [c.x, c.y]
	objects.add_child(m)
	blocker_sprites[c] = m


## Flood fill over walkable cells; used to keep maps fully connected.
func connected_count(start: Vector2i) -> int:
	if not is_walkable(start):
		return 0
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for n in neighbors(c):
			if is_walkable(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen.size()


func walkable_count() -> int:
	return width * height - blockers.size()


# ------------------------------------------------------------------ pathing

## A* path (inclusive of both ends). Units in `occupied` block the path except `from`/`to`.
func find_path(from: Vector2i, to: Vector2i, occupied: Array[Vector2i]) -> Array[Vector2i]:
	var temp: Array[Vector2i] = []
	for c in occupied:
		if c != from and c != to and in_bounds(c) and not astar.is_point_solid(c):
			astar.set_point_solid(c, true)
			temp.append(c)
	var path: Array[Vector2i] = astar.get_id_path(from, to, true)
	for c in temp:
		astar.set_point_solid(c, false)
	return path


## Cells reachable within `max_steps` moves -> step count. Uses the same costs as the path
## a unit actually walks (see move_path), so every highlighted cell can really be reached.
func reachable(from: Vector2i, max_steps: int, occupied: Array[Vector2i]) -> Dictionary:
	var out := {}
	var plan := plan_moves(from, max_steps, occupied)
	for c in plan["steps"]:
		if c != from:
			out[c] = plan["steps"][c]
	return out


## Dijkstra over walkable cells with cost = steps first, spike tiles second, so the chosen
## route is always the shortest one and avoids spikes only when that costs no extra AP.
## Returns {"steps": {cell: steps}, "parent": {cell: cell}}.
func plan_moves(from: Vector2i, max_steps: int, occupied: Array[Vector2i]) -> Dictionary:
	var cost := {from: 0}
	var steps := {from: 0}
	var parent := {}
	var open: Array[Vector2i] = [from]
	while not open.is_empty():
		var best_i := 0
		for i in range(1, open.size()):
			if cost[open[i]] < cost[open[best_i]]:
				best_i = i
		var c: Vector2i = open[best_i]
		open.remove_at(best_i)
		if steps[c] >= max_steps:
			continue
		for n in neighbors(c):
			if not is_walkable(n) or occupied.has(n):
				continue
			var nc: int = cost[c] + 1000 + (1 if hazards.has(n) else 0)
			if not cost.has(n) or nc < cost[n]:
				if not cost.has(n):
					open.append(n)
				cost[n] = nc
				steps[n] = steps[c] + 1
				parent[n] = c
	return {"steps": steps, "parent": parent}


## Path (inclusive of both ends) from a plan_moves() result, or [] if `to` isn't in it.
func path_from_plan(plan: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not plan["steps"].has(to):
		return out
	var c := to
	out.append(c)
	while c != from:
		c = plan["parent"][c]
		out.push_front(c)
	return out


## The route a unit walks to `to` within `max_steps`, matching reachable().
func move_path(from: Vector2i, to: Vector2i, max_steps: int, occupied: Array[Vector2i]) -> Array[Vector2i]:
	return path_from_plan(plan_moves(from, max_steps, occupied), from, to)


# ------------------------------------------------------------------ line of sight

## True if a ray from tile a to tile b clears every full-cover body, ignoring cover that hugs
## the target (that cover reduces the hit chance instead of blocking the shot).
func _ray_clear(a: Vector2i, b: Vector2i) -> bool:
	los_ray.clear_exceptions()
	if los_bodies.has(b):
		los_ray.add_exception(los_bodies[b])
	for n in neighbors(b):
		if los_bodies.has(n):
			los_ray.add_exception(los_bodies[n])
	los_ray.position = cell_to_world(a)
	los_ray.target_position = cell_to_world(b) - los_ray.position
	los_ray.force_raycast_update()
	var blocked := los_ray.is_colliding()
	var hit_body: Object = los_ray.get_collider() if blocked else null
	los_ray.clear_exceptions()
	_last_hit_body = hit_body
	return not blocked


var _last_hit_body: Object = null


## XCOM-style line of sight with step-out. A shot that's blocked by full cover right next to
## the shooter can still be taken by "leaning out" from an open neighbouring tile, but a
## machine squarely in the way of a shooter with no open side blocks it.
func has_los(a: Vector2i, b: Vector2i) -> bool:
	if a == b:
		return true
	if _ray_clear(a, b):
		return true
	var hit_cell := Vector2i(-999, -999)
	for c in los_bodies:
		if los_bodies[c] == _last_hit_body:
			hit_cell = c
			break
	if CombatMath.manhattan(hit_cell, a) != 1:
		return false
	var blocker_dir := hit_cell - a
	for n in neighbors(a):
		var side := n - a
		# Step out sideways only (not forward into the machine or backwards).
		if side == blocker_dir or side == -blocker_dir or blockers.has(n) or n == b:
			continue
		if _ray_clear(n, b):
			return true
	return false


## Best cover the target cell gets against a shot from `attacker` (XCOM rule: a cover object
## on a tile next to the target, on the side facing the attacker).
func cover_between(attacker: Vector2i, target: Vector2i) -> int:
	var best: int = Cover.NONE
	var to_attacker := Vector2(attacker - target)
	for n in neighbors(target):
		if not blockers.has(n):
			continue
		var side := Vector2(n - target)
		if side.dot(to_attacker) <= 0.0:
			continue
		best = maxi(best, int(COVER_OF.get(blockers[n], Cover.NONE)))
	return best


# ------------------------------------------------------------------ fog of war

## Reveals tiles within `radius` that Carol has line of sight to (vending machines block
## vision just like they block shots).
func update_fog(center: Vector2i, radius: int) -> void:
	visible_cells.clear()
	for c in all_cells():
		if Vector2(c).distance_to(Vector2(center)) <= radius + 0.01 and (c == center or has_los(center, c)):
			visible_cells[c] = true
			explored[c] = true
	for c in all_cells():
		if visible_cells.has(c):
			fog.erase_cell(c)
		elif explored.has(c):
			fog.set_cell(c, 0, FOG_EXPLORED)
		else:
			fog.set_cell(c, 0, FOG_UNEXPLORED)
	for c in blocker_sprites:
		var s: Sprite2D = blocker_sprites[c]
		s.visible = explored.has(c)
		s.modulate = Color.WHITE if visible_cells.has(c) else Color(0.4, 0.4, 0.5)


func is_cell_visible(c: Vector2i) -> bool:
	return visible_cells.has(c)
