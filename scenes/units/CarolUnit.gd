class_name CarolUnit
extends BattleUnit
## The player unit.


func _ready() -> void:
	display_name = "Carol"
	max_hp = GameState.CAROL_MAX_HP
	hp = GameState.carol_hp
	max_ap = GameState.CAROL_AP
	ap = max_ap
	bar_color = Color("#00f0ff")
	set_texture(sprite.texture)
