extends Node2D
## Draws movement range, path preview and target markers as isometric diamonds.

var grid: IsometricGrid
var move_cells: Dictionary = {}
var path: Array[Vector2i] = []
var targets: Dictionary = {} # cell -> Color
var hover_cell := Vector2i(-1, -1)


func clear_all() -> void:
	move_cells.clear()
	path.clear()
	targets.clear()
	hover_cell = Vector2i(-1, -1)
	queue_redraw()


func _diamond(c: Vector2i, shrink: float = 1.0) -> PackedVector2Array:
	var p := grid.cell_to_world(c)
	var hx := 16.0 * shrink
	var hy := 8.0 * shrink
	return PackedVector2Array([p + Vector2(0, -hy), p + Vector2(hx, 0), p + Vector2(0, hy), p + Vector2(-hx, 0)])


func _outline(c: Vector2i, col: Color, w: float = 1.0) -> void:
	var d := _diamond(c, 0.92)
	d.append(d[0])
	draw_polyline(d, col, w)


func _draw() -> void:
	if grid == null:
		return
	for c in move_cells:
		draw_colored_polygon(_diamond(c, 0.9), Color(0.0, 0.94, 1.0, 0.18))
		_outline(c, Color(0.0, 0.94, 1.0, 0.45))
	for i in path.size():
		if i == 0:
			continue
		draw_colored_polygon(_diamond(path[i], 0.6), Color(1.0, 0.9, 0.0, 0.55))
	for c in targets:
		_outline(c, targets[c], 2.0)
	if grid.in_bounds(hover_cell):
		_outline(hover_cell, Color.WHITE, 1.0)
