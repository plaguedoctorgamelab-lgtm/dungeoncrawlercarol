extends Node
## Global event hub so scenes stay decoupled.

signal hp_changed(current: float, maximum: float)
signal ap_changed(current: int, maximum: int)
signal log_message(text: String, color: Color)
signal phase_changed(phase_name: String)
signal hit_preview(chance: float, target_name: String)
signal battle_finished(victory: bool)
signal inventory_changed


func say(text: String, color: Color = Color.WHITE) -> void:
	log_message.emit(text, color)
