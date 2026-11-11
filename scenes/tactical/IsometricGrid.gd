class_name IsometricGrid
extends Node2D
## Isometric battlefield: TileMapLayer floor, AStarGrid2D pathing, RayCast2D line of sight,
## and a fog-of-war TileMapLayer.

const CELL := Vector2i(32, 16)
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
## cells with spike traps
var hazards: Dictionary = {}
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
		s.offset = Vector2(0, -tex.get_height() / 2.0 + 4)
		s.name = "%s_%d_%d" % [kind, c.x, c.y]
		objects.add_child(s)
		blocker_sprites[c] = s
	if blocks_los:
		var body := StaticBody2D.new()
		body.collision_layer = LOS_LAYER
		body.collision_mask = 0
		body.position = cell_to_world(c)
		var poly := CollisionPolygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(0, -7), Vector2(14, 0), Vector2(0, 7), Vector2(-14, 0)])
		body.add_child(poly)
		add_child(body)


func remove_blocker(c: Vector2i) -> void:
	blockers.erase(c)
	astar.set_point_solid(c, false)
	if blocker_sprites.has(c):
		blocker_sprites[c].queue_free()
		blocker_sprites.erase(c)


func add_hazard(c: Vector2i, tex: Texture2D) -> void:
	hazards[c] = true
	astar.set_point_weight_scale(c, 5.0)
	var s := Sprite2D.new()
	s.texture = tex
	s.position = cell_to_world(c)
	s.offset = Vector2(0, -tex.get_height() / 2.0 + 8)
	decals.add_child(s)


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


## Cells reachable within `max_steps` moves -> step count.
func reachable(from: Vector2i, max_steps: int, occupied: Array[Vector2i]) -> Dictionary:
	var out := {}
	var dist := {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var d: int = dist[c]
		if d >= max_steps:
			continue
		for n in neighbors(c):
			if dist.has(n) or not is_walkable(n) or occupied.has(n):
				continue
			dist[n] = d + 1
			out[n] = d + 1
			queue.append(n)
	return out


# ------------------------------------------------------------------ line of sight

## Casts a RayCast2D from tile center to tile center; LOS blockers are StaticBody2D diamonds.
func has_los(a: Vector2i, b: Vector2i) -> bool:
	if a == b:
		return true
	los_ray.position = cell_to_world(a)
	los_ray.target_position = cell_to_world(b) - los_ray.position
	los_ray.force_raycast_update()
	return not los_ray.is_colliding()


# ------------------------------------------------------------------ fog of war

func update_fog(center: Vector2i, radius: int) -> void:
	visible_cells.clear()
	for c in all_cells():
		if Vector2(c).distance_to(Vector2(center)) <= radius + 0.01:
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
