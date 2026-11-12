class_name CarolUnit
extends BattleUnit
## The player unit, with a procedural (code-driven) animation set built from her single
## sprite: idle breathing, hop-walk with squash and stretch, facing, dash afterimages,
## wind-up / strike / sword-swipe attacks, gun recoil, shove, hurt flinch, dodge sidestep,
## drink chug with bubbles, death fall and a victory jump.
##
## Layers: the "Rig" node carries the looping idle motion; one-shot actions animate the
## Sprite2D inside it, so the two combine instead of fighting each other.
##
## Frame-by-frame art: if res://assets/sprites/carol/carol_<anim>_NN.png frames exist
## (imported by scripts/tools/import_art.gd), the sprite plays real frames (idle, walk,
## attack, shoot, hit, down, victory) and the procedural motion is toned down to sit on top.

const HOP_HEIGHT := 18.0
const DASH_STEP_TIME := 0.08
const SWIPE_COLORS := [Color("#ff2bd6"), Color("#00f0ff"), Color("#ffe600")]
const FRAME_DIR := "res://assets/sprites/carol/"
const FRAME_ANIMS := ["idle", "walk", "attack", "shoot", "hit", "down", "victory"]
## Frame canvas from import_art.gd: feet sit at FRAME_FOOT; the idle pose is FRAME_BODY tall.
const FRAME_CANVAS := Vector2(440, 320)
const FRAME_FOOT := Vector2(220, 300)
const FRAME_BODY := 260.0

## Set by Dash: the next enemy attack on Carol gets -25% to hit.
var evasive: bool = false
## Stuck in red tape: no more moving this turn.
var rooted: bool = false
## "" while idling; otherwise the name of the one-shot animation that's playing.
var anim: String = ""

var rig: Node2D
var _t: float = 0.0
## anim name -> Array[Texture2D] (empty when no frame art is installed)
var frames: Dictionary = {}
var has_frames: bool = false
## Rotation multiplier: real frames already show the pose, so procedural tilts shrink.
var _rk: float = 1.0
var _fa: String = ""
var _fseq: Array = []
var _fi: int = 0
var _ffps: float = 8.0
var _floop: bool = true
var _ft: float = 0.0
var _facing: float = 1.0 # 1 = right, -1 = left
var _dead: bool = false


func _ready() -> void:
	display_name = "Carol"
	max_hp = GameState.carol_max_hp()
	hp = minf(GameState.carol_hp, max_hp)
	max_ap = GameState.CAROL_AP
	ap = max_ap
	bar_color = Color("#00f0ff")
	set_texture(sprite.texture)
	_load_frames()
	# Insert a rig between Carol and her sprite for the idle layer.
	rig = Node2D.new()
	rig.name = "Rig"
	add_child(rig)
	move_child(rig, 0)
	sprite.reparent(rig, false)


func _load_frames() -> void:
	for a in FRAME_ANIMS:
		var list: Array[Texture2D] = []
		for i in range(1, 10):
			var path := FRAME_DIR + "carol_%s_%02d.png" % [a, i]
			if not ResourceLoader.exists(path):
				break
			list.append(load(path))
		if not list.is_empty():
			frames[a] = list
	has_frames = frames.has("idle") and frames.has("walk")
	if not has_frames:
		return
	_rk = 0.35
	# Every frame shares one canvas, so one scale/offset keeps her feet planted.
	var sc := SpriteScaler.UNIT.y / FRAME_BODY
	sprite.texture = frames["idle"][0]
	sprite.centered = true
	sprite.scale = Vector2(sc, sc)
	sprite.offset = Vector2(FRAME_CANVAS.x / 2.0 - FRAME_FOOT.x, FRAME_CANVAS.y / 2.0 - FRAME_FOOT.y + SpriteScaler.FOOT_SINK / sc)
	base_scale = sprite.scale
	bar_y = -FRAME_BODY * sc + SpriteScaler.FOOT_SINK - 14.0
	queue_redraw()
	play_frames("idle")


## Plays a frame animation. "idle" ping-pongs (1-2-3-2); others run once and hold the
## last frame unless `loop` is set.
func play_frames(a: String, fps: float = 6.0, loop: bool = true) -> void:
	if not has_frames or not frames.has(a):
		return
	var n: int = frames[a].size()
	_fseq = range(n)
	if a == "idle" and n >= 3:
		_fseq = [0, 1, 2, 1]
	_fa = a
	_fi = 0
	_ffps = fps
	_floop = loop
	_ft = 0.0
	sprite.texture = frames[a][_fseq[0]]


## Shows one specific frame (1-based) and stops the frame player there.
func show_frame(a: String, index: int) -> void:
	if not has_frames or not frames.has(a):
		return
	var list: Array = frames[a]
	_fa = a
	_fseq = [clampi(index - 1, 0, list.size() - 1)]
	_fi = 0
	_floop = false
	sprite.texture = list[_fseq[0]]


func _idle_frames() -> void:
	if not _dead:
		play_frames("idle", 4.0, true)


func _tick_frames(delta: float) -> void:
	if not has_frames or _fseq.size() <= 1:
		return
	_ft += delta
	var step := 1.0 / maxf(_ffps, 0.1)
	while _ft >= step:
		_ft -= step
		if _fi + 1 < _fseq.size():
			_fi += 1
		elif _floop:
			_fi = 0
		else:
			return
		sprite.texture = frames[_fa][_fseq[_fi]]


func _process(delta: float) -> void:
	_tick_frames(delta)
	if _dead or rig == null:
		return
	_t += delta
	# Idle breathing and a gentle bob (smaller while an action plays).
	var k := 1.0 if anim == "" else 0.35
	rig.position.y = sin(_t * 2.6) * 2.5 * k
	rig.scale = Vector2(1.0 - 0.012 * k * sin(_t * 2.6), 1.0 + 0.022 * k * sin(_t * 2.6))
	# Evasive shimmer after a Dash.
	if evasive:
		rig.modulate = Color(0.75 + 0.25 * sin(_t * 12.0), 1.0, 1.0, 1.0)
	else:
		rig.modulate = Color.WHITE


## Turns Carol to face a world position (her art faces right).
func face(world_pos: Vector2) -> void:
	if absf(world_pos.x - position.x) < 2.0:
		return
	_facing = 1.0 if world_pos.x > position.x else -1.0
	sprite.flip_h = _facing < 0.0


func _tw() -> Tween:
	return create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _reset_pose(t: float = 0.12) -> Tween:
	var tw := _tw().set_parallel(true)
	tw.tween_property(sprite, "rotation", 0.0, t)
	tw.tween_property(sprite, "position", Vector2.ZERO, t)
	tw.tween_property(sprite, "scale", base_scale, t)
	return tw


# ------------------------------------------------------------------ movement

## Hop-walk: crouch, spring up with a stretch, land with a squash, tilted into the step.
func step_to(c: Vector2i, world: Vector2, animate: bool = true) -> void:
	cell = c
	if not animate or not visible:
		position = world
		return
	face(world)
	anim = "walk"
	if _fa != "walk":
		play_frames("walk", 14.0, true)
	var move := create_tween()
	move.tween_property(self, "position", world, STEP_TIME)
	var body := create_tween()
	body.tween_property(sprite, "scale", base_scale * Vector2(0.9, 1.12), STEP_TIME * 0.35)
	body.parallel().tween_property(sprite, "position:y", -HOP_HEIGHT, STEP_TIME * 0.45).set_ease(Tween.EASE_OUT)
	body.parallel().tween_property(sprite, "rotation", 0.09 * _facing * _rk, STEP_TIME * 0.4)
	body.tween_property(sprite, "position:y", 0.0, STEP_TIME * 0.45).set_ease(Tween.EASE_IN)
	body.tween_property(sprite, "scale", base_scale * Vector2(1.12, 0.88), 0.04)
	await move.finished
	_reset_pose(0.07)
	anim = ""
	# Go back to idle shortly after the last step (the next step restarts the walk).
	get_tree().create_timer(0.12).timeout.connect(func():
		if anim == "" and _fa == "walk":
			_idle_frames())


## Dash: a low, fast lunge with cyan afterimages.
func dash_to(c: Vector2i, world: Vector2) -> void:
	cell = c
	face(world)
	anim = "dash"
	show_frame("walk", 4)
	sprite.rotation = 0.2 * _facing * _rk
	sprite.scale = base_scale * Vector2(1.15, 0.9)
	var move := create_tween()
	move.tween_property(self, "position", world, DASH_STEP_TIME)
	for i in 3:
		_afterimage(Color(0.2, 0.95, 1.0, 0.55))
		await get_tree().create_timer(DASH_STEP_TIME / 3.0).timeout
	# The tween may already be done by now; awaiting a finished tween would hang.
	if move.is_running():
		await move.finished
	position = world
	_reset_pose(0.08)
	anim = ""
	_idle_frames()


func _afterimage(col: Color) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.offset = sprite.offset
	ghost.scale = sprite.scale
	ghost.rotation = sprite.rotation
	ghost.flip_h = sprite.flip_h
	ghost.modulate = col
	ghost.position = position + sprite.position
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tw.tween_callback(ghost.queue_free)


# ------------------------------------------------------------------ combat

## Attack: wind-up, strike and recover. Returns after the wind-up and strike so the caller
## can launch the projectile / swipe at the right moment; the recovery plays on its own.
func play_attack(target_pos: Vector2, melee: bool) -> void:
	face(target_pos)
	anim = "attack"
	var f := _facing
	if melee:
		show_frame("attack", 1)
		get_tree().create_timer(0.07).timeout.connect(func(): if anim == "attack": show_frame("attack", 2))
	else:
		show_frame("shoot", 1)
	# Wind-up: lean back and crouch.
	var wind := _tw().set_parallel(true)
	wind.tween_property(sprite, "rotation", -0.22 * f * _rk, 0.12)
	wind.tween_property(sprite, "position", Vector2(-10.0 * f, 2.0), 0.12)
	wind.tween_property(sprite, "scale", base_scale * Vector2(1.06, 0.92), 0.12)
	await wind.finished
	if melee:
		# Strike: whip forward, lunge toward the target and leave a neon swipe.
		var home := position
		var strike := create_tween().set_parallel(true)
		strike.tween_property(sprite, "rotation", 0.32 * f * _rk, 0.07)
		show_frame("attack", 3)
		strike.tween_property(sprite, "scale", base_scale * Vector2(0.94, 1.08), 0.07)
		strike.tween_property(self, "position", home + (target_pos - home) * 0.35, 0.07)
		_swipe(target_pos)
		await strike.finished
		show_frame("attack", 4)
		var back := _tw()
		back.tween_property(self, "position", home, 0.16)
		_reset_pose(0.16)
		get_tree().create_timer(0.22).timeout.connect(_idle_frames)
	else:
		# Ranged: snap forward and kick back with recoil.
		show_frame("shoot", 2)
		var shot := create_tween()
		shot.tween_property(sprite, "rotation", 0.06 * f * _rk, 0.04)
		shot.parallel().tween_property(sprite, "position", Vector2(6.0 * f, 0.0), 0.04)
		shot.tween_property(sprite, "position", Vector2(-12.0 * f, 0.0), 0.05)
		await shot.finished
		_reset_pose(0.14)
		get_tree().create_timer(0.25).timeout.connect(_idle_frames)
	anim = ""


## A short-lived glowing arc in front of Carol (the Star-Sword / Mallet swing).
func _swipe(target_pos: Vector2) -> void:
	var dir := (target_pos - position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(_facing, 0)
	var center := dir * 40.0 + Vector2(0, -64)
	var base_angle := dir.angle()
	for layer in 2:
		var line := Line2D.new()
		line.width = 18.0 if layer == 0 else 8.0
		line.default_color = SWIPE_COLORS[layer]
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		for i in 9:
			var a := base_angle - 1.2 + 2.4 * i / 8.0
			line.add_point(center + Vector2.from_angle(a) * Vector2(70, 46))
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.0))
		g.set_color(1, Color(1, 1, 1, 1.0))
		line.gradient = g
		line.z_index = 1
		add_child(line)
		var tw := line.create_tween()
		tw.tween_property(line, "modulate:a", 0.0, 0.22)
		tw.tween_callback(line.queue_free)


## Shove: crouch, then a two-handed push.
func play_shove(target_pos: Vector2) -> void:
	face(target_pos)
	anim = "shove"
	show_frame("attack", 2)
	var f := _facing
	var crouch := _tw().set_parallel(true)
	crouch.tween_property(sprite, "scale", base_scale * Vector2(1.1, 0.88), 0.1)
	crouch.tween_property(sprite, "position", Vector2(-8.0 * f, 4.0), 0.1)
	await crouch.finished
	var home := position
	var push := create_tween().set_parallel(true)
	push.tween_property(self, "position", home + (target_pos - home) * 0.3, 0.07)
	push.tween_property(sprite, "scale", base_scale * Vector2(0.92, 1.1), 0.07)
	push.tween_property(sprite, "rotation", 0.18 * f * _rk, 0.07)
	show_frame("attack", 3)
	await push.finished
	var back := _tw()
	back.tween_property(self, "position", home, 0.14)
	_reset_pose(0.14)
	anim = ""
	get_tree().create_timer(0.16).timeout.connect(_idle_frames)


## Hurt: knocked back away from the attacker, red flash and a wobble.
func play_hurt(from_pos: Vector2) -> void:
	if _dead:
		return
	anim = "hurt"
	play_frames("hit", 7.0, false)
	var away := (position - from_pos).normalized()
	if away == Vector2.ZERO:
		away = Vector2(-_facing, 0)
	sprite.self_modulate = Color(1.0, 0.35, 0.35)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "position", away * 14.0, 0.06)
	tw.tween_property(sprite, "rotation", -0.2 * _rk * signf(away.x if away.x != 0 else 1.0), 0.06)
	tw.chain().tween_property(sprite, "position", Vector2.ZERO, 0.18)
	tw.parallel().tween_property(sprite, "rotation", 0.0, 0.18)
	tw.parallel().tween_property(sprite, "self_modulate", Color.WHITE, 0.3)
	await tw.finished
	anim = ""
	if not _dead:
		get_tree().create_timer(0.15).timeout.connect(_idle_frames)


## Dodge: a quick sidestep when an attack misses.
func play_dodge(from_pos: Vector2) -> void:
	if _dead:
		return
	anim = "dodge"
	show_frame("walk", 3)
	var side := -1.0 if from_pos.x > position.x else 1.0
	var tw := _tw()
	tw.tween_property(sprite, "position", Vector2(18.0 * side, -6.0), 0.07)
	tw.tween_property(sprite, "position", Vector2.ZERO, 0.15)
	await tw.finished
	anim = ""
	_idle_frames()


## Drink: tilt back to chug, glow green and fizz bubbles.
func play_drink() -> void:
	anim = "drink"
	show_frame("idle", 2)
	var f := _facing
	var tw := _tw().set_parallel(true)
	tw.tween_property(sprite, "rotation", -0.32 * f * (0.6 if has_frames else 1.0), 0.15)
	tw.tween_property(sprite, "position", Vector2(0, -8), 0.15)
	tw.tween_property(sprite, "self_modulate", Color(0.6, 1.4, 0.7), 0.15)
	_bubbles()
	await tw.finished
	await get_tree().create_timer(0.25).timeout
	var back := _reset_pose(0.18)
	back.tween_property(sprite, "self_modulate", Color.WHITE, 0.25)
	await back.finished
	anim = ""
	_idle_frames()


func _bubbles() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.7
	p.explosiveness = 0.6
	p.position = Vector2(0, -90)
	p.direction = Vector2(0, -1)
	p.spread = 35.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 120.0
	p.gravity = Vector2(0, -40)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	p.color = Color(0.5, 1.0, 0.4, 0.9)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## Death: spin, topple over and grey out.
func play_death() -> void:
	_dead = true
	anim = "death"
	var f := _facing
	if has_frames and frames.has("down"):
		play_frames("down", 5.0, false)
		var fall := create_tween()
		fall.tween_property(sprite, "position", Vector2(10.0 * f, 4.0), 0.3)
		fall.parallel().tween_property(rig, "modulate", Color(0.7, 0.65, 0.8, 0.85), 0.5)
		await fall.finished
		return
	var tw := create_tween()
	tw.tween_property(sprite, "rotation", -0.4 * f, 0.12)
	tw.tween_property(sprite, "rotation", 1.5 * f, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "position", Vector2(30.0 * f, 6.0), 0.35)
	tw.parallel().tween_property(rig, "modulate", Color(0.55, 0.5, 0.65, 0.75), 0.5)
	await tw.finished


## Victory: two hops, the second with a full spin.
func play_victory() -> void:
	if _dead:
		return
	anim = "victory"
	show_frame("victory", 1)
	var tw := create_tween()
	for i in 2:
		tw.tween_property(sprite, "position:y", -34.0, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		if i == 1:
			if not has_frames:
				tw.parallel().tween_property(sprite, "rotation", TAU * _facing, 0.32)
		tw.tween_property(sprite, "position:y", 0.0, 0.16).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(sprite, "scale", base_scale * Vector2(1.12, 0.88), 0.05)
		tw.tween_property(sprite, "scale", base_scale, 0.07)
	await tw.finished
	sprite.rotation = 0.0
	anim = ""
