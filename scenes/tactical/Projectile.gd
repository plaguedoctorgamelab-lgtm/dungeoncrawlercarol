extends Sprite2D
## Static 1-frame projectile that flies in a straight line at 400 px/s (GDD 4.4).

signal arrived

const SPEED := 400.0


func launch(from: Vector2, to: Vector2, tex: Texture2D, tint: Color = Color.WHITE) -> void:
	texture = tex
	modulate = tint
	position = from
	scale = Vector2(1.25, 1.25)
	var dir := to - from
	# Flip instead of rotating upside-down so text-y sprites stay readable.
	flip_h = dir.x < 0
	rotation = atan2(dir.y, absf(dir.x)) * (-1.0 if flip_h else 1.0)
	var duration := maxf(dir.length() / SPEED, 0.05)
	var tw := create_tween()
	tw.tween_property(self, "position", to, duration)
	await tw.finished
	arrived.emit()
	queue_free()
