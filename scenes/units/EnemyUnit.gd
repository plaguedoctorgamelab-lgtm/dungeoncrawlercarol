class_name EnemyUnit
extends BattleUnit
## A smarmy corporate monster driven by EnemyData.

var data: EnemyData
var alerted: bool = false
## Turn number until which this enemy stays visible after attacking from the fog.
var revealed_until: int = -1


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
