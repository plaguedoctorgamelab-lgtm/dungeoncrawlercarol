extends Node2D
## Princess Penny in the Sea Lord's neon boardroom cage. break_cage() frees her.

signal freed

var cell: Vector2i
var caged: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var cage: Node2D = $Cage


func _ready() -> void:
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 4)
	cage.draw.connect(_draw_cage)
	cage.queue_redraw()


func _draw_cage() -> void:
	var col := Color("#ff2bd6")
	var w := 13.0
	var top := -34.0
	var bottom := 3.0
	# Back/floor ring
	cage.draw_rect(Rect2(-w - 1, bottom - 2, w * 2 + 2, 4), Color.BLACK)
	cage.draw_rect(Rect2(-w, bottom - 1, w * 2, 2), Color("#ffe600"))
	for i in 6:
		var x := -w + i * (w * 2 / 5.0)
		cage.draw_line(Vector2(x, top), Vector2(x, bottom), Color.BLACK, 3.0)
		cage.draw_line(Vector2(x, top), Vector2(x, bottom), col, 1.0)
	cage.draw_rect(Rect2(-w - 1, top - 2, w * 2 + 2, 4), Color.BLACK)
	cage.draw_rect(Rect2(-w, top - 1, w * 2, 2), Color("#ffe600"))


func break_cage() -> void:
	if not caged:
		return
	caged = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cage, "position", Vector2(0, -60), 0.6)
	tw.tween_property(cage, "modulate:a", 0.0, 0.6)
	tw.tween_property(cage, "rotation", 0.6, 0.6)
	await tw.finished
	cage.visible = false
	var hop := create_tween()
	hop.tween_property(sprite, "position", Vector2(0, -8), 0.15)
	hop.tween_property(sprite, "position", Vector2.ZERO, 0.15)
	hop.tween_property(sprite, "position", Vector2(0, -8), 0.15)
	hop.tween_property(sprite, "position", Vector2.ZERO, 0.15)
	await hop.finished
	freed.emit()
