class_name BattleUnit
extends Node2D
## Shared unit logic: grid cell(s), HP, AP, movement tweens and an HP bar.
## `cell` is the anchor (top) cell; bosses cover a size_cells x size_cells block.

signal died(unit: BattleUnit)

const STEP_TIME := 0.14

var cell: Vector2i
var max_hp: float = 100.0
var hp: float = 100.0
var max_ap: int = 4
var ap: int = 4
var display_name: String = "Unit"
var bar_y: float = -140.0
var bar_width: float = 84.0
var bar_color: Color = Color("#7dff4a")
## 1 for regular units, 2 for 2x2 bosses.
var size_cells: int = 1
## Sprite scale chosen by SpriteScaler; animations squash and stretch relative to it.
var base_scale: Vector2 = Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D


func is_dead() -> bool:
	return hp <= 0.0


func footprint() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in size_cells:
		for dx in size_cells:
			out.append(cell + Vector2i(dx, dy))
	return out


func occupies(c: Vector2i) -> bool:
	return c.x >= cell.x and c.y >= cell.y and c.x < cell.x + size_cells and c.y < cell.y + size_cells


## Footprint cell closest to `to` (used for range, LOS and melee adjacency).
func nearest_cell(to: Vector2i) -> Vector2i:
	return Vector2i(clampi(to.x, cell.x, cell.x + size_cells - 1), clampi(to.y, cell.y, cell.y + size_cells - 1))


## Scales any texture (e.g. a raw 512x512 PNG) to the unit's footprint via SpriteScaler.
func set_texture(tex: Texture2D) -> void:
	sprite.texture = tex if tex != null else SpriteScaler.placeholder("unit")
	var footprint_px := SpriteScaler.BOSS if size_cells > 1 else SpriteScaler.UNIT
	var drawn := SpriteScaler.fit(sprite, footprint_px, SpriteScaler.FOOT_SINK * size_cells)
	base_scale = sprite.scale
	bar_y = -drawn.y + SpriteScaler.FOOT_SINK * size_cells - 14.0
	bar_width = 84.0 * size_cells
	queue_redraw()


func place(c: Vector2i, world: Vector2) -> void:
	cell = c
	position = world


func step_to(c: Vector2i, world: Vector2, animate: bool = true) -> void:
	cell = c
	if not animate or not visible:
		position = world
		return
	var tw := create_tween()
	tw.tween_property(self, "position", world, STEP_TIME)
	await tw.finished


## Small hop toward a target for melee hits (a tween, not a sprite animation).
func lunge(toward: Vector2) -> void:
	var start := position
	var tw := create_tween()
	tw.tween_property(self, "position", start + (toward - start) * 0.35, 0.1)
	tw.tween_property(self, "position", start, 0.14)
	await tw.finished


func take_damage(amount: float) -> float:
	hp = maxf(0.0, hp - amount)
	if sprite:
		sprite.modulate = Color(4, 4, 4)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.25)
		# Squash on impact, then spring back.
		var sq := create_tween()
		sq.tween_property(sprite, "scale", base_scale * Vector2(1.25, 0.78), 0.05)
		sq.tween_property(sprite, "scale", base_scale * Vector2(0.92, 1.08), 0.07)
		sq.tween_property(sprite, "scale", base_scale, 0.08)
	queue_redraw()
	if hp <= 0.0:
		died.emit(self)
	return amount


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	queue_redraw()


func _draw() -> void:
	var w := bar_width
	draw_rect(Rect2(-w / 2 - 2, bar_y - 2, w + 4, 12), Color.BLACK)
	var frac := clampf(hp / max_hp, 0.0, 1.0)
	var col := bar_color if frac > 0.35 else Color("#ff3b3b")
	draw_rect(Rect2(-w / 2, bar_y, w * frac, 8), col)
