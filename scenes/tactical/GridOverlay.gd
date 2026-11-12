extends Node2D
## Draws reachable tiles (neon cyan), weapon attack range (neon pink), the path preview and
## target markers as isometric diamonds.

const CYAN := Color(0.0, 0.94, 1.0)
const PINK := Color(1.0, 0.17, 0.84)

var grid: IsometricGrid
var move_cells: Dictionary = {}
var range_cells: Dictionary = {}
var path: Array[Vector2i] = []
var targets: Dictionary = {} # cell -> Color
var hover_cell := Vector2i(-1, -1)
## Dash mode draws the move tiles brighter and dashed so it reads as a different action.
var dash_mode: bool = false
## Tiles a charging boss will strike next turn (drawn as a red danger zone).
var danger_cells: Dictionary = {}


func clear_all() -> void:
	move_cells.clear()
	range_cells.clear()
	path.clear()
	targets.clear()
	hover_cell = Vector2i(-1, -1)
	dash_mode = false
	queue_redraw()


func _diamond(c: Vector2i, shrink: float = 1.0) -> PackedVector2Array:
	var p := grid.cell_to_world(c)
	var hx := IsometricGrid.CELL.x / 2.0 * shrink
	var hy := IsometricGrid.CELL.y / 2.0 * shrink
	return PackedVector2Array([p + Vector2(0, -hy), p + Vector2(hx, 0), p + Vector2(0, hy), p + Vector2(-hx, 0)])


func _outline(c: Vector2i, col: Color, w: float = 2.0, shrink: float = 0.92) -> void:
	var d := _diamond(c, shrink)
	d.append(d[0])
	draw_polyline(d, col, w, true)


func _draw() -> void:
	if grid == null:
		return
	for c in range_cells:
		if move_cells.has(c):
			continue
		draw_colored_polygon(_diamond(c, 0.9), Color(PINK, 0.12))
		_outline(c, Color(PINK, 0.35), 2.0)
	for c in move_cells:
		if dash_mode:
			draw_colored_polygon(_diamond(c, 0.9), Color(1.0, 1.0, 1.0, 0.18))
			_outline(c, Color(CYAN, 0.95), 4.0)
		else:
			draw_colored_polygon(_diamond(c, 0.9), Color(CYAN, 0.2))
			_outline(c, Color(CYAN, 0.55), 2.0)
	for i in path.size():
		if i == 0:
			continue
		draw_colored_polygon(_diamond(path[i], 0.55), Color(1.0, 0.9, 0.0, 0.6))
	for c in danger_cells:
		if grid.in_bounds(c):
			draw_colored_polygon(_diamond(c, 0.95), Color(1.0, 0.1, 0.1, 0.32))
			_outline(c, Color(1.0, 0.2, 0.1, 0.95), 4.0, 0.95)
	for c in targets:
		draw_colored_polygon(_diamond(c, 0.9), Color(targets[c], 0.18))
		_outline(c, targets[c], 4.0)
	if grid.in_bounds(hover_cell):
		_outline(hover_cell, Color.WHITE, 3.0)
