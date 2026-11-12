extends Node2D
## Princess Penny in the Sea Lord's neon boardroom cage. break_cage() frees her.

signal freed

var cell: Vector2i
var caged: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var cage: Node2D = $Cage


func _ready() -> void:
	SpriteScaler.fit(sprite, SpriteScaler.UNIT)
	cage.draw.connect(_draw_cage)
	cage.queue_redraw()


func _draw_cage() -> void:
	var col := Color("#ff2bd6")
	var w := 54.0
	var top := -136.0
	var bottom := 12.0
	# Back/floor ring
	cage.draw_rect(Rect2(-w - 3, bottom - 6, w * 2 + 6, 12), Color.BLACK)
	cage.draw_rect(Rect2(-w, bottom - 4, w * 2, 8), Color("#ffe600"))
	for i in 7:
		var x := -w + i * (w * 2 / 6.0)
		cage.draw_line(Vector2(x, top), Vector2(x, bottom), Color.BLACK, 9.0)
		cage.draw_line(Vector2(x, top), Vector2(x, bottom), col, 4.0)
	cage.draw_rect(Rect2(-w - 3, top - 6, w * 2 + 6, 12), Color.BLACK)
	cage.draw_rect(Rect2(-w, top - 4, w * 2, 8), Color("#ffe600"))


func break_cage() -> void:
	if not caged:
		return
	caged = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cage, "position", Vector2(0, -240), 0.6)
	tw.tween_property(cage, "modulate:a", 0.0, 0.6)
	tw.tween_property(cage, "rotation", 0.6, 0.6)
	await tw.finished
	cage.visible = false
	var hop := create_tween()
	hop.tween_property(sprite, "position", Vector2(0, -32), 0.15)
	hop.tween_property(sprite, "position", Vector2.ZERO, 0.15)
	hop.tween_property(sprite, "position", Vector2(0, -32), 0.15)
	hop.tween_property(sprite, "position", Vector2.ZERO, 0.15)
	await hop.finished
	freed.emit()
