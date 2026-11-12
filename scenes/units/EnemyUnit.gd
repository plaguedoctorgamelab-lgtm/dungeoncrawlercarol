class_name EnemyUnit
extends BattleUnit
## A smarmy corporate monster driven by EnemyData. Shows its next-turn intent above its
## HP bar: a red "!" (will attack Carol where she stands), a cyan arrow (moving), a yellow
## lightning "CHARGING" badge (boss wind-up) or "?" (hasn't noticed Carol yet).

const INTENT_TEXT := {
	"attack": "will ATTACK Carol if she stays put",
	"move": "moving into position",
	"charge": "CHARGING a big hit - get out of reach or into cover!",
	"unaware": "hasn't noticed Carol yet",
}
const INTENT_COLORS := {
	"attack": Color("#ff3b3b"),
	"move": Color("#00f0ff"),
	"charge": Color("#ffe600"),
	"unaware": Color("#9a8cb8"),
}
const INTENT_GLYPH := {"attack": "!", "move": ">", "charge": "!!", "unaware": "?"}
const FRAME_ROOT := "res://assets/sprites/enemies/"
## Frame animations a monster can have (imported by scripts/tools/import_art.gd).
const FRAME_ANIMS := ["idle", "attack", "hurt", "charge", "defeated"]

var data: EnemyData
var alerted: bool = false
## Turn number until which this enemy stays visible after attacking from the fog.
var revealed_until: int = -1
## Telegraphed next action (see INTENT_TEXT).
var intent: String = ""
## Bosses: true while winding up a big attack that lands next turn.
var charged: bool = false
## Stuck in red tape: can't move again this turn (cleared when its turn starts).
var rooted: bool = false
## Has Carol seen this monster yet this battle (for the NEW THREAT card).
var sighted: bool = false
## Bosses: the tile the charged strike is aimed at (locked when the charge starts).
var strike_cell: Vector2i = Vector2i(-1, -1)
## anim -> Array[Texture2D] when this monster has frame art (Art Pack 2+).
var frames: Dictionary = {}
var has_frames: bool = false
var _anim_t: float = 0.0
## A one-shot pose (attack / hurt) shown until this time.
var _pose: String = ""
var _pose_left: float = 0.0
var _dying: bool = false


## Tiles the charged strike will hit: the locked tile, plus its 4 neighbours for ranged
## bosses (a blast). Carol dodges by ending her turn outside this zone.
func strike_zone() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not charged or strike_cell.x < 0:
		return out
	out.append(strike_cell)
	if data.is_ranged:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			out.append(strike_cell + d)
	return out


func setup(d: EnemyData, hp_scale: float) -> void:
	data = d
	display_name = d.display_name
	max_hp = roundf(d.max_hp * hp_scale)
	hp = max_hp
	max_ap = d.ap_pool
	ap = max_ap
	bar_color = Color("#ff2bd6") if not d.is_boss else Color("#ffe600")
	name = d.enemy_id
	size_cells = 2 if d.is_boss else 1
	set_texture(d.sprite_texture)
	_load_frames(d.enemy_id)


## Loads frame art and lines it up: every frame shares one canvas with the feet on a
## fixed point (frames.json), stored at 2x, so one scale and offset keep it planted.
func _load_frames(id: String) -> void:
	var meta_path := FRAME_ROOT + id + "/frames.json"
	if not FileAccess.file_exists(meta_path):
		return
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	if typeof(meta) != TYPE_DICTIONARY:
		return
	for a in FRAME_ANIMS:
		var list: Array[Texture2D] = []
		for i in range(1, 10):
			var path := FRAME_ROOT + "%s/%s_%s_%02d.png" % [id, id, a, i]
			if not ResourceLoader.exists(path):
				break
			list.append(load(path))
		if not list.is_empty():
			frames[a] = list
	has_frames = frames.has("idle")
	if not has_frames:
		return
	var canvas := Vector2(meta["canvas"][0], meta["canvas"][1])
	var foot := Vector2(meta["foot"][0], meta["foot"][1])
	var idle_h := float(meta["idle_size"][1])
	var sc := 0.5
	var sink := SpriteScaler.FOOT_SINK * size_cells
	sprite.texture = frames["idle"][0]
	sprite.centered = true
	sprite.scale = Vector2(sc, sc)
	sprite.offset = Vector2(canvas.x / 2.0 - foot.x, canvas.y / 2.0 - foot.y + sink / sc)
	base_scale = sprite.scale
	bar_y = -idle_h * sc + sink - 14.0
	# Desynchronise idle loops so a squad doesn't breathe in lockstep.
	_anim_t = randf() * 2.0
	queue_redraw()


## Holds a one-shot pose ("attack", "hurt") for `seconds`, then returns to idle.
func show_pose(a: String, seconds: float = 0.45) -> void:
	if not has_frames or not frames.has(a) or _dying:
		return
	_pose = a
	_pose_left = seconds
	sprite.texture = frames[a][0]


func _process(delta: float) -> void:
	if not has_frames or _dying:
		return
	_anim_t += delta
	if _pose_left > 0.0:
		_pose_left -= delta
		return
	if charged and frames.has("charge"):
		sprite.texture = frames["charge"][0]
		return
	var idle: Array = frames["idle"]
	sprite.texture = idle[int(_anim_t * 2.5) % idle.size()]


func take_damage(amount: float) -> float:
	var out := super(amount)
	if not is_dead():
		show_pose("hurt", 0.4)
	return out


func attack_damage() -> float:
	return data.base_damage * GameState.enemy_dmg_scale()


## One-line stat summary for the enemy cards.
func stats_text() -> String:
	var rng_txt := "melee" if not data.is_ranged else "%d tiles" % data.attack_range_tiles
	var parts := ["HP %d/%d" % [int(hp), int(max_hp)], "DMG %d" % int(attack_damage()), "RANGE %s" % rng_txt]
	if data.tiles_per_ap > 1:
		parts.append("FAST (%d tiles/AP)" % data.tiles_per_ap)
	if data.damage_reduction > 0.0:
		parts.append("ARMOR %d%%" % int(data.damage_reduction * 100))
	if data.is_boss:
		parts.append("2x2 BOSS")
	return "   ".join(parts)


func _draw() -> void:
	super()
	if intent == "" or is_dead():
		return
	var col: Color = INTENT_COLORS.get(intent, Color.WHITE)
	var glyph: String = INTENT_GLYPH.get(intent, "")
	var r := 15.0
	var center := Vector2(bar_width / 2.0 + r + 4.0, bar_y + 3.0)
	if intent == "charge":
		var t := "CHARGING!"
		var font := ThemeDB.fallback_font
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var box := Rect2(-w / 2.0 - 8.0, bar_y - 40.0, w + 16.0, 28.0)
		draw_rect(box, Color.BLACK)
		draw_rect(box.grow(-2), col)
		draw_string(font, Vector2(-w / 2.0, bar_y - 19.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.BLACK)
		return
	draw_circle(center, r + 2.0, Color.BLACK)
	draw_circle(center, r, col)
	var font2 := ThemeDB.fallback_font
	var gw := font2.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font2, center + Vector2(-gw / 2.0, 8.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.BLACK)


## Death: bosses with a "defeated" frame crumble in place; everyone else pops, spins
## and shrinks away.
func play_death() -> void:
	intent = ""
	queue_redraw()
	if has_frames and frames.has("defeated"):
		_dying = true
		sprite.texture = frames["defeated"][0]
		sprite.scale = base_scale
		var crumble := create_tween()
		crumble.tween_property(sprite, "scale", base_scale * Vector2(1.08, 0.92), 0.08)
		crumble.tween_property(sprite, "scale", base_scale, 0.12)
		crumble.tween_interval(1.4)
		crumble.tween_property(self, "modulate:a", 0.0, 0.5)
		crumble.tween_callback(queue_free)
		return
	if has_frames and frames.has("hurt"):
		_dying = true
		sprite.texture = frames["hurt"][0]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "scale", base_scale * 1.35, 0.08)
	tw.chain().tween_property(sprite, "scale", base_scale * 0.1, 0.32).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "rotation", TAU * (1 if randf() < 0.5 else -1), 0.32)
	tw.tween_property(self, "modulate:a", 0.0, 0.32)
	tw.chain().tween_callback(queue_free)
