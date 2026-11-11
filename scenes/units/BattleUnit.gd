class_name BattleUnit
extends Node2D
## Shared unit logic: grid cell, HP, AP, movement tweens and an HP bar.

signal died(unit: BattleUnit)

const STEP_TIME := 0.11

var cell: Vector2i
var max_hp: float = 100.0
var hp: float = 100.0
var max_ap: int = 4
var ap: int = 4
var display_name: String = "Unit"
var bar_y: float = -34.0
var bar_color: Color = Color("#7dff4a")

@onready var sprite: Sprite2D = $Sprite2D


func is_dead() -> bool:
	return hp <= 0.0


func set_texture(tex: Texture2D) -> void:
	sprite.texture = tex
	var h := tex.get_height()
	sprite.offset = Vector2(0, -h / 2.0 + 4)
	bar_y = -h + 1.0
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
	tw.tween_property(self, "position", start + (toward - start) * 0.4, 0.09)
	tw.tween_property(self, "position", start, 0.12)
	await tw.finished


func take_damage(amount: float) -> float:
	hp = maxf(0.0, hp - amount)
	if sprite:
		sprite.modulate = Color(4, 4, 4)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	queue_redraw()
	if hp <= 0.0:
		died.emit(self)
	return amount


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	queue_redraw()


func _draw() -> void:
	var w := 26.0
	draw_rect(Rect2(-w / 2 - 1, bar_y - 1, w + 2, 5), Color.BLACK)
	var frac := clampf(hp / max_hp, 0.0, 1.0)
	var col := bar_color if frac > 0.35 else Color("#ff3b3b")
	draw_rect(Rect2(-w / 2, bar_y, w * frac, 3), col)
