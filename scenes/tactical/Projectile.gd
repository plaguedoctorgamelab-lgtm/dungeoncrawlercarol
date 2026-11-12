extends Sprite2D
## A tweened projectile driven by ProjectileData. The node moves along the ground line in
## isometric screen space (so it y-sorts with units and props); `height` lifts the sprite
## for lobbed shots.

signal arrived

const DEFAULT_SPEED := 1100.0
const LAUNCH_HEIGHT := 64.0

var data: ProjectileData
var height: float = LAUNCH_HEIGHT
var _t: float = 0.0
var _trail_timer: float = 0.0
var _base_scale: float = 1.0


func launch(from: Vector2, to: Vector2, d: ProjectileData, tint: Color = Color.WHITE) -> void:
	data = d
	texture = d.texture if d and d.texture else SpriteScaler.placeholder("projectile")
	modulate = tint * (d.tint if d else Color.WHITE)
	position = from
	var fp: Vector2 = d.footprint if d else SpriteScaler.PROJECTILE
	_base_scale = SpriteScaler.scale_for(Vector2(texture.get_size()), fp)
	scale = Vector2(_base_scale, _base_scale)
	var dir := to - from
	var motion: String = d.motion if d else "straight"
	if motion != "spin":
		# Flip instead of rotating upside-down so text-y sprites stay readable.
		flip_h = dir.x < 0
		rotation = atan2(dir.y, absf(dir.x)) * (-1.0 if flip_h else 1.0)
	var speed: float = d.speed if d and d.speed > 0 else DEFAULT_SPEED
	var duration := maxf(dir.length() / speed, 0.08)
	if motion == "beam":
		scale.x = _base_scale * 1.8
	var tw := create_tween()
	tw.tween_property(self, "position", to, duration)
	tw.parallel().tween_method(_set_progress, 0.0, 1.0, duration)
	await tw.finished
	arrived.emit()
	queue_free()


func _set_progress(t: float) -> void:
	_t = t
	var motion: String = data.motion if data else "straight"
	height = LAUNCH_HEIGHT
	match motion:
		"arc":
			height += data.arc_height * 4.0 * t * (1.0 - t)
		"wobble":
			height += sin(t * TAU * 3.0) * 10.0
			var pulse := 1.0 + 0.15 * sin(t * TAU * 4.0)
			scale = Vector2(_base_scale * pulse, _base_scale * pulse)
	if data and data.spin_turns != 0.0:
		rotation = t * TAU * data.spin_turns
	offset = Vector2(0, -height / maxf(scale.y, 0.001))


func _process(delta: float) -> void:
	if data == null or data.trail_color.a <= 0.0:
		return
	_trail_timer -= delta
	if _trail_timer > 0.0:
		return
	_trail_timer = 0.025
	var ghost := Sprite2D.new()
	ghost.texture = texture
	ghost.position = position
	ghost.offset = offset
	ghost.scale = scale
	ghost.rotation = rotation
	ghost.flip_h = flip_h
	ghost.modulate = data.trail_color
	get_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ghost.queue_free)
