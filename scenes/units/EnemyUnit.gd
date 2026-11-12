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

var data: EnemyData
var alerted: bool = false
## Turn number until which this enemy stays visible after attacking from the fog.
var revealed_until: int = -1
## Telegraphed next action (see INTENT_TEXT).
var intent: String = ""
## Bosses: true while winding up a big attack that lands next turn.
var charged: bool = false
## Bosses: the tile the charged strike is aimed at (locked when the charge starts).
var strike_cell: Vector2i = Vector2i(-1, -1)


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


func attack_damage() -> float:
	return data.base_damage * GameState.enemy_dmg_scale()


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


## Death: a pop, a spin and a shrink-fade instead of a plain fade.
func play_death() -> void:
	intent = ""
	queue_redraw()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "scale", base_scale * 1.35, 0.08)
	tw.chain().tween_property(sprite, "scale", base_scale * 0.1, 0.32).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "rotation", TAU * (1 if randf() < 0.5 else -1), 0.32)
	tw.tween_property(self, "modulate:a", 0.0, 0.32)
	tw.chain().tween_callback(queue_free)
