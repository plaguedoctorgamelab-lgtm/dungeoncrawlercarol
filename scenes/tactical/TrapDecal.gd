extends Node2D
## Procedurally drawn floor trap, sized to the 128x64 isometric tile so it sits exactly on
## the grid. Used until real trap art arrives (see docs/art_brief.md, Part B).
##   "wire": downed power cables that spark on alternating turns (active / inactive)
##   "tape": a sticky tangle of red tape that roots whoever steps in it

var kind: String = "wire"
var active: bool = false
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()
## Sprite showing the delivered art (null -> procedural drawing).
var _art: Sprite2D
var _tex_on: Texture2D
var _tex_off: Texture2D


func _ready() -> void:
	_rng.seed = hash(position)
	var on_id := "trap_live_wire_on" if kind == "wire" else "trap_red_tape"
	var off_id := "trap_live_wire_off" if kind == "wire" else "trap_red_tape"
	if ResourceLoader.exists("res://assets/sprites/%s.png" % on_id):
		_tex_on = load("res://assets/sprites/%s.png" % on_id)
		_tex_off = load("res://assets/sprites/%s.png" % off_id) if ResourceLoader.exists("res://assets/sprites/%s.png" % off_id) else _tex_on
		_art = Sprite2D.new()
		add_child(_art)
		_apply_art()


func _apply_art() -> void:
	if _art == null:
		return
	_art.texture = _tex_on if (active or kind != "wire") else _tex_off
	SpriteScaler.fit_decal(_art, 124.0)


func set_active(on: bool) -> void:
	active = on
	_apply_art()
	queue_redraw()


func _process(delta: float) -> void:
	if kind == "wire" and active:
		_t += delta
		if _art:
			# Crackle: a quick bright flicker over the sparking art.
			_art.modulate = Color(1.0, 1.0, 1.0) * (1.0 + 0.35 * absf(sin(_t * 23.0)))
		queue_redraw()
	elif _art:
		_art.modulate = Color.WHITE


func _diamond(s: float) -> PackedVector2Array:
	var hx := IsometricGrid.CELL.x / 2.0 * s
	var hy := IsometricGrid.CELL.y / 2.0 * s
	return PackedVector2Array([Vector2(0, -hy), Vector2(hx, 0), Vector2(0, hy), Vector2(-hx, 0)])


## Maps a point in a unit square (u, v in 0..1) onto the floor diamond.
func _iso(u: float, v: float, s: float = 0.8) -> Vector2:
	var hx := IsometricGrid.CELL.x / 2.0 * s
	var hy := IsometricGrid.CELL.y / 2.0 * s
	return Vector2((u - v) * hx, (u + v - 1.0) * hy)


func _draw() -> void:
	if _art != null:
		return
	if kind == "wire":
		_draw_wire()
	elif kind == "tape":
		_draw_tape()


func _draw_wire() -> void:
	# Metal grate.
	draw_colored_polygon(_diamond(0.86), Color(0.16, 0.17, 0.22, 0.95))
	var outline := _diamond(0.86)
	outline.append(outline[0])
	draw_polyline(outline, Color.BLACK, 3.0)
	for i in range(1, 6):
		var k := i / 6.0
		draw_line(_iso(k, 0.0, 0.86), _iso(k, 1.0, 0.86), Color(0.3, 0.32, 0.4), 2.0)
	# Two cables snaking across.
	var cable_col := Color(0.95, 0.85, 0.1) if active else Color(0.35, 0.33, 0.25)
	for c in 2:
		var pts := PackedVector2Array()
		for i in 9:
			var u := i / 8.0
			var v := 0.3 + 0.4 * c + 0.12 * sin(u * 9.0 + c * 2.0)
			pts.append(_iso(u, v))
		draw_polyline(pts, Color.BLACK, 7.0)
		draw_polyline(pts, cable_col, 3.5)
	if not active:
		return
	# Sparks: jagged bolts re-rolled each frame, cyan and white.
	_rng.seed = int(_t * 20.0)
	for b in 3:
		var p := _iso(_rng.randf_range(0.15, 0.85), _rng.randf_range(0.15, 0.85))
		var pts := PackedVector2Array([p])
		for i in 4:
			p += Vector2(_rng.randf_range(-14, 14), _rng.randf_range(-12, 4))
			pts.append(p)
		draw_polyline(pts, Color(0.3, 1.0, 1.0, 0.9), 3.0)
		draw_polyline(pts, Color.WHITE, 1.2)
	draw_colored_polygon(_diamond(0.86), Color(0.2, 0.9, 1.0, 0.12 + 0.08 * sin(_t * 18.0)))


func _draw_tape() -> void:
	draw_colored_polygon(_diamond(0.84), Color(0.55, 0.05, 0.08, 0.35))
	_rng.seed = hash(position) + 7
	for i in 7:
		var a := _iso(_rng.randf_range(0.0, 1.0), _rng.randf_range(0.0, 0.35))
		var b := _iso(_rng.randf_range(0.0, 1.0), _rng.randf_range(0.65, 1.0))
		draw_line(a, b, Color.BLACK, 9.0)
		draw_line(a, b, Color(0.9, 0.08, 0.12), 6.0)
		draw_line(a, b, Color(1.0, 0.45, 0.45), 1.5)
	# Two "forms" stuck in the tape.
	for i in 2:
		var p := _iso(0.3 + 0.4 * i, 0.5 - 0.15 * i)
		var r := Rect2(p - Vector2(13, 9), Vector2(26, 18))
		draw_rect(r, Color.BLACK)
		draw_rect(r.grow(-2), Color(0.97, 0.95, 0.85))
		draw_line(r.position + Vector2(5, 6), r.position + Vector2(21, 6), Color(0.5, 0.5, 0.6), 1.5)
		draw_line(r.position + Vector2(5, 11), r.position + Vector2(17, 11), Color(0.5, 0.5, 0.6), 1.5)
