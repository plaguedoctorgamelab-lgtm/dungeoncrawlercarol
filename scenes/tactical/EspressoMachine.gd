extends Sprite2D
## Overheated Espresso Machine: half cover that EXPLODES when hit (or when a monster is
## shoved into it), hurting everyone on the 8 surrounding tiles. Drawn procedurally as an
## isometric box that fits its tile exactly, until real art arrives (docs/art_brief.md, A4).
## If res://assets/sprites/trap_espresso_machine.png exists, that art is used instead.

const W := 128.0
const H := 64.0
const BOX := 74.0

var _t: float = 0.0
var _has_art: bool = false


func _ready() -> void:
	var tex := SpriteScaler.texture("trap_espresso_machine", "") if ResourceLoader.exists("res://assets/sprites/trap_espresso_machine.png") else null
	if tex:
		texture = tex
		SpriteScaler.fit(self, SpriteScaler.COVER_HALF, 14.0)
		_has_art = true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if _has_art:
		return
	var s := 0.82
	var hx := W / 2.0 * s
	var hy := H / 2.0 * s
	var top := Vector2(0, -hy - BOX)
	var right := Vector2(hx, -BOX)
	var front := Vector2(0, hy - BOX)
	var left := Vector2(-hx, -BOX)
	var b_right := Vector2(hx, 0)
	var b_front := Vector2(0, hy)
	var b_left := Vector2(-hx, 0)
	# Faces: left (medium red), right (dark red), top (chrome).
	draw_colored_polygon(PackedVector2Array([left, front, b_front, b_left]), Color("#c81e2b"))
	draw_colored_polygon(PackedVector2Array([front, right, b_right, b_front]), Color("#7d0f18"))
	draw_colored_polygon(PackedVector2Array([top, right, front, left]), Color("#d9dde6"))
	# Hazard stripes along the base.
	for i in 6:
		var k := i / 6.0
		var a := b_left.lerp(b_front, k) + Vector2(0, -10)
		var b := b_left.lerp(b_front, k + 0.08) + Vector2(0, -10)
		draw_line(a, b, Color("#ffe600"), 8.0)
	# Pressure gauge on the left face, needle in the red.
	var g := left.lerp(b_front, 0.5) + Vector2(4, -6)
	draw_circle(g, 13, Color.BLACK)
	draw_circle(g, 10, Color.WHITE)
	var needle := Vector2.from_angle(-0.6 + 0.15 * sin(_t * 9.0)) * 9.0
	draw_line(g, g + needle, Color.RED, 2.5)
	# Spout and warning sign.
	draw_rect(Rect2(front + Vector2(-6, 10), Vector2(12, 10)), Color("#333333"))
	var lab := right.lerp(b_front, 0.5) + Vector2(-2, -4)
	draw_colored_polygon(PackedVector2Array([lab + Vector2(0, -12), lab + Vector2(11, 8), lab + Vector2(-11, 8)]), Color("#ffe600"))
	draw_string(ThemeDB.fallback_font, lab + Vector2(-3, 6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	# Outline.
	var o := PackedVector2Array([top, right, b_right, b_front, b_left, left, top])
	draw_polyline(o, Color.BLACK, 3.0)
	draw_line(left, front, Color.BLACK, 2.0)
	draw_line(front, right, Color.BLACK, 2.0)
	draw_line(front, b_front, Color.BLACK, 2.0)
	# Steam puffs rising from the top, and a hot glow.
	for i in 3:
		var ph := fmod(_t * 0.8 + i / 3.0, 1.0)
		var p := top + Vector2(-10 + i * 10, -ph * 50.0)
		draw_circle(p, 6.0 + ph * 8.0, Color(1, 1, 1, 0.55 * (1.0 - ph)))
	draw_colored_polygon(PackedVector2Array([top, right, front, left]), Color(1, 0.2, 0.1, 0.15 + 0.12 * sin(_t * 6.0)))
